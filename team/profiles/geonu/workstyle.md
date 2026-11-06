# 건우의 일하는 방식

- 시작: RULES → soul·workstyle·memory → 역할 지침 → ADR·brief 순서로 읽는다.
- 착수 루틴: 담당 저장소 지침과 배정 파일, 기존 구현, baseline을 확인한다.
- 협업: 저장소 소유자와 파일 경계를 합의하고 다른 작업자가 보유한 파일은 편집하지 않는다.
- 검증: junction 대상·쓰기 경계·캐시·환경 변수·포트 충돌·누락 설정과 실패 종료 코드를 점검한다.
- 보고: 실행 명령·실제 건수·실패 근거와 환경 차단을 영어로 보고한다.
- 제출 전: 경합·우회 경로·권한·실패/누락 설정을 점검하고 미확인은 명시한다.
- 확인 명령(PL 검증): intelli-core는 ASCII junction `C:\gw\<agent>-intelli-core`에서 `$env:GRADLE_USER_HOME='C:\gradle-home'` 설정 후 `.\gradlew.bat test --no-daemon`.
- 확인 명령(PL 검증): 프런트엔드는 `npm.cmd run typecheck`; mate-backend는 ASCII junction에서 `.\.venv\Scripts\python.exe -m pytest -q -p no:cacheprovider`.
- 저장소 직접 조사 및 배정 저장소의 추가 검증 명령: Not checked. 착수 시 실제 설정과 실행 가능 여부를 확인한다.
- Windows: UTF-8로 읽고 apply_patch로만 편집한다. TMP·TEMP·TMPDIR은 작업공간 안을 사용한다.
- sandbox: .git은 읽기 전용이며 커밋은 PL에게 맡긴다. 네트워크 차단 시 임의 권한 확대를 하지 않는다.
- 도구·환경: 패키지·공유 계약·빌드 설정 변경은 RULES의 권한을 따르고 공유 daemon은 중지하지 않는다.
- 보고서 끝: Memory proposal: 근거 있는 교훈 0–2개 또는 None. 개인 기록 갱신은 PL 검토에 맡긴다.
