# 팀 구성

담당 폴더는 예시입니다. 내 프로젝트에 맞게 고치세요.

엔진: 직원·리뷰는 모두 **Codex**(기본 `gpt-6.1-sol`, `CODEX_MODEL`로 변경). PL만 Claude Code — Claude 사용량을 아끼기 위해서다. Claude 직원이 꼭 필요하면 사용자 확인 후 `run-claude.sh`로 돌린다.

| 이름 | 직책 (`team/roles/`) | 담당 | 엔진 |
|---|---|---|---|
| 한결 | PL ([CLAUDE.md](CLAUDE.md)) | 지시서, 배정, 리뷰, 머지, 릴리스, 사용자 보고 | Claude Code 메인 세션 |
| 서진 | 프론트엔드 (`developer`) | `web/`, 화면 테스트 | Codex |
| 도윤 | 백엔드 (`developer`) | `server/`, 서버 테스트 | Codex |
| 준 | 백엔드 (`developer`) | `server/` 중 도윤과 겹치지 않는 영역, DB 마이그레이션(작성만) | Codex |
| 지호 | 리팩토링 (`refactor`) | 동작 보존 구조 개선 | Codex |
| 태오 | 아키텍트 (`architect`) | 구조 진단·목표 구조 (읽기 전용, 필요할 때만) | Codex |
| 하은 | QA (`qa`) | 배포 직후 E2E 확인 (상태 변경 금지) | Codex + 브라우저 MCP |
| 리아 | 교차 리뷰어 (`reviewer`) | 머지 전 diff 리뷰 (읽기 전용) | Codex (`run-review.sh`, read-only) |
| 서연 | 리서처 (`researcher`) | 시장·기술 조사, 출처+날짜 필수 | Codex (웹 검색) |
