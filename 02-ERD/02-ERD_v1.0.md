---
문서명: Jira 프로젝트 관리 시스템 ERD 문서
버전: v1.0
작성일: 2026-03-21
최종수정일: 2026-03-21
작성자: 팀
상태: 초안
---

# Jira 프로젝트 관리 시스템 ERD (Entity-Relationship Diagram)

## 1. 개요

본 문서는 Jira 프로젝트 관리 시스템의 데이터베이스 구조를 정의한다.

### 1.1 데이터베이스 정보

| 항목 | 내용 |
|------|------|
| DBMS | PostgreSQL |
| 버전 | 16.x |
| 문자셋 | UTF-8 |
| Collation | ko_KR.UTF-8 |

## 2. ERD 다이어그램

```mermaid
erDiagram
    PROJECT {
        bigint id PK "프로젝트 ID"
        varchar key UK "프로젝트 키 (예: PROJ)"
        varchar name "프로젝트명"
        text description "설명"
        enum board_type "보드 타입 (SCRUM, KANBAN)"
        bigint lead_id FK "프로젝트 리더 ID"
        boolean archived "아카이브 여부"
        timestamp created_at "생성일"
        timestamp updated_at "수정일"
    }

    USER_ACCOUNT {
        bigint id PK "사용자 ID"
        varchar email UK "이메일"
        varchar password "비밀번호 (해시)"
        varchar name "이름"
        enum role "역할 (ADMIN, DEVELOPER, QA, REPORTER, VIEWER)"
        timestamp created_at "생성일"
        timestamp updated_at "수정일"
    }

    ISSUE {
        bigint id PK "이슈 ID"
        varchar issue_key UK "이슈 키 (예: PROJ-142)"
        bigint project_id FK "프로젝트 ID"
        enum issue_type "타입 (EPIC, STORY, TASK, BUG, SUBTASK)"
        varchar summary "제목"
        text description "설명"
        enum status "상태 (BACKLOG, SELECTED, IN_PROGRESS, CODE_REVIEW, QA, DONE)"
        enum priority "우선순위 (HIGHEST, HIGH, MEDIUM, LOW, LOWEST)"
        int story_points "스토리 포인트"
        bigint assignee_id FK "담당자 ID"
        bigint reporter_id FK "보고자 ID"
        bigint parent_id FK "상위 이슈 ID (Epic/Story)"
        bigint sprint_id FK "스프린트 ID"
        bigint fix_version_id FK "릴리즈 버전 ID"
        enum security_level "보안 레벨 (PUBLIC, INTERNAL, CONFIDENTIAL)"
        timestamp created_at "생성일"
        timestamp updated_at "수정일"
    }

    SPRINT {
        bigint id PK "스프린트 ID"
        bigint project_id FK "프로젝트 ID"
        varchar name "스프린트명"
        enum status "상태 (PLANNING, ACTIVE, COMPLETED)"
        date start_date "시작일"
        date end_date "종료일"
        int goal_points "목표 포인트"
        timestamp created_at "생성일"
    }

    RELEASE_VERSION {
        bigint id PK "버전 ID"
        bigint project_id FK "프로젝트 ID"
        varchar name "버전명 (예: v1.0.0)"
        text description "설명"
        date release_date "배포 예정일"
        enum status "상태 (UNRELEASED, RELEASED)"
        timestamp created_at "생성일"
    }

    WORKFLOW_TRANSITION {
        bigint id PK "전환 ID"
        bigint issue_id FK "이슈 ID"
        enum from_status "이전 상태"
        enum to_status "이후 상태"
        bigint changed_by FK "변경자 ID"
        text condition_note "전환 조건"
        timestamp transitioned_at "전환 시각"
    }

    COMMENT {
        bigint id PK "댓글 ID"
        bigint issue_id FK "이슈 ID"
        bigint author_id FK "작성자 ID"
        text body "댓글 내용"
        timestamp created_at "생성일"
        timestamp updated_at "수정일"
    }

    ISSUE_LINK {
        bigint id PK "링크 ID"
        bigint source_issue_id FK "출발 이슈 ID"
        bigint target_issue_id FK "도착 이슈 ID"
        enum link_type "관계 (BLOCKS, DUPLICATES, RELATES_TO)"
    }

    AUDIT_LOG {
        bigint id PK "로그 ID"
        bigint issue_id FK "이슈 ID"
        bigint changed_by FK "변경자 ID"
        varchar field_name "변경 필드"
        text old_value "이전 값"
        text new_value "새 값"
        timestamp changed_at "변경 시각"
    }

    LABEL {
        bigint id PK "레이블 ID"
        varchar name UK "레이블명"
    }

    COMPONENT {
        bigint id PK "컴포넌트 ID"
        bigint project_id FK "프로젝트 ID"
        varchar name "컴포넌트명"
        bigint lead_id FK "담당자 ID"
    }

    PROJECT ||--o{ ISSUE : "포함"
    PROJECT ||--o{ SPRINT : "운영"
    PROJECT ||--o{ RELEASE_VERSION : "관리"
    PROJECT ||--o{ COMPONENT : "구성"
    USER_ACCOUNT ||--o{ ISSUE : "담당"
    USER_ACCOUNT ||--o{ COMMENT : "작성"
    ISSUE ||--o{ COMMENT : "포함"
    ISSUE ||--o{ WORKFLOW_TRANSITION : "전환 이력"
    ISSUE ||--o{ AUDIT_LOG : "변경 이력"
    ISSUE ||--o{ ISSUE_LINK : "연결"
    SPRINT ||--o{ ISSUE : "포함"
    RELEASE_VERSION ||--o{ ISSUE : "배포 대상"
```

