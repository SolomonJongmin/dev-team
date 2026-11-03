#!/usr/bin/env bash
# Wait for the latest exact slug; unsuccessful terminal states fail.
set -euo pipefail
[[ $# -gt 0 ]] || { echo 'usage: wait-job.sh <slug>...' >&2; exit 2; }
S=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/STATUS.md
rc=0
for slug in "$@"; do
  while :; do
    state=$(awk -F '|' -v slug="$slug" '
      {s=$4; gsub(/^[ \t]+|[ \t]+$/, "", s)}
      s==slug {
        v=$5; gsub(/^[ \t]+|[ \t]+$/, "", v)
        if(v=="running") {run=$6; latest=v}
        else if(run=="" || run==$6) latest=v
      }
      END {print latest}' "$S")
    case "$state" in
      done) break ;;
      failed|blocked|cancelled) rc=1; break ;;
    esac
    sleep 30
  done
done
exit "$rc"
