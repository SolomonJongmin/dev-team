# dev-team — Claude Code + Codex 멀티 에이전트 개발팀

한 사람이 **PL(Claude Code 메인 세션)** 하나와 **Codex 직원 여러 명**으로 개발팀을 꾸려 일하는 방식입니다.
실제 제품 개발에서 굴려 보며 다듬은 규칙·역할·실행 스크립트를 특정 제품과 무관하게 정리했습니다.

## 구성
| 파일 | 내용 |
|---|---|
| [TEAM.md](TEAM.md) | 팀원(역할·담당·실행 엔진) |
| [CLAUDE.md](CLAUDE.md) | Claude Code가 PL로 일할 때 읽는 시작점 |
| [team/RULES.md](team/RULES.md) | 모든 직원 공통 규칙 (권한, Git, 테스트·머지, 비밀값, 브라우저, Codex 실행) |
| [team/roles/](team/roles/) | 직책별 규칙: PL · 개발자 · 리팩토링 · 아키텍트 · QA · 교차 리뷰어 · 리서처 |
| [team/OPERATIONS.md](team/OPERATIONS.md) | 운영하며 겪은 문제와 바꾼 것 (회고) |
| [team/checklists/security.md](team/checklists/security.md) | 제출 전 보안 셀프 체크리스트 |
| [team/adr/](team/adr/) | 사용자 확정 결정 기록(ADR) — 다시 논의하지 않음 |
| [team/bin/](team/bin/) | `run-codex.sh`(직원 실행기), `run-review.sh`(교차 리뷰), `wait-job.sh`(완료 대기) |
| [team/briefs/](team/briefs/) | 지시서 (예시 포함) |
| `team/STATUS.md` | 현황판 — 실행기가 시작·끝을 자동 기록 |
| `team/reports/` | 직원 보고서 (git에 올리지 않음) |

## 시작하기
1. 저장소를 받습니다.
   ```
   git clone https://github.com/SolomonJongmin/dev-team.git
   ```
2. 설치·로그인: [Claude Code](https://claude.com/claude-code), [Codex CLI](https://github.com/openai/codex) (`npm i -g @openai/codex` → `codex login`), GitHub CLI (`gh auth login`), Windows라면 Git Bash.
3. `TEAM.md`의 담당 영역을 내 프로젝트에 맞게 고치고, `team/RULES.md`의 `<…>` 자리표시(저장소, 테스트 명령, 기준선)를 채웁니다.
4. 이 폴더에서 Claude Code를 열고 "이 팀 구성으로 일해줘"라고 하면 Claude가 PL로 일합니다.

## 작업 흐름
```
사용자 요청
  → PL: 작업 쪼개기 + 지시서 작성 (team/briefs/<slug>.txt)
  → run-codex.sh <이름> <직책> <전용 worktree> <지시서>   # 현황판 기록, 보고서 저장
  → PL: 보고·diff 검토, 범위 밖 변경 되돌리기
  → (보안·수명·저장 관련) run-review.sh 로 교차 리뷰 → P0~P2 수정
  → PL: 머지·릴리스 → QA
  → 사용자에게 완료·결정 필요 사항만 보고
```

## 핵심 원칙
- **PL만 Claude, 직원은 Codex.** Claude 사용량을 아끼고 병렬 작업 수를 늘립니다.
- **작업 하나 = 브랜치 하나 = worktree 하나 = 직원 한 명.**
- **지시서 밖 기능 금지.** 아이디어는 "제안(미구현)"으로 보고만.
- **직원은 커밋까지만.** push·머지·배포·운영 데이터 변경은 PL 또는 사용자.
- **확정 결정(ADR)은 다시 논의하지 않음.**
- **사실을 지어내지 않음.** 확인 안 한 것은 "확인 안 함", 실패는 실패라고 보고.
