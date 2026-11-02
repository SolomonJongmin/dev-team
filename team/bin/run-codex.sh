#!/usr/bin/env bash
# Starts one Codex teammate job and records it on the status board.
#   run-codex.sh <name> <role> <workdir> <brief-file> [--search]
# Report: team/reports/<date>-<name>-<slug>.md   Status: team/STATUS.md
# Env: CODEX_MODEL (default gpt-6.1-sol), CODEX_FULL_ACCESS=1 (bypass sandbox; Windows workspace-write
#      can block all writes — only with user approval, only in a dedicated worktree), CODEX_ADD_DIRS.
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

model_args=(-m "${CODEX_MODEL:-gpt-6.1-sol}")
sandbox_args=(-s workspace-write)
[[ "${CODEX_FULL_ACCESS:-0}" == 1 ]] && sandbox_args=(--dangerously-bypass-approvals-and-sandbox)
# CODEX_ADD_DIRS: extra writable dirs for the sandbox, ";"-separated (e.g. a Gradle cache). Not .git — that stays read-only.
IFS=';' read -ra extra_dirs <<< "${CODEX_ADD_DIRS:-}"; for d in "${extra_dirs[@]}"; do [[ -n "$d" ]] && sandbox_args+=(--add-dir "$d"); done

preamble="너는 '$name'(직책: $role)이다. 먼저 $team/RULES.md, $team/roles/$role.md, $team/adr/README.md 를 읽고 따르라.
이 폴더는 이번 작업 동안 너 혼자 쓴다. 지시서에 적힌 것만 하고, 보고에 '지시서 밖 변경'을 반드시 적어라.
제출 전 RULES.md 1장의 자체 점검(경합·우회·권한·실패)을 하고, 테스트는 실제로 돌린 명령과 숫자만 보고하라. 파일은 편집 도구(apply_patch)로만 고쳐라."

echo "| $(date +%H:%M) | $name | $slug | running | $report |" >> "$team/STATUS.md"
cd "$workdir"
# The workspace-write sandbox keeps .git read-only (also with --add-dir), so a sandboxed worker cannot commit.
# It leaves the changes in the worktree and the PL commits them after review.
[[ "${CODEX_FULL_ACCESS:-0}" != 1 ]] && preamble="$preamble
커밋하지 마라(샌드박스에서 .git이 읽기 전용이다). 변경은 작업 폴더에 남기고, 보고에 제안 커밋 메시지 한 줄을 적어라. 커밋은 PL이 검토 후 한다."
# </dev/null: codex exec otherwise waits for stdin forever when it is not a terminal.
codex $search exec "${model_args[@]}" "${sandbox_args[@]}" --skip-git-repo-check -C . \
  -o "$report" "$preamble

$(cat "$brief")" </dev/null >/dev/null 2>&1 || true
state=done; [[ -s "$report" ]] || state=failed
echo "| $(date +%H:%M) | $name | $slug | $state | $report |" >> "$team/STATUS.md"
echo "$state $report"
