import importlib.util
from pathlib import Path
from types import SimpleNamespace
import unittest
from unittest.mock import MagicMock, patch

spec = importlib.util.spec_from_file_location("backup", Path(__file__).with_name("backup.py"))
backup = importlib.util.module_from_spec(spec)
spec.loader.exec_module(backup)


class BackupGuards(unittest.TestCase):
    def publication(self, fail_sync=False):
        directory = MagicMock()
        directory.resolve.return_value = directory
        directory.stat.return_value = SimpleNamespace(st_mode=0o700, st_uid=123)
        partial = MagicMock()
        partial.stat.return_value.st_size = 1
        lock = MagicMock()
        directory.__truediv__.side_effect = lambda name: lock if name == ".backup.lock" else partial
        events = []
        def sync(fd):
            events.append("directory-sync" if fd == 42 else "file-sync")
            if fd == 42 and fail_sync:
                raise OSError("directory sync failed")
        partial.unlink.side_effect = lambda: events.append("unlink")
        with patch.object(backup.os, "name", "posix"), \
             patch.object(backup.os, "getuid", return_value=123, create=True), \
             patch.object(backup.os, "O_DIRECTORY", 0, create=True), \
             patch.object(backup.os, "open", side_effect=[41, 42]), \
             patch.object(backup.os, "fdopen"), \
             patch.object(backup.os, "close") as close, \
             patch.object(backup.os, "fsync", side_effect=sync), \
             patch.object(backup.os, "link", side_effect=lambda *args: events.append("link")), \
             patch.object(backup, "check_space"), \
             patch.object(backup.subprocess, "run"), \
             patch("builtins.print", side_effect=lambda *args: events.append("success")):
            if fail_sync:
                with self.assertRaises(OSError):
                    backup.backup("db", "postgres", directory, 1)
            else:
                backup.backup("db", "postgres", directory, 1)
            close.assert_called_once_with(42)
        lock.rmdir.assert_called_once()
        return events

    def test_publication_syncs_directory_before_success(self):
        self.assertEqual(self.publication(), ["file-sync", "link", "unlink", "directory-sync", "success"])

    def test_directory_sync_failure_prevents_success_and_closes_fd(self):
        self.assertEqual(self.publication(fail_sync=True), ["file-sync", "link", "unlink", "directory-sync"])

    def test_91_percent_full_rejected(self):
        with patch.object(backup.shutil, "disk_usage", return_value=SimpleNamespace(total=100 * 1024**3, free=9 * 1024**3)):
            with self.assertRaises(RuntimeError):
                backup.check_space(Path("."), 1)

    def test_expected_size_reserves_headroom(self):
        with patch.object(backup.shutil, "disk_usage", return_value=SimpleNamespace(total=100 * 1024**3, free=15 * 1024**3)):
            with self.assertRaises(RuntimeError):
                backup.check_space(Path("."), 6 * 1024**3)

    def test_sufficient_space(self):
        with patch.object(backup.shutil, "disk_usage", return_value=SimpleNamespace(total=100 * 1024**3, free=30 * 1024**3)):
            backup.check_space(Path("."), 6 * 1024**3)

    def test_connection_string_rejected_before_docker(self):
        with patch.object(backup.subprocess, "run") as run:
            with self.assertRaises(ValueError):
                backup.backup("postgresql://host/db", "postgres", Path("."), 1)
            run.assert_not_called()

    def test_invalid_size_rejected_before_docker(self):
        with patch.object(backup.subprocess, "run") as run:
            with self.assertRaises(ValueError):
                backup.backup("db", "postgres", Path("."), 0)
            run.assert_not_called()


if __name__ == "__main__":
    unittest.main()
