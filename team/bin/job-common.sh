#!/usr/bin/env bash
# Atomic allocation prevents simultaneous reruns from overwriting reports.
check_role_fit() {
  [[ "$role" =~ ^[a-z][a-z-]*$ ]] || { echo 'invalid role name' >&2; return 2; }
  case "$role" in researcher|architect|reviewer|qa)
    grep -Eq '^Mode: read-only\r?$' "$brief" || {
      echo "role $role requires Mode: read-only in the brief" >&2; return 2;
    } ;;
  esac
}
start_job() {
  mkdir -p "$team/reports"
  report=$(mktemp "$team/reports/$(date +%Y-%m-%d-%H%M%S)-$name-$slug.XXXXXX.md")
  final="$report.final.txt"
  status_row running
}
status_row() {
  echo "| $(date '+%Y-%m-%d %H:%M:%S') | $name | $slug | $1 | $report |" >> "$team/STATUS.md"
}
job_environment() {
  mkdir -p "$PWD/.job-tmp"
  export TMP="$PWD/.job-tmp" TEMP="$PWD/.job-tmp" TMPDIR="$PWD/.job-tmp"
}
finish_job() {
  local rc=$1 state=done
  if [[ ! -s "$report" && -s "$final" ]]; then cat "$final" > "$report"; fi
  if head -n 1 "$report" | grep -q '^BLOCKED:'; then state=blocked
  elif (( rc != 0 )) || [[ ! -s "$report" ]]; then state=failed; fi
  status_row "$state"
  echo "$state $report"
  (( rc == 0 )) || return "$rc"
  [[ "$state" == done ]]
}
