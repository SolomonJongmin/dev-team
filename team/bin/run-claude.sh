#!/usr/bin/env bash
# Starts one Claude Code teammate job and records it on the status board (same contract as run-codex.sh).
#   run-claude.sh <name> <role> <workdir> team/briefs/<slug>.md (.txt also supported)
# Reports have date/time and an atomic random run suffix. Status: team/STATUS.md
# Env: CLAUDE_MODEL (pin a model; default: Claude Code's default),
#      CLAUDE_FULL_ACCESS=1 (bypassPermissions instead of auto — only with user approval,
#      only in the agent's workspace).
set -euo pipefail
[[ $# -ge 4 ]] || { echo "usage: run-claude.sh <name> <role> <workdir> team/briefs/<slug>.md (.txt also supported)" >&2; exit 2; }
name=$1; role=$2; workdir=$3; brief=$4

team=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
source "$team/bin/job-common.sh"
[[ -f "$team/roles/$role.md" ]] || { echo "unknown role: $role (see $team/roles/)" >&2; exit 2; }
brief=$(realpath "$brief"); [[ -s "$brief" ]] || { echo "brief file missing or empty: $brief" >&2; exit 2; }
slug=$(basename "$brief"); slug=${slug%.*}
check_role_fit
cd "$workdir"
job_environment
start_job

model_args=(); [[ -n "${CLAUDE_MODEL:-}" ]] && model_args=(--model "$CLAUDE_MODEL")
perm_args=(--permission-mode auto)
[[ "${CLAUDE_FULL_ACCESS:-0}" == 1 ]] && perm_args=(--permission-mode bypassPermissions)

preamble="You are '$name' (role: $role). First read and follow $team/RULES.md, $team/roles/$role.md, and $team/adr/README.md.
Only you use this folder during this job. Do only what the brief says. Report in English and always include 'Changes outside the brief'.
Write the full report to $report; final output is the fallback.
Run optional brief Preflight commands/host checks first; on failure write BLOCKED: <reason> as the first report line and stop. No workarounds outside the workspace or Windows temp writes. TMP/TEMP/TMPDIR are inside the workspace."

case "$role" in researcher|architect|reviewer|qa)
  perm_args=(--permission-mode dontAsk --allowedTools Read Grep Glob) ;;
esac
# </dev/null: claude -p would otherwise wait for stdin when it is not a terminal.
rc=0
claude -p "${model_args[@]}" "${perm_args[@]}" --add-dir "$team" --output-format text \
  "$preamble

$(cat "$brief")" </dev/null >"$final" 2>/dev/null || rc=$?
finish_job "$rc"
