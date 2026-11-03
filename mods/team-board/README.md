# team-board

dev-team의 팀 현황을 Claude Code 패널에서 확인하는 플러그인입니다. 팀원별 상태, 진행 중인 작업, 내 결정 필요 항목과 최근 완료한 작업을 표시합니다. 세션을 시작하면 패널이 열리고, `/team` 명령으로 다시 열 수 있습니다. 데이터는 5초마다 읽으며 상태줄에는 진행 중인 작업 수와 결정이 필요한 항목 수를 표시합니다. 두 수가 모두 0이면 상태줄을 비웁니다.

## 설치

터미널의 Claude Code 프롬프트에서 입력합니다.

```text
/plugin install team-board --marketplace SolomonJongmin/dev-team
```

셸에서는 다음 명령을 실행합니다.

```sh
claude plugin install team-board --marketplace SolomonJongmin/dev-team
```

데스크톱 앱에서는 프롬프트 입력란 옆 **+ → Plugins → Add marketplace**에서 `SolomonJongmin/dev-team`을 추가한 뒤 **Add plugin**으로 team-board를 설치합니다.

## 데이터와 경로 설정

dev-team 저장소의 다음 파일을 읽습니다.

- `team/STATUS.md`: 진행 중, 막힘, 완료 작업
- `team/DECISIONS.md`: 아직 결정하지 않은 질문
- `TEAM.md`: 팀원, 역할과 담당 영역

`/plugin → team-board → teamDir`의 **dev-team 폴더 경로**에 저장소 폴더를 지정합니다. 예: `C:/workspace/dev-team` 또는 `/workspace/dev-team`. Windows 역슬래시와 경로 끝의 슬래시도 지원합니다.

기본값은 빈 문자열입니다. 비워 두면 세션 작업 폴더 `<cwd>`에 `team/STATUS.md`가 있는지 먼저 확인하고, 없으면 `<cwd>/dev-team/team/STATUS.md`를 확인합니다. 따라서 저장소 자체 또는 저장소가 들어 있는 상위 폴더에서 세션을 시작할 수 있습니다. 둘 다 찾지 못하면 `dev-team 경로를 설정하세요 (/plugin → team-board → teamDir)` 한 줄을 표시하고 상태줄을 비웁니다. 폴더를 새로 만들었다면 세션을 다시 시작하거나 teamDir를 설정하세요. 지정한 폴더의 파일을 읽지 못하면 파일과 읽기 권한을 확인하라는 경고가 표시됩니다.
