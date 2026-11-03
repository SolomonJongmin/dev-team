# 준의 기억

- 2026-11-03 [cli-auth-fixes] 프로세스 간 잠금에서 "확인 후 경로로 삭제"는 원자적이지 않다. 고유 경로를 rename한 뒤 지우고, 잠금 실패 시에는 fail closed한다(4회차 끝에 승인). (evidence: team/reports/*Ria-review-cli-auth-fixes-4*)
- 2026-11-03 [team-retro-2026-11-03] single-session은 구현 4회·리뷰 3회를 거쳤다. 우회 토큰·검사/실행 경합·CORS·큰 본문·빈 입력을 처음부터 검증한다. (evidence: [2026-11-03-태오-team-retro-2026-11-03.md](C:/Users/최종민/projects/dev-team/team/reports/2026-11-03-태오-team-retro-2026-11-03.md))
- 2026-11-02 [single-session] 빈·공백·누락·null·비문자열·잘못된 refresh 입력은 JAR에 도달하기 전에 거부하며 실제 회귀 실행으로 확인한다. (evidence: [2026-11-02-준-single-session.md](C:/Users/최종민/projects/dev-team/team/reports/2026-11-02-준-single-session.md))
