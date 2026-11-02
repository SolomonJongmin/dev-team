#!/usr/bin/env bash
# Cross-review (리아) of a branch diff, read-only.
#   run-review.sh <worktree> <base-ref> <slug> [extra instructions]
# The diff goes in on stdin (do NOT add </dev/null here, or the diff is dropped).
set -euo pipefail
[[ $# -ge 3 ]] || { echo "usage: run-review.sh <worktree> <base-ref> <slug> [extra]" >&2; exit 2; }
wt=$1; base=$2; slug=$3; extra=${4:-}
team=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
mkdir -p "$team/reports"
report="$team/reports/$(date +%Y-%m-%d)-리아-review-$slug.md"
model_args=(); [[ -n "${CODEX_MODEL:-}" ]] && model_args=(-m "$CODEX_MODEL")

prompt="너는 '리아'(직책: reviewer). 먼저 $team/RULES.md, $team/roles/reviewer.md, $team/checklists/security.md 를 읽고 따르라.
stdin 으로 받은 diff($base...HEAD)를 리뷰하라. 확정 결함만 P0~P3 로, 각 항목에 file:line·실패 상황·고칠 방향. 추측은 '확인 필요'로 분리. 볼 수 없었던 범위를 마지막에 적어라.
$extra"

echo "| $(date +%H:%M) | 리아 | review-$slug | running | $report |" >> "$team/STATUS.md"
git -C "$wt" diff "$base"...HEAD | codex exec "${model_args[@]}" -s read-only --skip-git-repo-check \
  -C "$wt" -o "$report" "$prompt" >/dev/null 2>&1 || true
state=done; [[ -s "$report" ]] || state=failed
echo "| $(date +%H:%M) | 리아 | review-$slug | $state | $report |" >> "$team/STATUS.md"
echo "$state $report"
