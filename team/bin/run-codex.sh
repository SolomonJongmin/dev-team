#!/usr/bin/env bash
# Starts one Codex teammate job and records it on the status board.
#   run-codex.sh <name> <role> <workdir> team/briefs/<slug>.md [--search] (.txt also supported)
# Report: team/reports/<date>-<name>-<slug>.md   Status: team/STATUS.md
# Env: CODEX_MODEL (default gpt-6.1-sol), CODEX_FULL_ACCESS=1 (bypass sandbox; Windows workspace-write
#      can block all writes — only with user approval, only in the agent's workspace), CODEX_ADD_DIRS.
set -euo pipefail
[[ $# -ge 4 ]] || { echo "usage: run-codex.sh <name> <role> <workdir> team/briefs/<slug>.md [--search] (.txt also supported)" >&2; exit 2; }
name=$1; role=$2; workdir=$3; brief=$4; shift 4
search=""; [[ "${1:-}" == "--search" ]] && search="--search"

team=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
[[ -f "$team/roles/$role.md" ]] || { echo "unknown role: $role (see $team/roles/)" >&2; exit 2; }
brief=$(realpath "$brief"); [[ -s "$brief" ]] || { echo "brief file missing or empty: $brief" >&2; exit 2; }
slug=$(basename "$brief"); slug=${slug%.*}
mkdir -p "$team/reports"
report="$team/reports/$(date +%Y-%m-%d)-$name-$slug.md"

model_args=(-m "${CODEX_MODEL:-gpt-6.1-sol}")
sandbox_args=(-s workspace-write)
[[ "${CODEX_FULL_ACCESS:-0}" == 1 ]] && sandbox_args=(--dangerously-bypass-approvals-and-sandbox)
# CODEX_ADD_DIRS: extra writable dirs for the sandbox, ";"-separated (e.g. a Gradle cache). Not .git — that stays read-only.
IFS=';' read -ra extra_dirs <<< "${CODEX_ADD_DIRS:-}"; for d in "${extra_dirs[@]}"; do [[ -n "$d" ]] && sandbox_args+=(--add-dir "$d"); done

preamble="You are '$name' (role: $role). First read and follow $team/RULES.md, $team/roles/$role.md, and $team/adr/README.md.
Only you use this folder during this job. Do only what the brief says. Report in English and always include 'Changes outside the brief'.
Before submission, do the RULES.md section 1 self-check (races, bypasses, permissions, failures). Report tests only as commands actually run and counts. Edit files only with the editing tool (apply_patch)."

echo "| $(date +%H:%M) | $name | $slug | running | $report |" >> "$team/STATUS.md"
cd "$workdir"
# The workspace-write sandbox keeps .git read-only (also with --add-dir), so a sandboxed worker cannot commit.
# It leaves the changes in the workspace and the PL commits them after review.
[[ "${CODEX_FULL_ACCESS:-0}" != 1 ]] && preamble="$preamble
Do not commit (.git is read-only in the sandbox). Leave changes in the working folder and include one proposed commit message in the report. The PL commits after review."
# </dev/null: codex exec otherwise waits for stdin forever when it is not a terminal.
codex $search exec "${model_args[@]}" "${sandbox_args[@]}" --skip-git-repo-check -C . \
  -o "$report" "$preamble

$(cat "$brief")" </dev/null >/dev/null 2>&1 || true
state=done; [[ -s "$report" ]] || state=failed
echo "| $(date +%H:%M) | $name | $slug | $state | $report |" >> "$team/STATUS.md"
echo "$state $report"
