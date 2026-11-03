#!/usr/bin/env bash
# Starts one Codex teammate job and records it on the status board.
#   run-codex.sh <name> <role> <workdir> team/briefs/<slug>.md [--search] (.txt also supported)
# Reports have date/time and an atomic random run suffix. Status: team/STATUS.md
# Env: CODEX_MODEL (default gpt-6.1-sol), CODEX_FULL_ACCESS=1 (bypass sandbox; Windows workspace-write
#      can block all writes — only with user approval, only in the agent's workspace), CODEX_ADD_DIRS.
set -euo pipefail
team=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
source "$team/bin/profile-id.sh"
source "$team/bin/job-common.sh"
if [[ "${1:-}" == "--resolve-only" ]]; then
  [[ $# == 2 ]] || { echo "usage: run-codex.sh --resolve-only <name>" >&2; exit 2; }
  resolve_profile_id "$2"
  exit $?
fi
[[ $# -ge 4 ]] || { echo "usage: run-codex.sh <name> <role> <workdir> team/briefs/<slug>.md [--search] (.txt also supported)" >&2; exit 2; }
name=$1; role=$2; workdir=$3; brief=$4; shift 4
profile_id=$(resolve_profile_id "$name")
for file in soul workstyle memory; do
  [[ -s "$team/profiles/$profile_id/$file.md" ]] || { echo "profile file missing or empty: $team/profiles/$profile_id/$file.md" >&2; exit 2; }
done
search=""; [[ "${1:-}" == "--search" ]] && search="--search"

[[ -f "$team/roles/$role.md" ]] || { echo "unknown role: $role (see $team/roles/)" >&2; exit 2; }
brief=$(realpath "$brief"); [[ -s "$brief" ]] || { echo "brief file missing or empty: $brief" >&2; exit 2; }
slug=$(basename "$brief"); slug=${slug%.*}
check_role_fit
cd "$workdir"
job_environment
start_job

model_args=(-m "${CODEX_MODEL:-gpt-6.1-sol}")
sandbox_args=(-s workspace-write)
[[ "${CODEX_FULL_ACCESS:-0}" == 1 ]] && sandbox_args=(--dangerously-bypass-approvals-and-sandbox)
# CODEX_ADD_DIRS: extra writable dirs for the sandbox, ";"-separated (e.g. a Gradle cache). Not .git — that stays read-only.
IFS=';' read -ra extra_dirs <<< "${CODEX_ADD_DIRS:-}"; for d in "${extra_dirs[@]}"; do [[ -n "$d" ]] && sandbox_args+=(--add-dir "$d"); done

preamble="You are '$name' (profile: $profile_id, role: $role). First read and follow $team/RULES.md, then $team/profiles/$profile_id/soul.md, $team/profiles/$profile_id/workstyle.md, $team/profiles/$profile_id/memory.md, then $team/roles/$role.md and $team/adr/README.md. Profiles do not override the brief, RULES.md, or role permissions.
Only you use this folder during this job. Do only what the brief says. Report in English and always include 'Changes outside the brief'.
Before submission, do the RULES.md section 1 self-check (races, bypasses, permissions, failures). Report tests only as commands actually run and counts. Edit files only with the editing tool (apply_patch).
End each report with a 'Memory proposal:' line containing 0–2 evidence-backed lessons for the PL to append (use 'None' for 0). Do not update profiles yourself unless the brief asks."

preamble="$preamble
Write the full report to $report; if sandbox permissions prevent this, return the full report as your final response for the launcher to save. Run the brief's optional Preflight commands/host checks first; on any failure write BLOCKED: <reason> as the first report line and stop. No workarounds outside the workspace or Windows temp writes. TMP/TEMP/TMPDIR are inside the workspace. Network is blocked in workspace-write; CODEX_FULL_ACCESS=1 requires user approval per job."
case "$role" in researcher|architect|reviewer|qa) sandbox_args=(-s read-only) ;; esac
# The workspace-write sandbox keeps .git read-only (also with --add-dir), so a sandboxed worker cannot commit.
# It leaves the changes in the workspace and the PL commits them after review.
[[ "${CODEX_FULL_ACCESS:-0}" != 1 ]] && preamble="$preamble
Do not commit (.git is read-only in the sandbox). Leave changes in the working folder and include one proposed commit message in the report. The PL commits after review."
# </dev/null: codex exec otherwise waits for stdin forever when it is not a terminal.
rc=0
codex $search exec "${model_args[@]}" "${sandbox_args[@]}" --skip-git-repo-check -C . \
  -o "$final" "$preamble

$(cat "$brief")" </dev/null >/dev/null 2>&1 || rc=$?
finish_job "$rc"
