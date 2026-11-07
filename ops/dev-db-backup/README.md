# Dev database backup and recovery

PL executes this runbook on the approved dev Linux host. No server commands were
executed while authoring it. Scope: Mate G0 003, ax `20261107_menu_grants`, and
verification service `issuance_skeleton`. Do not apply migrations with this script.

## Database evidence (local checkout, 2026-11-07)

| Service | Repository configuration | Actual shared dev database |
| --- | --- | --- |
| Mate | `intellicore-mate-backend/docker-compose.yml:7,31`: `${POSTGRES_DB:-cxnexus}` | 확인 안 됨 (not verified; environment can override) |
| ax | `intellicore-ax-backend/docker-compose.dev.yml:31`: `intellicore_ax`, local container `iax-postgres` | 확인 안 됨 (not verified; local compose differs from shared dev) |
| issuance_skeleton | No database mapping available in this workspace | 확인 안 됨 (not verified) |

Mate's available POC `.env.example` does not establish a shared dev database name;
no ax `.env.example` was found in its main local checkout. Never infer database
identity from service name or the container's default database. Shared dev uses
one container named `postgres`, with multiple databases including intellicore and
cxnexus per the brief. PL must reconcile deployed compose/environment privately
with `docker exec postgres psql -w -U ROLE -d postgres -Atc 'SELECT datname FROM pg_database WHERE NOT datistemplate'`
and each service's active connection target before proceeding. Do not print URLs,
passwords, or full environment files. Resolve all three service mappings first.

## Before migration

1. Confirm dev host/container identity, PostgreSQL/client versions, authenticated
   backup role, and database mappings. Docker access is effectively privileged;
   restrict it to the authorized PL. Use existing container-local authentication;
   `-w` fails rather than prompting. No passwords in command arguments or logs.
2. Quiesce writers and background jobs for all affected services, including
   issuance_skeleton. Keep writes paused through backups, migration and checks.
   Independent `pg_dump` snapshots are not a cross-database atomic snapshot.
3. Check `df -h` on both PostgreSQL data storage and backup destination. At the
   reported 91% dev disk usage, **do not back up onto that disk**. Arrange an
   approved volume with capacity; do not delete Docker volumes or shared data.
   Script checks its destination, not database storage. Monitor both throughout.
4. For each confirmed DB obtain its size using a parameterized/privately reviewed
   `pg_database_size` query. Set expected bytes to at least the uncompressed size
   plus growth allowance. Script requires this amount plus max(10% volume, 2 GiB)
   free. Free-space checks cannot reserve space against unrelated writers; isolate
   the backup volume and monitor it. A failed dump never authorizes migration.
5. Prepare an operator-owned 0700 destination on that approved volume. Linux,
   Python 3, Docker and container `pg_dump`/`pg_restore` are prerequisites.

```sh
# Replace every uppercase placeholder; one call per distinct confirmed DB.
python3 ops/dev-db-backup/backup.py CONFIRMED_DB --user BACKUP_ROLE \
  --directory /APPROVED_VOLUME/dev-db-backups --expected-bytes SIZE_WITH_MARGIN
```

The script streams `pg_dump -Fc -Z 6` directly to a 0600 host file, without a
container copy or second compression pass. UTC names include microseconds. A
destination-wide atomic lock prevents concurrent script dumps. Success publishes
`.dump` only after successful dump, file fsync and archive-list validation, then
syncs the destination directory before reporting success. Failure can leave
`.partial` or a published `.dump` if directory sync fails; file presence alone
does not authorize migration. Never restore a partial file. A killed process may
leave `.backup.lock`: verify no dump is running before manually removing the empty
lock directory. Never clear a live lock. Use a local filesystem supporting hard
links and directory fsync. Archive-list success alone does not prove data restoration.

## Restore rehearsal and rollback (PL only)

Before migration, rehearse each archive on an isolated PostgreSQL instance with
matching major version, extensions, roles, locale and sufficient disk. Never use
the 91%-full dev data volume for a rehearsal. Custom dumps include one DB's data
and schema, not cluster roles, tablespaces or external services. Preserve required
role/extension definitions securely through the existing operational process.

```sh
# ISOLATED_POSTGRES must be a separate approved rehearsal container.
docker exec ISOLATED_POSTGRES createdb -w -U RESTORE_ROLE -T template0 NEW_EMPTY_DB
docker exec -i ISOLATED_POSTGRES pg_restore -w -U RESTORE_ROLE \
  --exit-on-error --single-transaction -d NEW_EMPTY_DB < /ABSOLUTE/VERIFIED.dump
```

Require every command to exit zero. Verify representative row counts, constraints,
ownership/grants and migration history, then service-specific checks for Mate,
ax menu grants and issuance_skeleton. Exact application check commands are not
available here; PL obtains them from migration owners. Record archive path, size,
checksum (`sha256sum /ABSOLUTE/VERIFIED.dump`), DB mapping, versions, time and
rehearsal results privately. Only then apply the assigned migrations separately.

If checks fail, pause writes and all three services. Preserve evidence and the
failed DB; do not rerun blindly. PL creates a distinct empty recovery database on
adequately provisioned approved storage and uses the same restore command above
with the approved recovery container. Validate data, roles and application state,
then have PL switch the relevant service connections and restart/verify them.
Do not use `--clean`, drop databases, overwrite another DB, or restore the whole
cluster. Switching to pre-migration state loses post-backup writes; reconcile any
such writes before reopening traffic. Migration rollback SQL is not supplied.

## Retention

No automatic deletion. Keep the pre-migration archives until all three services
pass validation and the PL closes the rollback window. Thereafter, candidates
are completed `.dump` files older than 14 days with a verified independent copy
and successful restore evidence; always retain at least the latest two verified
sets and every set tied to an open incident. PL reviews exact paths and obtains
data-deletion approval before removal. Partial files and stale locks require
separate incident review, never age-based deletion. Capacity pressure is a stop
condition, not permission to remove the last recovery point.
