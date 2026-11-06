# 0001. 개발 서버 배포 Jenkinsfile의 SSH 호스트 키 검증 꺼짐을 수용

- 날짜: 2026-11-06
- 결정자: 사용자

## 배경
issuance-validation-service `Jenkinsfile.dev` 리뷰(리아·도현)에서 `StrictHostKeyChecking=no`가 P2로 지적됨. 같은 패턴이 기존 Jenkinsfile 10곳 이상(axnexus-front, intellicore-front, intelli-core, intellicore-ax-backend 등)에 있음.

## 결정
개발 서버(staging) 배포 파이프라인은 현재 패턴을 그대로 쓴다. 리뷰에서 이 항목은 수용된 위험으로 보고 머지를 막지 않는다.

## 범위
개발 서버 배포만. 운영 배포 파이프라인에는 적용하지 않는다(운영은 known_hosts 고정 필요).
