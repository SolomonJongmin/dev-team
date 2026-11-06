#!/usr/bin/env bash
# Isolated integration checks: no real engines, no repository STATUS writes.
set -euo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
fixture=$(mktemp -d "$root/.test-jobs.XXXXXX")
trap 'rm -rf -- "$fixture"' EXIT
mkdir -p "$fixture/team/bin" "$fixture/work" "$fixture/fakes"
cp "$root"/team/bin/*.sh "$fixture/team/bin/"
cp -R "$root/team/profiles" "$root/team/roles" "$fixture/team/"
cp "$root/team/bin/test-fixtures/"* "$fixture/fakes/"
chmod +x "$fixture/fakes/"*
export PATH="$fixture/fakes:$PATH"
# Capture the actual engine arguments while retaining the existing fake engine.
export CODEX_TEST_CAPTURE="$fixture/codex-args"
codex() { printf '%s\n' "$@" > "$CODEX_TEST_CAPTURE"; command codex "$@"; }
export -f codex
printf '## Goal\nEdit tooling\n' > "$fixture/brief.md"
printf 'Mode: read-only\n' > "$fixture/read.md"
printf '| old | person | historical | done | old-report |\n' > "$fixture/team/STATUS.md"
git -C "$fixture/work" init -q
git -C "$fixture/work" -c user.name=Test -c user.email=test@example.invalid commit --allow-empty -qm initial
passed=0
check() { if "$@"; then passed=$((passed+1)); else echo "FAIL: $*" >&2; exit 1; fi; }
run() {
  rc=0
  output=$(bash "$fixture/team/bin/run-codex.sh" doyun "${ROLE:-developer}" "$fixture/work" "${BRIEF:-$fixture/brief.md}" 2>&1) || rc=$?
  report=${output#* }
}
run
check test "$rc" = 0
check grep -qx 'fallback report' "$report"
check grep -qx 'sandbox_workspace_write.network_access=true' "$CODEX_TEST_CAPTURE"
check grep -qx 'Network is available in workspace-write to install packages and fetch references.' "$CODEX_TEST_CAPTURE"
check grep -q 'Never execute downloaded scripts.*official registries already used by the repo.*Do not change lockfiles unless the brief allows it.' "$CODEX_TEST_CAPTURE"
first=$report
CODEX_NETWORK=0 run
check test "$rc" = 0
check grep -qx 'sandbox_workspace_write.network_access=false' "$CODEX_TEST_CAPTURE"
check grep -qx 'Network is disabled in workspace-write (CODEX_NETWORK=0).' "$CODEX_TEST_CAPTURE"
check bash -c '! grep -q "sandbox_workspace_write.network_access=true" "$CODEX_TEST_CAPTURE"'
CODEX_FULL_ACCESS=1 run
check test "$rc" = 0
check grep -qx -- '--dangerously-bypass-approvals-and-sandbox' "$CODEX_TEST_CAPTURE"
check bash -c '! grep -q "sandbox_workspace_write.network_access=" "$CODEX_TEST_CAPTURE"'
export FAKE_MODE=full
run
check test "$report" != "$first"
check grep -qx 'full report' "$report"
check grep -qx 'short final' "$report.final.txt"
export FAKE_EXIT=17
run
check test "$rc" = 17
check grep -q '| failed |' "$fixture/team/STATUS.md"
export FAKE_EXIT=0 FAKE_MODE=blocked
run
check test "$rc" = 1
check grep -q '| blocked |' "$fixture/team/STATUS.md"
rc=0; bash "$fixture/team/bin/wait-job.sh" brief || rc=$?
check test "$rc" = 1
export FAKE_MODE=empty
run
check test "$rc" = 1
export FAKE_MODE=fallback
for role in researcher architect reviewer qa; do
  ROLE=$role run
  check test "$rc" = 2
  FAKE_READ_ONLY=1 ROLE=$role BRIEF="$fixture/read.md" run
  check test "$rc" = 0
  check grep -qx 'fallback report' "$report"
  check cmp "$report.final.txt" "$report"
  check grep -qx 'read-only' "$CODEX_TEST_CAPTURE"
  check bash -c '! grep -q "sandbox_workspace_write.network_access=" "$CODEX_TEST_CAPTURE"'
done
ROLE=../roles/researcher run
check test "$rc" = 2
run
check bash "$fixture/team/bin/wait-job.sh" brief read
check grep -Eq '^\| [0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2} \|' "$fixture/team/STATUS.md"
check grep -qx '| old | person | historical | done | old-report |' "$fixture/team/STATUS.md"
# Two simultaneous allocations must retain both full reports.
export FAKE_MODE=full
bash "$fixture/team/bin/run-codex.sh" doyun developer "$fixture/work" "$fixture/brief.md" > "$fixture/a" & a=$!
bash "$fixture/team/bin/run-codex.sh" doyun developer "$fixture/work" "$fixture/brief.md" > "$fixture/b" & b=$!
wait "$a"; wait "$b"
check test "$(cat "$fixture/a")" != "$(cat "$fixture/b")"
export FAKE_EXIT=19
rc=0; bash "$fixture/team/bin/run-review.sh" "$fixture/work" HEAD audit > "$fixture/review" || rc=$?
check test "$rc" = 19
rc=0; bash "$fixture/team/bin/wait-job.sh" review-audit || rc=$?
check test "$rc" = 1
export FAKE_EXIT=0 FAKE_MODE=fallback
check env FAKE_READ_ONLY=1 bash "$fixture/team/bin/run-review.sh" "$fixture/work" HEAD audit
check grep -qx 'read-only' "$CODEX_TEST_CAPTURE"
check bash -c '! grep -q "sandbox_workspace_write.network_access=" "$CODEX_TEST_CAPTURE"'
review_report=$(tail -n 1 "$fixture/team/STATUS.md" | cut -d '|' -f 6 | xargs)
check grep -qx 'fallback report' "$review_report"
check cmp "$review_report.final.txt" "$review_report"
check bash "$fixture/team/bin/wait-job.sh" review-audit
export FAKE_EXIT=19
rc=0; bash "$fixture/team/bin/run-claude.sh" doyun developer "$fixture/work" "$fixture/brief.md" > "$fixture/claude" || rc=$?
check test "$rc" = 19
export FAKE_EXIT=0
check bash "$fixture/team/bin/run-claude.sh" doyun developer "$fixture/work" "$fixture/brief.md"
for role in researcher architect reviewer qa; do
  rc=0; bash "$fixture/team/bin/run-claude.sh" doyun "$role" "$fixture/work" "$fixture/brief.md" > /dev/null 2>&1 || rc=$?
  check test "$rc" = 2
done
export REVIEW_ENGINE=claude FAKE_EXIT=23
rc=0; bash "$fixture/team/bin/run-review.sh" "$fixture/work" HEAD audit > "$fixture/review" || rc=$?
check test "$rc" = 23
export FAKE_EXIT=0
check bash "$fixture/team/bin/run-review.sh" "$fixture/work" HEAD audit
review_report=$(tail -n 1 "$fixture/team/STATUS.md" | cut -d '|' -f 6 | xargs)
check grep -qx 'claude report' "$review_report"
check cmp "$review_report.final.txt" "$review_report"
printf '| date | name | overlap | running | old |\n| date | name | overlap | running | new |\n| date | name | overlap | blocked | new |\n| date | name | overlap | done | old |\n' >> "$fixture/team/STATUS.md"
rc=0; bash "$fixture/team/bin/wait-job.sh" overlap || rc=$?
check test "$rc" = 1
printf 'Job launcher checks: %s passed, 0 failed\n' "$passed"
