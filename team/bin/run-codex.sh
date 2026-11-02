#!/usr/bin/env bash
# Starts one Codex teammate job the same way every time, and records it on the status board.
#   run-codex.sh <name> <role> <workdir> <brief-file> [--search]
# The brief file holds only the task; the shared preamble (rules, ADRs, report format) is added here.
# Report: team/reports/<date>-<name>-<slug>.md   Status: team/STATUS.md (one line per job)
#
# Env:
#   CODEX_MODEL        pin a model (default: Codex's default)
#   CODEX_FULL_ACCESS  1 = --dangerously-bypass-approvals-and-sandbox (Windows workspace-write
#                      sandbox can block all writes). Only with user approval, only in a dedicated worktree.
#   PL_NAME            name the preamble uses for the PL (default: 한결)
set -euo pipefail
[[ $# -ge 4 ]] || { echo "usage: run-codex.sh <name> <role> <workdir> <brief-file> [--search]" >&2; exit 2; }
name=$1; role=$2; workdir=$3; brief=$4; shift 4
search=""; [[ "${1:-}" == "--search" ]] && { search="--search"; shift; }

team=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
pl=${PL_NAME:-한결}
mkdir -p "$team/reports"
[[ -f "$team/roles/$role.md" ]] || { echo "unknown role: $role (see $team/roles/)" >&2; exit 2; }
brief=$(realpath "$brief"); [[ -s "$brief" ]] || { echo "brief file missing or empty: $brief" >&2; exit 2; }
slug=$(basename "$brief" .txt)
report="$team/reports/$(date +%Y-%m-%d)-$name-$slug.md"

model_args=(); [[ -n "${CODEX_MODEL:-}" ]] && model_args=(-m "$CODEX_MODEL")
if [[ "${CODEX_FULL_ACCESS:-0}" == 1 ]]; then
  sandbox_args=(--dangerously-bypass-approvals-and-sandbox)
else
  sandbox_args=(-s workspace-write)
fi

preamble="너는 '$name'(직책: $role), PL $pl 이 지시한다. 먼저 $team/RULES.md, $team/roles/$role.md, $team/adr/README.md 를 읽고 따르라.
보고는 한국어, 아래 형식으로 30줄 이내: 결론 1줄 / 한 일 / 변경 파일·커밋 / 검증(명령과 숫자) / 남은 문제·결정 필요 / 지시서 밖 변경.
**UI 문구:** 사용자 화면에는 설명 문단을 넣지 마라. 버튼·제목·짧은 라벨만, 필요하면 한 줄 이하.
**범위 엄수:** 지시서에 적힌 것만 만든다. 지시서에 없는 기능·화면·설정·문구·옵션·리팩토링을 추가하지 마라. 더 좋아 보이는 아이디어는 만들지 말고 보고 마지막에 '제안(미구현)'으로 한 줄만 적어라. 보고에 '지시서 밖 변경: 없음' 또는 그 목록을 반드시 적어라.
이 폴더는 이번 작업 동안 너 혼자 쓴다. push·머지·배포·운영 변경 금지(지시서가 명시적으로 허용한 웹 설정 제외)."

echo "| $(date +%H:%M) | $name | $slug | running | $report |" >> "$team/STATUS.md"
cd "$workdir"
# </dev/null: codex exec otherwise waits for stdin forever when it is not a terminal.
codex $search exec "${model_args[@]}" "${sandbox_args[@]}" --skip-git-repo-check -C . \
  -o "$report" "$preamble

$(cat "$brief")" </dev/null >/dev/null 2>&1 || true
state=done; [[ -s "$report" ]] || state=failed
echo "| $(date +%H:%M) | $name | $slug | $state | $report |" >> "$team/STATUS.md"
echo "$state $report"
