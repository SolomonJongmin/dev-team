#!/usr/bin/env bash
# wait-job.sh <slug>... : block until the LAST status line of every slug is done/failed/cancelled.
S=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/STATUS.md
for slug in "$@"; do
  until last=$(grep "| $slug |" "$S" | tail -1) && [[ -n "$last" ]] && ! [[ "$last" == *"| running |"* ]]; do sleep 30; done
done
