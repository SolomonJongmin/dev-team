#!/usr/bin/env bash
# Read-only cross-review of a branch diff.
#   run-review.sh <worktree> <base-ref> <slug> [extra instructions]
# Env: REVIEWER (default Ria), REVIEW_ENGINE (claude | codex, default codex),
#      CLAUDE_MODEL / CODEX_MODEL (default gpt-6.1-sol).
# The diff goes in on stdin — do NOT add </dev/null here, or the diff is dropped.
set -euo pipefail
[[ $# -ge 3 ]] || { echo "usage: run-review.sh <worktree> <base-ref> <slug> [extra]" >&2; exit 2; }
wt=$1; base=$2; slug=$3; extra=${4:-}
who=${REVIEWER:-Ria}
engine=${REVIEW_ENGINE:-codex}
team=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
mkdir -p "$team/reports"
report="$team/reports/$(date +%Y-%m-%d)-$who-review-$slug.md"

prompt="You are '$who' (role: reviewer). First read and follow $team/RULES.md, $team/roles/reviewer.md, and $team/checklists/security.md.
Review the diff ($base...HEAD) received on stdin. Do not edit code or commit. Report in English.
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
    git -C "$wt" diff "$base"...HEAD | codex exec -m "${CODEX_MODEL:-gpt-6.1-sol}" -s read-only \
      --skip-git-repo-check -C "$wt" -o "$report" "$prompt" >/dev/null 2>&1 || true ;;
  *) echo "unknown REVIEW_ENGINE: $engine (claude | codex)" >&2; exit 2 ;;
esac
state=done; [[ -s "$report" ]] || state=failed
echo "| $(date +%H:%M) | $who | review-$slug | $state | $report |" >> "$team/STATUS.md"
echo "$state $report"
