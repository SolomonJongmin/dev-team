#!/usr/bin/env bash
# Prepare one agent's persistent clone for a fresh job.
set -euo pipefail
[[ $# -ge 3 && $# -le 4 ]] || { echo "usage: agent-ws.sh <agent> <repo> <branch> [base=main]" >&2; exit 2; }
agent=$1; repo=$2; branch=$3; base=${4:-main}
case "$agent" in
  eunho|seojin|doyun|jun|harin|minjae|yuna|siwoo|daon|geonu|jiho|taeo|haeun|ria|seoyeon) ;;
  *) echo "Unknown agent: $agent (use a lowercase name from TEAM.md)." >&2; exit 2 ;;
esac
team=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
root=${AGENT_WS_ROOT:-$(dirname "$team")/agents}
name=$(basename "${repo%/}")
name=${name%.git}
[[ -n "$name" && "$name" != . && "$name" != .. ]] || { echo "Cannot determine repository name: $repo" >&2; exit 2; }
workspace="$root/$agent/$name"
if [[ ! -e "$workspace" ]]; then
  origin=$repo
  if [[ -d "$repo" ]]; then
    origin=$(git -C "$repo" remote get-url origin)
  fi
  mkdir -p "$root/$agent"
  git clone -- "$repo" "$workspace" >&2
  git -C "$workspace" remote set-url origin "$origin"
fi
[[ -d "$workspace/.git" ]] || { echo "Workspace is not a normal clone: $workspace. The PL must inspect it." >&2; exit 2; }
status=$(git -C "$workspace" status --porcelain --untracked-files=all)
if [[ -n "$status" ]]; then
  echo "Workspace is dirty: $workspace. The PL must commit/push or discard the previous job first." >&2
  exit 2
fi
if [[ "$branch" != --detach ]] && git -C "$workspace" show-ref --verify --quiet "refs/heads/$branch"; then
  echo "Branch already exists locally: $branch. Choose a fresh job branch." >&2
  exit 2
fi
git -C "$workspace" fetch origin --prune >&2
if [[ "$branch" == --detach ]]; then
  git -C "$workspace" switch --detach "origin/$base" >&2
else
  git -C "$workspace" switch -c "$branch" "origin/$base" >&2
fi
(cd "$workspace" && pwd)
