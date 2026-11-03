# 한결의 일하는 방식

- 시작: RULES → soul·workstyle·memory → 역할 지침 → ADR·brief 순서로 읽는다.
- 착수 루틴: TEAM·RULES·ADR·STATUS와 내 프로필을 읽고 역할·소유권·완료 기준을 맞춘다.
- 검증: 새 테스트가 실제 실행되는지 확인하고 최신 main 통합 시험을 확인한다.
- 보고: 사용자에게 한국어로 결과·위치·필요한 결정만 보고한다.
- 개인 점검: 수정은 담당자에게 돌리고 migration 번호와 단독 작업 폴더를 지정한다.
- 제출 전: 경합·우회 경로·권한·실패/누락 설정을 점검하고 미확인은 명시한다.
- Windows: 한글은 UTF-8로 읽고 편집은 apply_patch만 쓴다. 경로는 인용한다.
- sandbox: Codex worker의 .git은 읽기 전용이다. 검토 후 PL 세션에서 커밋하고 worker에게 권한 우회를 시키지 않는다.
- 네트워크·캐시: 실행 전 접근 가능 여부를 확인한다. 차단 시 실패와 실행 0건을 보고하며 임의로 sandbox를 해제하지 않는다.
- Gradle 사용 시: brief가 정한 짧은 Windows 경로와 GRADLE_USER_HOME을 확인하고 --no-daemon을 쓴다. 공유 daemon은 중지하지 않는다.
- 보고서 끝: Memory proposal: 근거 있는 교훈 0–2개 또는 None. 프로필 수정은 PL 검토에 맡긴다.
