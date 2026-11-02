#!/usr/bin/env bash
# Starts one Claude Code teammate job and records it on the status board (same contract as run-codex.sh).
#   run-claude.sh <name> <role> <workdir> <brief-file>
# Report: team/reports/<date>-<name>-<slug>.md   Status: team/STATUS.md
# Env: CLAUDE_MODEL (pin a model; default: Claude Code's default),
#      CLAUDE_FULL_ACCESS=1 (bypassPermissions instead of auto — only with user approval,
#      only in a dedicated worktree).
set -euo pipefail
[[ $# -ge 4 ]] || { echo "usage: run-claude.sh <name> <role> <workdir> <brief-file>" >&2; exit 2; }
name=$1; role=$2; workdir=$3; brief=$4

team=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
[[ -f "$team/roles/$role.md" ]] || { echo "unknown role: $role (see $team/roles/)" >&2; exit 2; }
brief=$(realpath "$brief"); [[ -s "$brief" ]] || { echo "brief file missing or empty: $brief" >&2; exit 2; }
slug=$(basename "$brief" .txt)
mkdir -p "$team/reports"
report="$team/reports/$(date +%Y-%m-%d)-$name-$slug.md"

model_args=(); [[ -n "${CLAUDE_MODEL:-}" ]] && model_args=(--model "$CLAUDE_MODEL")
perm_args=(--permission-mode auto)
[[ "${CLAUDE_FULL_ACCESS:-0}" == 1 ]] && perm_args=(--permission-mode bypassPermissions)

preamble="너는 '$name'(직책: $role)이다. 먼저 $team/RULES.md, $team/roles/$role.md, $team/adr/README.md 를 읽고 따르라.
이 폴더는 이번 작업 동안 너 혼자 쓴다. 지시서에 적힌 것만 하고, 보고에 '지시서 밖 변경'을 반드시 적어라.
마지막 응답은 보고서 본문만 쓴다(그대로 보고서 파일에 저장된다)."

echo "| $(date +%H:%M) | $name | $slug | running | $report |" >> "$team/STATUS.md"
cd "$workdir"
# </dev/null: claude -p would otherwise wait for stdin when it is not a terminal.
claude -p "${model_args[@]}" "${perm_args[@]}" --add-dir "$team" --output-format text \
  "$preamble

$(cat "$brief")" </dev/null >"$report" 2>/dev/null || true
state=done; [[ -s "$report" ]] || state=failed
echo "| $(date +%H:%M) | $name | $slug | $state | $report |" >> "$team/STATUS.md"
echo "$state $report"
