#!/usr/bin/env bash
# Read-only cross-review of a branch diff.
#   run-review.sh <worktree> <base-ref> <slug> [extra instructions]
# Env: REVIEWER (default 리아), REVIEW_ENGINE (claude | codex, default claude),
#      CLAUDE_MODEL / CODEX_MODEL (default gpt-6.1-terra).
# The diff goes in on stdin — do NOT add </dev/null here, or the diff is dropped.
set -euo pipefail
[[ $# -ge 3 ]] || { echo "usage: run-review.sh <worktree> <base-ref> <slug> [extra]" >&2; exit 2; }
wt=$1; base=$2; slug=$3; extra=${4:-}
who=${REVIEWER:-리아}
engine=${REVIEW_ENGINE:-claude}
team=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
mkdir -p "$team/reports"
report="$team/reports/$(date +%Y-%m-%d)-$who-review-$slug.md"

prompt="너는 '$who'(직책: reviewer)이다. 먼저 $team/RULES.md, $team/roles/reviewer.md, $team/checklists/security.md 를 읽고 따르라.
stdin 으로 받은 diff($base...HEAD)를 리뷰하라. 코드를 고치거나 커밋하지 마라.
$extra"

echo "| $(date +%H:%M) | $who | review-$slug | running | $report |" >> "$team/STATUS.md"
case $engine in
  claude)
    model_args=(); [[ -n "${CLAUDE_MODEL:-}" ]] && model_args=(--model "$CLAUDE_MODEL")
    # Read-only: dontAsk denies every tool not listed in --allowedTools.
    git -C "$wt" diff "$base"...HEAD | (cd "$wt" && claude -p "${model_args[@]}" \
      --permission-mode dontAsk --add-dir "$team" --output-format text \
      --allowedTools Read Grep Glob "Bash(git diff:*)" "Bash(git log:*)" "Bash(git show:*)" \
      -- "$prompt" >"$report" 2>/dev/null) || true ;;
  codex)
    git -C "$wt" diff "$base"...HEAD | codex exec -m "${CODEX_MODEL:-gpt-6.1-terra}" -s read-only \
      --skip-git-repo-check -C "$wt" -o "$report" "$prompt" >/dev/null 2>&1 || true ;;
  *) echo "unknown REVIEW_ENGINE: $engine (claude | codex)" >&2; exit 2 ;;
esac
state=done; [[ -s "$report" ]] || state=failed
echo "| $(date +%H:%M) | $who | review-$slug | $state | $report |" >> "$team/STATUS.md"
echo "$state $report"
