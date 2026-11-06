#!/usr/bin/env bash
# Dry checks only: never launch Codex or Claude, or write reports/status.
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/../.."
passed=0; failed=0
before=$(sha256sum team/STATUS.md)
check_exit() {
  local expected=$1 output code; shift
  output=$("$@" 2>&1); code=$?
  if [[ $code == "$expected" ]]; then
    passed=$((passed+1))
  else
    printf 'FAIL expected exit %s, got %s: %s => %s\n' "$expected" "$code" "$*" "$output"
    failed=$((failed+1))
  fi
}
for script in team/bin/run-codex.sh team/bin/run-review.sh; do
  for pair in '도윤:doyun' 'doyun:doyun' 'Ria:ria' '리아:ria' 'DOYUN:doyun' \
    'Eunho:eunho' '은호:eunho' 'Seojin:seojin' '서진:seojin' \
    'Jun:jun' '준:jun' 'Jiho:jiho' '지호:jiho' 'Taeo:taeo' '태오:taeo' \
    'Haeun:haeun' '하은:haeun' 'Seoyeon:seoyeon' '서연:seoyeon' \
    'Harin:harin' 'harin:harin' '하린:harin' 'Minjae:minjae' 'minjae:minjae' '민재:minjae' \
    'Yuna:yuna' 'yuna:yuna' '유나:yuna' 'Siwoo:siwoo' 'siwoo:siwoo' '시우:siwoo' \
    'Daon:daon' 'daon:daon' '다온:daon' 'Geonu:geonu' 'geonu:geonu' '건우:geonu'; do
    name=${pair%:*}; expected=${pair#*:}
    output=$(bash "$script" --resolve-only "$name"); code=$?
    if [[ $code == 0 && "$output" == "$expected" ]]; then
      passed=$((passed+1))
    else
      printf 'FAIL %s %s: %s (exit %s)\n' "$script" "$name" "$output" "$code"
      failed=$((failed+1))
    fi
  done
  check_exit 2 bash "$script" --resolve-only unknown
  check_exit 2 bash "$script" --resolve-only '../ria'
  check_exit 2 bash "$script" --resolve-only
  check_exit 2 bash "$script" --resolve-only Ria extra
  check_exit 2 bash "$script"
done
check_exit 2 bash team/bin/run-codex.sh unknown developer . nonexistent.md
check_exit 2 env REVIEWER=unknown bash team/bin/run-review.sh . HEAD test
after=$(sha256sum team/STATUS.md)
if [[ "$before" == "$after" ]]; then
  passed=$((passed+1))
else
  printf 'FAIL dry checks changed STATUS.md\n'
  failed=$((failed+1))
fi
printf 'Profile launcher checks: %s passed, %s failed\n' "$passed" "$failed"
[[ $failed == 0 ]]