## 3. 테이블 상세 명세

### 3.1 PROJECT (프로젝트)

| 컬럼명 | 타입 | 제약조건 | 기본값 | 설명 |
|--------|------|----------|--------|------|
| id | BIGINT | PK, AUTO_INCREMENT | - | 프로젝트 ID |
| key | VARCHAR(10) | UNIQUE, NOT NULL | - | 프로젝트 키 |
| name | VARCHAR(200) | NOT NULL | - | 프로젝트명 |
| description | TEXT | - | NULL | 설명 |
| board_type | ENUM('SCRUM','KANBAN') | NOT NULL | 'SCRUM' | 보드 타입 |
| lead_id | BIGINT | FK(USER_ACCOUNT) | - | 프로젝트 리더 |
| archived | BOOLEAN | NOT NULL | false | 아카이브 여부 |
| created_at | TIMESTAMP | NOT NULL | CURRENT_TIMESTAMP | 생성일 |
| updated_at | TIMESTAMP | NOT NULL | CURRENT_TIMESTAMP | 수정일 |

### 3.2 ISSUE (이슈)

| 컬럼명 | 타입 | 제약조건 | 기본값 | 설명 |
|--------|------|----------|--------|------|
| id | BIGINT | PK, AUTO_INCREMENT | - | 이슈 ID |
| issue_key | VARCHAR(20) | UNIQUE, NOT NULL | - | 이슈 키 |
| project_id | BIGINT | FK(PROJECT), NOT NULL | - | 프로젝트 ID |
| issue_type | ENUM('EPIC','STORY','TASK','BUG','SUBTASK') | NOT NULL | - | 이슈 타입 |
| summary | VARCHAR(500) | NOT NULL | - | 제목 |
| description | TEXT | - | NULL | 설명 |
| status | ENUM('BACKLOG','SELECTED','IN_PROGRESS','CODE_REVIEW','QA','DONE') | NOT NULL | 'BACKLOG' | 상태 |
| priority | ENUM('HIGHEST','HIGH','MEDIUM','LOW','LOWEST') | NOT NULL | 'MEDIUM' | 우선순위 |
| story_points | INT | - | NULL | 스토리 포인트 |
| assignee_id | BIGINT | FK(USER_ACCOUNT) | NULL | 담당자 |
| reporter_id | BIGINT | FK(USER_ACCOUNT), NOT NULL | - | 보고자 |
| parent_id | BIGINT | FK(ISSUE) | NULL | 상위 이슈 ID |
| sprint_id | BIGINT | FK(SPRINT) | NULL | 스프린트 ID |
| fix_version_id | BIGINT | FK(RELEASE_VERSION) | NULL | 릴리즈 버전 |
| security_level | ENUM('PUBLIC','INTERNAL','CONFIDENTIAL') | NOT NULL | 'PUBLIC' | 보안 레벨 |
| created_at | TIMESTAMP | NOT NULL | CURRENT_TIMESTAMP | 생성일 |
| updated_at | TIMESTAMP | NOT NULL | CURRENT_TIMESTAMP | 수정일 |

**인덱스**:
- `idx_issue_project` (project_id) - 프로젝트별 이슈 조회
- `idx_issue_assignee` (assignee_id) - 담당자별 이슈 조회
- `idx_issue_status` (status) - 상태별 이슈 조회
- `idx_issue_sprint` (sprint_id) - 스프린트별 이슈 조회

## 4. 관계 정의

| 부모 테이블 | 자식 테이블 | 관계 | FK 컬럼 | 설명 |
|------------|------------|------|---------|------|
| PROJECT | ISSUE | 1:N | project_id | 프로젝트에 속한 이슈 |
| PROJECT | SPRINT | 1:N | project_id | 프로젝트의 스프린트 |
| PROJECT | RELEASE_VERSION | 1:N | project_id | 프로젝트의 릴리즈 버전 |
| PROJECT | COMPONENT | 1:N | project_id | 프로젝트의 컴포넌트 |
| USER_ACCOUNT | ISSUE | 1:N | assignee_id | 담당자-이슈 |
| USER_ACCOUNT | COMMENT | 1:N | author_id | 작성자-댓글 |
| ISSUE | COMMENT | 1:N | issue_id | 이슈의 댓글 |
| ISSUE | WORKFLOW_TRANSITION | 1:N | issue_id | 이슈의 상태 전환 이력 |
| ISSUE | AUDIT_LOG | 1:N | issue_id | 이슈의 변경 이력 |
| ISSUE | ISSUE | 1:N | parent_id | 상위-하위 이슈 계층 (Epic→Story→Sub-task) |
| SPRINT | ISSUE | 1:N | sprint_id | 스프린트에 포함된 이슈 |
| RELEASE_VERSION | ISSUE | 1:N | fix_version_id | 릴리즈에 포함된 이슈 |

## 5. 데이터 마이그레이션 노트

- 초기 시딩: 기본 프로젝트 역할(ADMIN, DEVELOPER, QA, REPORTER, VIEWER) 생성
- 표준 워크플로우 상태 6단계 초기화
- 기본 우선순위(HIGHEST~LOWEST) 및 이슈 타입(EPIC~SUBTASK) 등록

## 변경 이력

| 버전 | 날짜 | 작성자 | 변경 내용 |
|------|------|--------|-----------|
| v1.0 | 2026-03-21 | 팀 | 최초 작성 |
