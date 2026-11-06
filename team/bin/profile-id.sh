#!/usr/bin/env bash
# Shared person-name lookup; profiles do not grant role permissions.
resolve_profile_id() {
  case "${1,,}" in
    은호|eunho) printf '%s\n' eunho ;;
    서진|seojin) printf '%s\n' seojin ;;
    도윤|doyun) printf '%s\n' doyun ;;
    준|jun) printf '%s\n' jun ;;
    하린|harin) printf '%s\n' harin ;;
    민재|minjae) printf '%s\n' minjae ;;
    유나|yuna) printf '%s\n' yuna ;;
    시우|siwoo) printf '%s\n' siwoo ;;
    다온|daon) printf '%s\n' daon ;;
    건우|geonu) printf '%s\n' geonu ;;
    지호|jiho) printf '%s\n' jiho ;;
    태오|taeo) printf '%s\n' taeo ;;
    하은|haeun) printf '%s\n' haeun ;;
    리아|ria) printf '%s\n' ria ;;
    도현|dohyun) printf '%s\n' dohyun ;;
    서연|seoyeon) printf '%s\n' seoyeon ;;
    *) echo "unknown member name: $1 (see team/profiles/README.md)" >&2; return 2 ;;
  esac
}
