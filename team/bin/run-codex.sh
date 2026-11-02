#!/usr/bin/env bash
# Starts one Codex teammate job and records it on the status board.
#   run-codex.sh <name> <role> <workdir> <brief-file> [--search]
# Report: team/reports/<date>-<name>-<slug>.md   Status: team/STATUS.md
# Env: CODEX_MODEL (pin a model), CODEX_FULL_ACCESS=1 (bypass sandbox; Windows workspace-write
#      can block all writes — only with user approval, only in a dedicated worktree).
set -euo pipefail
[[ $# -ge 4 ]] || { echo "usage: run-codex.sh <name> <role> <workdir> <brief-file> [--search]" >&2; exit 2; }
name=$1; role=$2; workdir=$3; brief=$4; shift 4
search=""; [[ "${1:-}" == "--search" ]] && search="--search"

team=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
[[ -f "$team/roles/$role.md" ]] || { echo "unknown role: $role (see $team/roles/)" >&2; exit 2; }
brief=$(realpath "$brief"); [[ -s "$brief" ]] || { echo "brief file missing or empty: $brief" >&2; exit 2; }
slug=$(basename "$brief" .txt)
mkdir -p "$team/reports"
report="$team/reports/$(date +%Y-%m-%d)-$name-$slug.md"

model_args=(); [[ -n "${CODEX_MODEL:-}" ]] && model_args=(-m "$CODEX_MODEL")
sandbox_args=(-s workspace-write)
[[ "${CODEX_FULL_ACCESS:-0}" == 1 ]] && sandbox_args=(--dangerously-bypass-approvals-and-sandbox)

preamble="너는 '$name'(직책: $role)이다. 먼저 $team/RULES.md, $team/roles/$role.md, $team/adr/README.md 를 읽고 따르라.
이 폴더는 이번 작업 동안 너 혼자 쓴다. 지시서에 적힌 것만 하고, 보고에 '지시서 밖 변경'을 반드시 적어라."

echo "| $(date +%H:%M) | $name | $slug | running | $report |" >> "$team/STATUS.md"
cd "$workdir"
# </dev/null: codex exec otherwise waits for stdin forever when it is not a terminal.
codex $search exec "${model_args[@]}" "${sandbox_args[@]}" --skip-git-repo-check -C . \
  -o "$report" "$preamble

$(cat "$brief")" </dev/null >/dev/null 2>&1 || true
state=done; [[ -s "$report" ]] || state=failed
echo "| $(date +%H:%M) | $name | $slug | $state | $report |" >> "$team/STATUS.md"
echo "$state $report"
