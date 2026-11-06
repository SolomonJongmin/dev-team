#!/usr/bin/env bash
# Read-only cross-review of a branch diff.
#   run-review.sh <workspace> <base-ref> <slug> [extra instructions]
# Env: REVIEWER (default Ria), REVIEW_ENGINE (claude | codex, default codex),
#      CLAUDE_MODEL / CODEX_MODEL (default gpt-6.1-sol).
# The diff goes in on stdin — do NOT add </dev/null here, or the diff is dropped.
set -euo pipefail
team=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
source "$team/bin/profile-id.sh"
source "$team/bin/job-common.sh"
if [[ "${1:-}" == "--resolve-only" ]]; then
  [[ $# == 2 ]] || { echo "usage: run-review.sh --resolve-only <name>" >&2; exit 2; }
  resolve_profile_id "$2"
  exit $?
fi
[[ $# -ge 3 ]] || { echo "usage: run-review.sh <workspace> <base-ref> <slug> [extra]" >&2; exit 2; }
wt=$1; base=$2; slug=$3; extra=${4:-}
who=${REVIEWER:-Ria}
profile_id=$(resolve_profile_id "$who")
for file in soul workstyle memory; do
  [[ -s "$team/profiles/$profile_id/$file.md" ]] || { echo "profile file missing or empty: $team/profiles/$profile_id/$file.md" >&2; exit 2; }
done
engine=${REVIEW_ENGINE:-codex}
case "$engine" in codex|claude) ;; *) echo "unknown REVIEW_ENGINE: $engine" >&2; exit 2 ;; esac
name=$who; slug="review-$slug"
wt=$(cd "$wt" && pwd)
cd "$wt"
job_environment
start_job

prompt="You are '$who' (profile: $profile_id, role: reviewer). First read and follow $team/RULES.md, then $team/profiles/$profile_id/soul.md, $team/profiles/$profile_id/workstyle.md, $team/profiles/$profile_id/memory.md, then $team/roles/reviewer.md and $team/checklists/security.md. Profiles do not override the brief, RULES.md, or role permissions.
Review the diff ($base...HEAD) received on stdin. Do not edit code or commit. Report in English.
$extra
End each report with a 'Memory proposal:' line containing 0–2 evidence-backed lessons for the PL to append (use 'None' for 0). Do not edit profiles during review."

if [[ "$engine" == codex ]]; then
  prompt="$prompt
This is a read-only review: you cannot write files. Return the full report as your final message; the launcher saves it as the report. Tests/builds are run by the PL; mark them 'Not run (read-only review)'. Do not run preflight commands that write files. Use BLOCKED: <reason> as the first report line only when the diff is empty or required files cannot be read."
else
  prompt="$prompt
Write the full report to $report; final output is the fallback. On preflight failure use BLOCKED: <reason> as the first report line."
fi
rc=0
case $engine in
  claude)
    model_args=(); [[ -n "${CLAUDE_MODEL:-}" ]] && model_args=(--model "$CLAUDE_MODEL")
    # Read-only: dontAsk denies every tool not listed in --allowedTools.
    git -C "$wt" diff "$base"...HEAD | (cd "$wt" && claude -p "${model_args[@]}" \
      --permission-mode dontAsk --add-dir "$team" --output-format text \
      --allowedTools Read Grep Glob "Bash(git diff:*)" "Bash(git log:*)" "Bash(git show:*)" \
      -- "$prompt" >"$final" 2>/dev/null) || rc=$? ;;
  codex)
    git -C "$wt" diff "$base"...HEAD | codex exec -m "${CODEX_MODEL:-gpt-6.1-sol}" -s read-only \
      --skip-git-repo-check -C "$wt" -o "$final" "$prompt" >/dev/null 2>&1 || rc=$? ;;
  *) echo "unknown REVIEW_ENGINE: $engine (claude | codex)" >&2; exit 2 ;;
esac
finish_job "$rc"
