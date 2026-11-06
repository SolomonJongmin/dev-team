# 구성원 프로필

작업 폴더가 저장소 쪽의 연속성이라면 프로필은 사람 쪽의 연속성이다. 개인별 폴더는 역할 지침을 공유해도 서로 분리한다.

| id | 이름 | 역할 |
|---|---|---|
| eunho | 은호 | PL |
| seojin | 서진 | developer |
| doyun | 도윤 | developer |
| jun | 준 | developer |
| harin | 하린 | developer |
| minjae | 민재 | developer |
| yuna | 유나 | developer |
| siwoo | 시우 | developer |
| daon | 다온 | developer |
| geonu | 건우 | developer |
| jiho | 지호 | refactor |
| taeo | 태오 | architect |
| haeun | 하은 | qa |
| ria | 리아 | reviewer |
| seoyeon | 서연 | researcher |

- soul.md: 한 줄 정체성, 가치·우선순위, 기질·보고 목소리, 거부하는 일. 최대 20줄.
- workstyle.md: 시작 루틴, 검증·보고 방식, 개인 체크리스트와 도구·환경 주의점. 최대 30줄.
- memory.md: 배운 교훈. 최신 날짜부터 `- YYYY-MM-DD [slug] 교훈 (evidence: 보고서 파일)` 형식으로 최대 40개. 근거가 없으면 “아직 기록 없음”.
- history.md: 날짜·slug·결과·회차·보고서 표. STATUS에 관측된 작업만 기록하고 미확인·취소를 성공으로 바꾸지 않는다.

## 읽기와 권한

run-codex.sh와 run-review.sh는 한국어 이름 또는 대소문자 구분 없는 영문 id를 해석한다. 예: 도윤/doyun, Ria/리아. 알 수 없는 이름은 exit 2로 중단한다.
RULES 다음 개인 soul·workstyle·memory를 읽고 역할 파일을 읽는다. 개인 프로필은 brief·RULES·역할 권한을 대체하지 않는다. 은호의 PL 세션은 CLAUDE.md와 함께 자신의 세 파일을 읽는다.
실행 없는 확인: `bash team/bin/run-codex.sh --resolve-only 도윤`, `bash team/bin/run-review.sh --resolve-only Ria`.
전체 별칭·거부 경로와 STATUS 미변경 확인: `bash team/bin/test-profiles.sh` (Codex·Claude를 시작하지 않는다).

## 작업 후 갱신

worker는 보고서 마지막에 `Memory proposal:`로 근거 있는 교훈 0–2개(없으면 None)를 제안한다. PL이 검토하여 받아들인 교훈만 날짜·slug·실제 보고서 링크와 함께 memory 맨 앞에 추가하고 history에 결과·회차·보고서 행을 추가한다. 중복 교훈은 합친다.
worker는 명시적으로 배정받은 프로필 편집 외에는 제안만 한다. 검토·커밋 책임은 PL에게 있다. 읽기 전용 리뷰어도 직접 갱신하지 않는다.
40개를 넘기기 전에 오래된 교훈을 근거 링크를 보존한 요약 항목으로 합친다. 요약 날짜는 마지막 관련 작업 날짜를 쓰고 원래 날짜 범위를 적는다. 장기 원본 이력은 history와 보고서에 남긴다. 비밀·자격증명은 저장하지 않는다.

## 초기 이력의 근거와 한계

이 checkout의 team/STATUS.md는 빈 표이고 team/reports에는 기존 보고서가 없다. 초기 자료는 실제 운영 폴더 `C:/Users/최종민/projects/dev-team/team/STATUS.md`와 그 reports에서 읽었으며 링크는 이 위치를 가리킨다. 외부 원본을 이 브랜치로 복사하거나 STATUS를 수정하지 않았다. 다른 환경에서는 PL이 원본을 제공하거나 검증된 저장소 링크로 교체해야 한다.
회차는 같은 사람·slug의 running 행 수이며, 시작이 없으면 미상이다. 덮어쓴 보고서로 과거 결과를 복원하지 않는다. done은 launcher 실행 종료이며 기능 통과나 리뷰 승인 증거가 아니다. 리뷰의 2차·3차 slug는 STATUS 그대로 별도 행이다.
준의 single-session 구현 4회와 리아 리뷰 3회는 회고 보고서에서 확인된다. 도윤의 선행 2회 시도는 별도 개인 이력이다. 은호·지호·하은의 개인 작업 행은 없어 빈 이력으로 남겼다. 진행 중인 작업은 완료로 기록하지 않았다.
