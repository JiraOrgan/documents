---
문서명: Jira 프로젝트 관리 시스템 Git 규칙 정의서
버전: v1.0
작성일: 2026-03-21
최종수정일: 2026-03-21
작성자: 팀
상태: 초안
---

# Jira 프로젝트 관리 시스템 Git 규칙 정의서

## 1. 브랜치 전략

```mermaid
gitgraph
    commit id: "init"
    branch develop
    commit id: "dev setup"
    branch feature/PROJ-23-login
    commit id: "login UI"
    commit id: "login API"
    checkout develop
    merge feature/PROJ-23-login id: "merge login"
    branch feature/PROJ-24-board
    commit id: "board UI"
    commit id: "board drag-drop"
    checkout develop
    merge feature/PROJ-24-board id: "merge board"
    branch release/1.0
    commit id: "version bump"
    checkout main
    merge release/1.0 id: "v1.0" tag: "v1.0.0"
    checkout develop
    merge release/1.0 id: "sync release"
```

### 1.1 브랜치 종류

| 브랜치 | 용도 | 네이밍 규칙 | 생성 기준 | 병합 대상 |
|--------|------|-------------|-----------|-----------|
| main | 운영 배포 | main | - | - |
| develop | 개발 통합 | develop | - | main |
| feature | 기능 개발 | feature/{이슈키}-{설명} | develop | develop |
| bugfix | 버그 수정 | bugfix/{이슈키}-{설명} | develop | develop |
| hotfix | 긴급 수정 | hotfix/{이슈키}-{설명} | main | main, develop |
| release | 배포 준비 | release/{버전} | develop | main, develop |

## 2. 커밋 컨벤션

### 2.1 커밋 메시지 형식

```
<type>(<scope>): <subject>

<body>

<footer>
```

### 2.2 Type 목록

| Type | 설명 | 예시 |
|------|------|------|
| feat | 새로운 기능 | feat(issue): 이슈 생성 API 구현 |
| fix | 버그 수정 | fix(board): WIP 제한 초과 시 경고 미표시 수정 |
| docs | 문서 수정 | docs: API 정의서 업데이트 |
| style | 코드 스타일 | style: 들여쓰기 수정 |
| refactor | 리팩토링 | refactor(workflow): 전환 규칙 엔진 분리 |
| test | 테스트 | test(jql): JQL 파서 단위 테스트 추가 |
| chore | 빌드/설정 | chore: ESLint 설정 추가 |

## 3. PR (Pull Request) 규칙

### 3.1 PR 템플릿

```
## 변경 사항
-

## 변경 사유
- Jira Issue: PROJ-{번호}

## 테스트 결과
- [ ] 단위 테스트 통과
- [ ] 기능 테스트 완료

## 스크린샷 (UI 변경 시)

## 관련 이슈
- PROJ-{번호}
```

### 3.2 PR 규칙

- [ ] 최소 1명 이상의 리뷰어 승인 필요 (Code Review → QA 전환 조건)
- [ ] CI 빌드 통과 필수
- [ ] 충돌 해결 후 병합
- [ ] Squash Merge 사용 (feature → develop)
- [ ] PR 크기 400줄 이하 권장

## 4. .gitignore 기본 설정

```
node_modules/
.env
.env.local
dist/
build/
target/
*.log
.DS_Store
.idea/
.vscode/
```

## 변경 이력

| 버전 | 날짜 | 작성자 | 변경 내용 |
|------|------|--------|-----------|
| v1.0 | 2026-03-21 | 팀 | 최초 작성 |
