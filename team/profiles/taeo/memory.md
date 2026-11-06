# 태오의 기억

- 2026-11-06 [mate-cx-detach-design] Mate의 CX 그룹 결합은 관리자 CRUD·템플릿·HITL·웹훅 4곳에 걸쳐 있어 분리 전 네 곳을 모두 감사한다. intelli-core 디렉터리 API는 TenantFilter의 기본 스키마 폴백(TenantFilter.java:47,73) 때문에 명시적 테넌트 가드가 필요하다. (evidence: 2026-11-06-115417-태오-mate-cx-detach-design report)
- 2026-11-03 [mate-bridge-4001] 서명 검증 실패와 그 뒤의 식별자(UUID) 오류를 구분한다. 가설은 실제 토큰 헤더 등으로 확인 가능하면 확인을 요청한다(알고리즘 가설은 실제 HS384로 반증됨). (evidence: team/reports/2026-11-03-태오-mate-bridge-4001-detail.md)
- 2026-11-03 [team-retro-2026-11-03] STATUS 시작 누락과 겹친 리뷰 시간은 총 작업 시간으로 단순 합산하지 않는다. 관측·재구성·unknown을 구분한다. (evidence: [2026-11-03-태오-team-retro-2026-11-03.md](C:/Users/최종민/projects/dev-team/team/reports/2026-11-03-태오-team-retro-2026-11-03.md))
