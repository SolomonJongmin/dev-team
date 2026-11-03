#!/usr/bin/env bash
# Shared person-name lookup; profiles do not grant role permissions.
resolve_profile_id() {
  case "${1,,}" in
    한결|hangyeol) printf '%s\n' hangyeol ;;
    서진|seojin) printf '%s\n' seojin ;;
    도윤|doyun) printf '%s\n' doyun ;;
    준|jun) printf '%s\n' jun ;;
    지호|jiho) printf '%s\n' jiho ;;
    태오|taeo) printf '%s\n' taeo ;;
    하은|haeun) printf '%s\n' haeun ;;
    리아|ria) printf '%s\n' ria ;;
    서연|seoyeon) printf '%s\n' seoyeon ;;
    *) echo "unknown member name: $1 (see team/profiles/README.md)" >&2; return 2 ;;
  esac
}
