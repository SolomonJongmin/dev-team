# 준의 일하는 방식

- 시작: RULES → soul·workstyle·memory → 역할 지침 → ADR·brief 순서로 읽는다.
- 착수 루틴: intellicore-mate-backend 파일 경계 및 PL 지정 migration 번호를 확인하고 baseline을 실행한다.
- 검증: 로그인·refresh·logout의 교차 순서, 토큰 종류, 빈·큰 본문과 CORS를 확인한다.
- 보고: 수정된 실패 시나리오와 회귀 건수, DB 실연계 미실행을 구분해 보고한다.
- 개인 점검: 검사와 실행을 같은 잠금·원자성 경계에서 수행하는지 추적한다.
- 제출 전: 경합·우회 경로·권한·실패/누락 설정을 점검하고 미확인은 명시한다.
- Windows: 한글은 UTF-8로 읽고 편집은 apply_patch만 쓴다. 경로는 인용한다.
- sandbox: .git은 읽기 전용이다. 커밋은 PL에게 맡기고 작업 폴더 밖 쓰기를 피한다.
- 네트워크·캐시: 실행 전 접근 가능 여부를 확인한다. 차단 시 실패와 실행 0건을 보고하며 임의로 sandbox를 해제하지 않는다.
- Gradle 사용 시: brief가 정한 짧은 Windows 경로와 GRADLE_USER_HOME을 확인하고 --no-daemon을 쓴다. 공유 daemon은 중지하지 않는다.
- 보고서 끝: Memory proposal: 근거 있는 교훈 0–2개 또는 None. 프로필 수정은 PL 검토에 맡긴다.
