"""PL-operated, single-database custom-format backup. No server execution in CI."""
import argparse
from datetime import datetime, timezone
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys


def check_space(directory, expected):
    usage = shutil.disk_usage(directory)
    reserve = max(usage.total // 10, 2 * 1024**3)
    if usage.free < expected + reserve:
        raise RuntimeError("Insufficient space: use an approved backup volume; retain 10% or 2 GiB plus expected dump size")


def backup(database, user, directory, expected):
    if not re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]{0,62}", database):
        raise ValueError("Database must be an explicit simple PostgreSQL identifier")
    if not re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]{0,62}", user):
        raise ValueError("Invalid database role")
    if expected <= 0:
        raise ValueError("Expected bytes must be positive")
    directory = directory.resolve(strict=True)
    if os.name != "posix":
        raise RuntimeError("Run on an approved Linux Docker host; POSIX permissions required")
    if directory.stat().st_mode & 0o077 or directory.stat().st_uid != os.getuid():
        raise RuntimeError("Backup directory must be owned by the operator with mode 0700")
    lock = directory / ".backup.lock"
    lock.mkdir(mode=0o700)  # Atomic; all databases share the destination lock.
    try:
        check_space(directory, expected)
        stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S%fZ")
        partial = directory / f"{database}-{stamp}.dump.partial"
        final = partial.with_suffix("")
        command = ["docker", "exec", "postgres", "pg_dump", "-w", "-U", user,
                   "-d", database, "-Fc", "-Z", "6"]
        fd = os.open(partial, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
        with os.fdopen(fd, "wb") as output:
            subprocess.run(command, stdout=output, stderr=subprocess.DEVNULL, check=True)
            output.flush()
            os.fsync(output.fileno())
        if partial.stat().st_size == 0:
            raise RuntimeError("Empty archive")
        check_space(directory, 0)
        with partial.open("rb") as archive:
            subprocess.run(["docker", "exec", "-i", "postgres", "pg_restore", "--list"],
                           stdin=archive, stdout=subprocess.DEVNULL,
                           stderr=subprocess.DEVNULL, check=True)
        # Link publication cannot overwrite an existing backup.
        os.link(partial, final)
        partial.unlink()
        directory_fd = os.open(directory, os.O_RDONLY | os.O_DIRECTORY)
        try:
            os.fsync(directory_fd)
        finally:
            os.close(directory_fd)
        print(final)
    finally:
        lock.rmdir()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("database")
    parser.add_argument("--user", required=True)
    parser.add_argument("--directory", type=Path, required=True)
    parser.add_argument("--expected-bytes", type=int, required=True,
                        help="Conservative uncompressed DB size plus growth allowance")
    args = parser.parse_args()
    try:
        backup(args.database, args.user, args.directory, args.expected_bytes)
    except (OSError, ValueError, RuntimeError, subprocess.SubprocessError):
        print("Backup failed; do not migrate. Check capacity, role, Docker and partial files privately.", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
