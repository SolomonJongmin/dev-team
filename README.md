# dev-team — Claude Code + Codex 멀티 에이전트 개발팀

**PL(Claude Code 메인 세션)** 하나가 **Codex·Claude 직원들**에게 일을 나눠 맡기는 개발팀 구성입니다.
실제 제품 개발에서 굴려 보며 다듬은 규칙과 실행 스크립트를 일반화했습니다.

## 구성
| 파일 | 내용 |
|---|---|
| [TEAM.md](TEAM.md) | 팀원과 담당 |
| [CLAUDE.md](CLAUDE.md) | PL 규칙 (Claude Code가 이 폴더에서 자동으로 읽음) |
| [team/RULES.md](team/RULES.md) | 모든 직원 공통 규칙 |
| [team/roles/](team/roles/) | 직책별 규칙 |
| [team/checklists/security.md](team/checklists/security.md) | 제출 전 보안 체크리스트 |
| [team/adr/](team/adr/) | 사용자 확정 결정 기록 |
| [team/bin/](team/bin/) | `run-codex.sh`·`run-claude.sh`(직원 실행), `run-review.sh`(교차 리뷰), `wait-job.sh`(완료 대기) |
| [team/briefs/](team/briefs/) | 지시서 (예시 포함) |
| `team/STATUS.md` | 현황판 (실행기가 자동 기록) |

## 시작하기
1. `git clone https://github.com/SolomonJongmin/dev-team.git`
2. [Claude Code](https://claude.com/claude-code), [Codex CLI](https://github.com/openai/codex)(`npm i -g @openai/codex` → `codex login`)를 설치합니다. Windows는 Git Bash가 필요합니다.
3. `TEAM.md`의 담당 폴더와 `team/RULES.md`의 `<…>` 자리를 내 프로젝트에 맞게 채웁니다.
4. 이 폴더에서 Claude Code를 열고 "이 팀 구성으로 일해줘"라고 합니다.

## 흐름
```
요청 → PL이 지시서 작성 → run-codex.sh 로 직원 실행 → PL이 보고·diff 검토
     → (보안·저장·수명 관련) run-review.sh 교차 리뷰 → 머지 → QA → 사용자 보고
```
