#!/usr/bin/env bash
# Read-only cross-review of a branch diff.
#   run-review.sh <worktree> <base-ref> <slug> [extra instructions]
# Env: REVIEWER (default 리아), CODEX_MODEL.
# The diff goes in on stdin — do NOT add </dev/null here, or the diff is dropped.
set -euo pipefail
[[ $# -ge 3 ]] || { echo "usage: run-review.sh <worktree> <base-ref> <slug> [extra]" >&2; exit 2; }
wt=$1; base=$2; slug=$3; extra=${4:-}
who=${REVIEWER:-리아}
team=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
mkdir -p "$team/reports"
report="$team/reports/$(date +%Y-%m-%d)-$who-review-$slug.md"
model_args=(); [[ -n "${CODEX_MODEL:-}" ]] && model_args=(-m "$CODEX_MODEL")

prompt="너는 '$who'(직책: reviewer)이다. 먼저 $team/RULES.md, $team/roles/reviewer.md, $team/checklists/security.md 를 읽고 따르라.
stdin 으로 받은 diff($base...HEAD)를 리뷰하라.
$extra"

echo "| $(date +%H:%M) | $who | review-$slug | running | $report |" >> "$team/STATUS.md"
git -C "$wt" diff "$base"...HEAD | codex exec "${model_args[@]}" -s read-only --skip-git-repo-check \
  -C "$wt" -o "$report" "$prompt" >/dev/null 2>&1 || true
state=done; [[ -s "$report" ]] || state=failed
echo "| $(date +%H:%M) | $who | review-$slug | $state | $report |" >> "$team/STATUS.md"
echo "$state $report"
