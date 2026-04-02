---
title: LearnFlow AI — API 정의서
version: v5.0
project: LearnFlow AI (AI 기반 적응형 학습 관리 시스템)
date: 2026-04-02
author: Architecture Team
status: APPROVED
prev_version: v4.0
---

# LearnFlow AI — API 정의서 v5.0

## 변경 이력

| 버전 | 날짜 | 변경 내용 | 작성자 |
|------|------|-----------|--------|
| v1.0 | 2025-09-01 | 초기 API (사용자/강의/퀴즈 기본) | Architecture Team |
| v2.0 | 2025-11-01 | AI 튜터 API, SSE 스트리밍, 임베딩 이벤트 | Architecture Team |
| v3.0 | 2026-01-15 | 이의 제기 API, RAGAS 품질, FinOps Admin | Architecture Team |
| v4.0 | 2026-03-01 | Manual Review Queue, 온보딩 진단, DeepEval, rubric_coverage | Architecture Team |
| v5.0 | 2026-04-02 | Request/Response 예시 전면 보강, 이벤트 트리거 표시 정형화, SSE 명세 분리 | Architecture Team |

---

## 1. 개요

### 1.1 공통 규칙

| 항목 | 규정 |
|------|------|
| Base URL | `https://api.learnflow.ai/api/v1` |
| 프로토콜 | HTTPS (TLS 1.3+) |
| 인증 | `Authorization: Bearer {JWT Access Token}` |
| 응답 형식 | `Content-Type: application/json; charset=UTF-8` |
| 날짜 형식 | ISO 8601 — `2026-04-02T09:00:00Z` |
| 페이지네이션 | `?page=0&size=20&sort=createdAt,desc` |
| 에러 형식 | 공통 에러 응답 (아래 참조) |

### 1.2 공통 에러 응답

```json
{
  "status": 400,
  "code": "VALIDATION_ERROR",
  "message": "요청 데이터가 유효하지 않습니다.",
  "errors": [
    { "field": "email", "message": "이메일 형식이 올바르지 않습니다." }
  ],
  "traceId": "4bf92f3577b34da6a3ce929d0e0e4736",
  "timestamp": "2026-04-02T09:00:00Z"
}
```

| HTTP 상태 | 코드 | 설명 |
|-----------|------|------|
| 400 | VALIDATION_ERROR | 요청 데이터 유효성 오류 |
| 401 | UNAUTHORIZED | 인증 토큰 없음/만료 |
| 403 | FORBIDDEN | 권한 부족 |
| 404 | NOT_FOUND | 리소스 없음 |
| 409 | CONFLICT | 중복 데이터 |
| 429 | RATE_LIMIT_EXCEEDED | 요청 빈도 초과 |
| 500 | INTERNAL_ERROR | 서버 내부 오류 |
| 503 | AI_SERVICE_UNAVAILABLE | AI 서비스 일시 중단 (Kill-switch) |

### 1.3 표기 규칙

- `→ Event` : 해당 API 처리 시 Outbox 이벤트 발행
- `[SSE]` : Server-Sent Events 스트리밍 응답
- 권한: `PUBLIC` / `LEARNER` / `INSTRUCTOR` / `ADMIN`

---

## 2. API 그룹 목록

| # | 그룹 | Base Path |
|---|------|-----------|
| 9.1 | 사용자/인증 | `/api/v1/auth`, `/api/v1/users` |
| 9.2 | 강의 | `/api/v1/courses`, `/api/v1/sections`, `/api/v1/lessons` |
| 9.3 | AI 튜터 | `/api/v1/ai/chat` |
| 9.4 | 퀴즈/과제 | `/api/v1/quizzes`, `/api/v1/assignments`, `/api/v1/instructor` |
| 9.5 | 학습 분석 | `/api/v1/analytics` |
| 9.6 | 온보딩 | `/api/v1/onboarding` |
| 9.7 | 콘텐츠 요약 | `/api/v1/ai/summarize`, `/api/v1/ai/flashcards` |
| 9.8 | AI 품질 관리 (Admin) | `/api/v1/admin/ai` |
| 9.9 | FinOps (Admin) | `/api/v1/admin/finops` |

---

## 9.1 사용자 / 인증

### 엔드포인트 목록

| Method | URL | 설명 | 권한 |
|--------|-----|------|------|
| POST | `/auth/signup` | 회원가입 | PUBLIC |
| POST | `/auth/login` | 로그인 (JWT 발급) | PUBLIC |
| POST | `/auth/refresh` | Access Token 갱신 | AUTHENTICATED |
| GET | `/users/me` | 내 프로필 조회 | AUTHENTICATED |
| PUT | `/users/me` | 프로필 수정 | AUTHENTICATED |
| PUT | `/users/me/learning-prefs` | 학습 선호 설정 | LEARNER |

---

#### POST `/auth/signup` — 회원가입

**Request**
```json
{
  "email": "learner@example.com",
  "password": "Secure#1234",
  "nickname": "김학습",
  "role": "LEARNER"
}
```

**Response** `201 Created`
```json
{
  "id": 42,
  "email": "learner@example.com",
  "nickname": "김학습",
  "role": "LEARNER",
  "createdAt": "2026-04-02T09:00:00Z"
}
```

---

#### POST `/auth/login` — 로그인

**Request**
```json
{
  "email": "learner@example.com",
  "password": "Secure#1234"
}
```

**Response** `200 OK`
```json
{
  "accessToken": "eyJhbGciOiJIUzI1NiJ9...",
  "refreshToken": "dGhpcyBpcyBhIHJlZnJlc2g...",
  "tokenType": "Bearer",
  "expiresIn": 900
}
```

---

#### GET `/users/me` — 내 프로필 조회

**Response** `200 OK`
```json
{
  "id": 42,
  "email": "learner@example.com",
  "nickname": "김학습",
  "role": "LEARNER",
  "level": 5,
  "expPoint": 1240,
  "bio": "Spring Boot를 배우는 중입니다.",
  "avatarUrl": "https://cdn.learnflow.ai/avatars/42.png",
  "learningPrefs": {
    "preferredPace": "NORMAL",
    "dailyGoalMin": 60,
    "difficulty": "INTERMEDIATE",
    "interests": ["BACKEND", "SPRING", "JPA"]
  }
}
```

---

#### PUT `/users/me/learning-prefs` — 학습 선호 설정

**Request**
```json
{
  "preferredPace": "FAST",
  "dailyGoalMin": 90,
  "difficulty": "ADVANCED",
  "interests": ["ARCHITECTURE", "KAFKA", "AI"]
}
```

**Response** `200 OK`
```json
{
  "message": "학습 선호가 업데이트되었습니다.",
  "updatedAt": "2026-04-02T09:05:00Z"
}
```

---

## 9.2 강의

### 엔드포인트 목록

| Method | URL | 설명 | 권한 | 이벤트 |
|--------|-----|------|------|--------|
| GET | `/courses` | 강의 목록 (검색/필터) | PUBLIC | |
| GET | `/courses/{id}` | 강의 상세 | PUBLIC | |
| POST | `/courses` | 강의 생성 | INSTRUCTOR | |
| PUT | `/courses/{id}` | 강의 수정 | INSTRUCTOR | |
| POST | `/courses/{id}/sections` | 섹션 추가 | INSTRUCTOR | |
| POST | `/sections/{id}/lessons` | 레슨 추가 | INSTRUCTOR | → `ContentCreated` |
| PUT | `/lessons/{id}` | 레슨 수정 | INSTRUCTOR | → `ContentUpdated` |
| DELETE | `/lessons/{id}` | 레슨 삭제 | INSTRUCTOR | → `ContentDeleted` |
| POST | `/courses/{id}/enroll` | 수강 신청 | LEARNER | |
| GET | `/courses/{id}/progress` | 진도율 조회 | LEARNER | |
| PUT | `/lessons/{id}/complete` | 레슨 완료 처리 | LEARNER | → `LessonCompleted` |

---

#### GET `/courses` — 강의 목록

**Query Parameters**
| 파라미터 | 타입 | 필수 | 설명 |
|---------|------|------|------|
| keyword | String | | 검색어 |
| category | String | | 카테고리 필터 |
| level | Enum | | BEGINNER / INTERMEDIATE / ADVANCED |
| page | Int | | 페이지 번호 (default: 0) |
| size | Int | | 페이지 크기 (default: 20) |

**Response** `200 OK`
```json
{
  "content": [
    {
      "id": 10,
      "title": "Spring Boot 4 완전 정복",
      "instructorName": "박강사",
      "category": "BACKEND",
      "level": "INTERMEDIATE",
      "thumbnailUrl": "https://cdn.learnflow.ai/courses/10.png",
      "price": 49000,
      "avgRating": 4.8,
      "enrollmentCount": 1240,
      "status": "PUBLISHED"
    }
  ],
  "totalElements": 1,
  "totalPages": 1,
  "page": 0,
  "size": 20
}
```

---

#### POST `/sections/{sectionId}/lessons` — 레슨 추가 → `ContentCreated`

**Request**
```json
{
  "title": "JPA Lazy Loading 원리",
  "type": "VIDEO",
  "content": "Lazy Loading은 실제 접근 시점에 쿼리를 실행합니다...",
  "videoUrl": "https://cdn.learnflow.ai/videos/lesson-55.mp4",
  "durationMin": 25,
  "orderNum": 3
}
```

**Response** `201 Created`
```json
{
  "id": 55,
  "sectionId": 12,
  "title": "JPA Lazy Loading 원리",
  "type": "VIDEO",
  "orderNum": 3,
  "createdAt": "2026-04-02T10:00:00Z",
  "event": "ContentCreated"
}
```

> **이벤트**: `ContentCreated` → Outbox → Kafka(`content.created`) → Embedding Worker (청킹 + 임베딩 생성)

---

#### PUT `/lessons/{id}/complete` — 레슨 완료 → `LessonCompleted`

**Response** `200 OK`
```json
{
  "lessonId": 55,
  "courseProgress": 68.5,
  "expPointEarned": 50,
  "event": "LessonCompleted"
}
```

> **이벤트**: `LessonCompleted` → Outbox → Kafka(`lesson.completed`) → Analytics Worker (진도/취약점/mastery 갱신)

---

## 9.3 AI 튜터

### 엔드포인트 목록

| Method | URL | 설명 | 권한 | 비고 |
|--------|-----|------|------|------|
| POST | `/ai/chat/sessions` | 채팅 세션 생성 | LEARNER | |
| POST | `/ai/chat/sessions/{id}/messages` | 메시지 전송 | LEARNER | **[SSE]** |
| GET | `/ai/chat/sessions` | 세션 목록 | LEARNER | |
| GET | `/ai/chat/sessions/{id}/messages` | 대화 히스토리 | LEARNER | |
| POST | `/ai/chat/messages/{id}/feedback` | 피드백 (좋아요/싫어요) | LEARNER | |
| GET | `/ai/chat/sessions/{id}/suggestions` | 추천 질문 | LEARNER | |

---

#### POST `/ai/chat/sessions` — 채팅 세션 생성

**Request**
```json
{
  "courseId": 10,
  "title": "JPA 질문 세션"
}
```

**Response** `201 Created`
```json
{
  "sessionId": 301,
  "courseId": 10,
  "title": "JPA 질문 세션",
  "createdAt": "2026-04-02T11:00:00Z"
}
```

---

#### POST `/ai/chat/sessions/{id}/messages` — 메시지 전송 [SSE]

**Request**
```json
{
  "content": "JPA Lazy Loading이 왜 N+1 문제를 유발하나요?",
  "lessonId": 55
}
```

**Response** `200 OK` — `Content-Type: text/event-stream`

```
data: {"type":"start","messageId":1024,"model":"claude-3-5-sonnet"}

data: {"type":"chunk","content":"N+1 문제는 "}

data: {"type":"chunk","content":"연관 엔티티를 "}

data: {"type":"chunk","content":"각각 별도 쿼리로 조회할 때 발생합니다. "}

data: {"type":"chunk","content":"예를 들어 Order 10개를 조회하면 각 Order의 Member를..."}

data: {"type":"end","tokenUsed":{"input":320,"output":210},"costUsd":0.00265,"cacheHit":false}
```

> **SSE 이벤트 타입**:
> - `start`: 스트리밍 시작 (messageId, 모델명)
> - `chunk`: 텍스트 청크
> - `end`: 완료 (토큰/비용/캐시 히트 여부)
> - `error`: 오류 발생

---

#### POST `/ai/chat/messages/{id}/feedback` — 피드백

**Request**
```json
{
  "feedback": "BAD",
  "comment": "설명이 너무 어렵습니다. 비유를 써주세요."
}
```

**Response** `200 OK`
```json
{
  "messageId": 1024,
  "feedback": "BAD",
  "message": "피드백이 기록되었습니다. AI 품질 개선에 활용됩니다."
}
```

---

#### GET `/ai/chat/sessions/{id}/suggestions` — 추천 질문

**Response** `200 OK`
```json
{
  "sessionId": 301,
  "suggestions": [
    "Fetch Join으로 N+1을 어떻게 해결하나요?",
    "EAGER Loading과 LAZY Loading의 차이는?",
    "EntityGraph를 사용하는 방법은?"
  ]
}
```

---

## 9.4 퀴즈 / 과제

### 엔드포인트 목록

| Method | URL | 설명 | 권한 | 이벤트 |
|--------|-----|------|------|--------|
| POST | `/ai/quizzes/generate` | AI 퀴즈 생성 | INSTRUCTOR | |
| GET | `/lessons/{id}/quizzes` | 레슨별 퀴즈 목록 | LEARNER | |
| POST | `/quizzes/{id}/submit` | 퀴즈 제출 | LEARNER | → `QuizSubmitted` |
| GET | `/quizzes/{id}/results` | 결과 + AI 피드백 조회 | LEARNER | |
| POST | `/assignments/{id}/submit` | 과제 제출 | LEARNER | → `AssignmentSubmitted` |
| GET | `/assignments/submissions/{id}` | 과제 제출물 조회 | LEARNER | |
| POST | `/quizzes/attempts/{id}/appeal` | 퀴즈 채점 이의 제기 | LEARNER | → `GradingAppeal` |
| POST | `/assignments/submissions/{id}/appeal` | 과제 채점 이의 제기 | LEARNER | → `GradingAppeal` |
| GET | `/instructor/review-queue` | Manual Review 대기 목록 | INSTRUCTOR | |
| PUT | `/instructor/review-queue/{id}/resolve` | 검토 완료 처리 | INSTRUCTOR | |

---

#### POST `/ai/quizzes/generate` — AI 퀴즈 생성

**Request**
```json
{
  "lessonId": 55,
  "questionCount": 5,
  "difficulty": "MEDIUM",
  "bloomDistribution": {
    "REMEMBER": 1,
    "UNDERSTAND": 1,
    "APPLY": 2,
    "ANALYZE": 1
  }
}
```

**Response** `201 Created`
```json
{
  "quizId": 200,
  "lessonId": 55,
  "title": "JPA Lazy Loading 퀴즈",
  "aiGenerated": true,
  "promptVersion": "tutor-quiz-v3.2",
  "questions": [
    {
      "id": 501,
      "question": "Lazy Loading이 실제 쿼리를 실행하는 시점은?",
      "type": "MULTIPLE_CHOICE",
      "bloomLevel": "REMEMBER",
      "options": ["엔티티 생성 시", "실제 필드 접근 시", "트랜잭션 시작 시", "영속성 컨텍스트 종료 시"],
      "orderNum": 1
    }
  ]
}
```

---

#### POST `/quizzes/{id}/submit` — 퀴즈 제출 → `QuizSubmitted`

**Request**
```json
{
  "answers": [
    { "questionId": 501, "answer": "실제 필드 접근 시" },
    { "questionId": 502, "answer": "false" }
  ]
}
```

**Response** `202 Accepted`
```json
{
  "attemptId": 750,
  "quizId": 200,
  "status": "SUBMITTED",
  "message": "채점이 진행 중입니다.",
  "event": "QuizSubmitted"
}
```

> **이벤트**: `QuizSubmitted` → Outbox → Kafka(`quiz.submitted`) → AI Grading Worker (자동 채점 + Confidence Score)

---

#### GET `/quizzes/{id}/results` — 결과 + AI 피드백

**Response** `200 OK`
```json
{
  "attemptId": 750,
  "quizId": 200,
  "score": 80.0,
  "status": "GRADED",
  "aiFeedback": "Lazy Loading의 시점에 대해 정확히 이해하고 있습니다. N+1 문제 방지를 위해 Fetch Join 활용을 추천합니다.",
  "questions": [
    {
      "questionId": 501,
      "yourAnswer": "실제 필드 접근 시",
      "correct": true,
      "explanation": "JPA Proxy 객체는 실제 필드에 접근할 때 SELECT 쿼리를 실행합니다."
    }
  ],
  "gradedAt": "2026-04-02T11:05:30Z"
}
```

---

#### POST `/assignments/submissions/{id}/appeal` — 과제 채점 이의 제기 → `GradingAppeal`

**Request**
```json
{
  "reason": "루브릭 3번 항목(예외 처리)이 채점에서 누락된 것 같습니다. 제 코드에서 try-catch 블록을 명확히 구현했습니다."
}
```

**Response** `200 OK`
```json
{
  "submissionId": 890,
  "status": "APPEALED",
  "appealAt": "2026-04-02T12:00:00Z",
  "message": "이의 제기가 접수되었습니다. 강사가 7영업일 내에 검토합니다.",
  "event": "GradingAppeal"
}
```

> **이벤트**: `GradingAppeal` → Kafka(`grading.appeal`) → Notification Consumer (강사 Manual Review Queue 알림)

---

#### GET `/instructor/review-queue` — Manual Review 대기 목록

**Query Parameters**: `?type=ASSIGNMENT&status=MANUAL_REVIEW&page=0&size=20`

**Response** `200 OK`
```json
{
  "content": [
    {
      "id": 890,
      "type": "ASSIGNMENT",
      "submissionId": 890,
      "studentName": "김학습",
      "assignmentTitle": "Spring Boot 예외 처리 구현",
      "aiScore": 65.0,
      "aiConfidence": 0.62,
      "status": "MANUAL_REVIEW",
      "reason": "ai_confidence < 0.8 (자동 이관)",
      "submittedAt": "2026-04-02T10:30:00Z"
    },
    {
      "id": 891,
      "type": "ASSIGNMENT",
      "submissionId": 891,
      "studentName": "이수강",
      "assignmentTitle": "JPA N+1 최적화",
      "aiScore": 72.0,
      "aiConfidence": 0.71,
      "status": "APPEALED",
      "reason": "학습자 이의 제기",
      "appealReason": "루브릭 3번 항목이 채점에서 누락...",
      "submittedAt": "2026-04-02T09:15:00Z"
    }
  ],
  "totalElements": 2,
  "page": 0,
  "size": 20
}
```

---

#### PUT `/instructor/review-queue/{id}/resolve` — 검토 완료

**Request**
```json
{
  "instructorScore": 82.0,
  "instructorFeedback": "예외 처리 구현은 적절합니다. 다만 커스텀 예외 계층 설계가 더 명확했으면 좋겠습니다.",
  "resolution": "SCORE_ADJUSTED"
}
```

**Response** `200 OK`
```json
{
  "submissionId": 890,
  "status": "CONFIRMED",
  "instructorScore": 82.0,
  "reviewedAt": "2026-04-02T14:00:00Z"
}
```

---

## 9.5 학습 분석

### 엔드포인트 목록

| Method | URL | 설명 | 권한 |
|--------|-----|------|------|
| GET | `/analytics/me/dashboard` | 학습 종합 대시보드 | LEARNER |
| GET | `/analytics/me/weaknesses` | 취약점 분석 | LEARNER |
| GET | `/analytics/me/concept-mastery` | 개념별 숙련도 | LEARNER |
| GET | `/analytics/me/recommendations` | AI 학습 추천 | LEARNER |
| GET | `/analytics/me/study-time` | 학습 시간 현황 | LEARNER |
| GET | `/analytics/courses/{id}/overview` | 강의 전체 분석 | INSTRUCTOR |

---

#### GET `/analytics/me/dashboard` — 학습 대시보드

**Response** `200 OK`
```json
{
  "userId": 42,
  "summary": {
    "totalStudyTimeMin": 1240,
    "coursesEnrolled": 3,
    "coursesCompleted": 1,
    "avgMasteryScore": 0.72,
    "weeklyGoalProgress": 85.0
  },
  "recentActivity": [
    {
      "lessonId": 55,
      "lessonTitle": "JPA Lazy Loading 원리",
      "activityType": "LESSON_VIEW",
      "durationMin": 25,
      "completedAt": "2026-04-02T11:30:00Z"
    }
  ],
  "topWeakConcepts": [
    { "concept": "JPA N+1", "masteryScore": 0.35 },
    { "concept": "Kafka Consumer 멱등성", "masteryScore": 0.42 }
  ]
}
```

---

#### GET `/analytics/me/concept-mastery` — 개념별 숙련도

**Query Parameters**: `?courseId=10`

**Response** `200 OK`
```json
{
  "courseId": 10,
  "concepts": [
    {
      "concept": "Spring IoC",
      "masteryScore": 0.88,
      "confidence": 0.90,
      "source": "QUIZ",
      "attemptCount": 5,
      "lastUpdated": "2026-04-01T15:00:00Z"
    },
    {
      "concept": "JPA N+1",
      "masteryScore": 0.35,
      "confidence": 0.70,
      "source": "DIAGNOSTIC",
      "attemptCount": 2,
      "lastUpdated": "2026-04-02T09:00:00Z"
    }
  ]
}
```

---

#### GET `/analytics/me/recommendations` — AI 학습 추천

**Response** `200 OK`
```json
{
  "userId": 42,
  "recommendations": [
    {
      "type": "LESSON",
      "lessonId": 58,
      "lessonTitle": "Fetch Join으로 N+1 해결",
      "reason": "concept 'JPA N+1' 숙련도 0.35로 낮음",
      "priority": 1
    },
    {
      "type": "QUIZ",
      "lessonId": 60,
      "lessonTitle": "Kafka Consumer 실습 퀴즈",
      "reason": "concept 'Kafka Consumer 멱등성' 숙련도 0.42, confidence 낮음",
      "priority": 2
    }
  ]
}
```

---

## 9.6 온보딩

### 엔드포인트 목록

| Method | URL | 설명 | 권한 |
|--------|-----|------|------|
| GET | `/onboarding/diagnostic/{courseId}` | 진단 테스트 문항 조회 | LEARNER |
| POST | `/onboarding/diagnostic/{courseId}/submit` | 진단 결과 제출 | LEARNER |
| POST | `/onboarding/self-assess` | 자가 진단 제출 | LEARNER |

---

#### GET `/onboarding/diagnostic/{courseId}` — 진단 테스트

**Response** `200 OK`
```json
{
  "testId": 5,
  "courseId": 10,
  "title": "Spring Boot 4 진단 테스트",
  "estimatedMinutes": 5,
  "bloomDistribution": {
    "REMEMBER": 1,
    "UNDERSTAND": 1,
    "APPLY": 1,
    "ANALYZE": 1,
    "EVALUATE": 1
  },
  "questions": [
    {
      "id": 101,
      "question": "@SpringBootApplication 어노테이션의 역할은?",
      "type": "MULTIPLE_CHOICE",
      "bloomLevel": "REMEMBER",
      "options": ["컴포넌트 스캔 활성화", "서버 시작", "DB 연결", "보안 설정"],
      "orderNum": 1
    }
  ]
}
```

---

#### POST `/onboarding/diagnostic/{courseId}/submit` — 진단 결과 제출

**Request**
```json
{
  "testId": 5,
  "answers": [
    { "questionId": 101, "answer": "컴포넌트 스캔 활성화" },
    { "questionId": 102, "answer": "B" }
  ]
}
```

**Response** `200 OK`
```json
{
  "resultId": 88,
  "diagnosedLevel": "INTERMEDIATE",
  "confidenceWeight": 0.7,
  "conceptScores": {
    "Spring IoC": 0.8,
    "Spring MVC": 0.6,
    "JPA 기본": 0.4,
    "Security": 0.3
  },
  "message": "진단이 완료되었습니다. AI 튜터가 취약 개념 학습을 우선 추천합니다."
}
```

---

#### POST `/onboarding/self-assess` — 자가 진단

**Request**
```json
{
  "courseId": 10,
  "selfLevel": "BEGINNER"
}
```

**Response** `200 OK`
```json
{
  "diagnosedLevel": "BEGINNER",
  "confidenceWeight": 0.3,
  "message": "자가 진단이 완료되었습니다. 퀴즈를 통해 더 정확한 수준 측정이 이루어집니다.",
  "initialMasteryScore": 0.1
}
```

---

## 9.7 콘텐츠 요약

### 엔드포인트 목록

| Method | URL | 설명 | 권한 | 비고 |
|--------|-----|------|------|------|
| POST | `/ai/summarize/lesson/{id}` | 레슨 AI 요약 | LEARNER | [SSE] |
| POST | `/ai/flashcards/generate/{lessonId}` | 플래시카드 AI 생성 | LEARNER | |

---

#### POST `/ai/summarize/lesson/{id}` — 레슨 요약 [SSE]

**Request**
```json
{
  "style": "BULLET_POINTS",
  "maxLength": 500
}
```

**Response** `200 OK` — `Content-Type: text/event-stream`

```
data: {"type":"start","lessonId":55}

data: {"type":"chunk","content":"## JPA Lazy Loading 핵심 요약\n\n"}

data: {"type":"chunk","content":"- **정의**: 연관 엔티티를 실제 접근 시점에 로딩하는 전략\n"}

data: {"type":"chunk","content":"- **장점**: 불필요한 JOIN 쿼리 방지, 성능 최적화\n"}

data: {"type":"chunk","content":"- **주의**: N+1 문제 발생 가능 → Fetch Join 또는 @BatchSize 사용 권장\n"}

data: {"type":"end","tokenUsed":{"input":180,"output":95},"costUsd":0.00120}
```

---

#### POST `/ai/flashcards/generate/{lessonId}` — 플래시카드 생성

**Response** `201 Created`
```json
{
  "lessonId": 55,
  "flashcards": [
    {
      "id": 1,
      "front": "JPA Lazy Loading이란?",
      "back": "연관 엔티티를 실제로 접근하는 시점에 SELECT 쿼리를 실행하여 로딩하는 전략",
      "bloomLevel": "UNDERSTAND"
    },
    {
      "id": 2,
      "front": "N+1 문제란?",
      "back": "1개의 쿼리로 N개 엔티티 조회 후, 각 엔티티의 연관 관계를 N번 추가 쿼리로 조회하는 문제",
      "bloomLevel": "ANALYZE"
    }
  ],
  "totalCount": 5,
  "tokenUsed": 240
}
```

---

## 9.8 AI 품질 관리 (Admin)

### 엔드포인트 목록

| Method | URL | 설명 | 권한 |
|--------|-----|------|------|
| GET | `/admin/ai/quality/dashboard` | AI 품질 종합 대시보드 | ADMIN |
| GET | `/admin/ai/quality/ragas/summary` | RAGAS 주간 요약 | ADMIN |
| GET | `/admin/ai/quality/ragas/trends` | RAGAS 지표 트렌드 | ADMIN |
| POST | `/admin/ai/ab-tests` | A/B 테스트 생성 | ADMIN |
| GET | `/admin/ai/ab-tests/{id}/results` | A/B 테스트 결과 | ADMIN |
| GET | `/admin/ai/prompts` | 프롬프트 버전 목록 | ADMIN |
| POST | `/admin/ai/prompts` | 새 프롬프트 버전 등록 | ADMIN |
| PUT | `/admin/ai/prompts/{id}/rollback` | 프롬프트 롤백 | ADMIN |

---

#### GET `/admin/ai/quality/dashboard` — AI 품질 대시보드

**Response** `200 OK`
```json
{
  "period": "2026-W14",
  "summary": {
    "totalEvaluations": 1250,
    "avgFaithfulness": 0.82,
    "avgContextPrecision": 0.79,
    "avgContextRecall": 0.75,
    "avgAnswerRelevancy": 0.88,
    "avgDeepevalHallucination": 0.12,
    "lowQualityCount": 43,
    "userThumbsUpRate": 0.87,
    "userThumbsDownRate": 0.13
  },
  "alerts": [
    {
      "type": "LOW_FAITHFULNESS",
      "count": 18,
      "threshold": 0.7,
      "message": "faithfulness < 0.7 응답 18건 → 주간 리뷰 대기"
    }
  ]
}
```

---

#### GET `/admin/ai/quality/ragas/summary` — RAGAS 주간 요약

**Response** `200 OK`
```json
{
  "week": "2026-W14",
  "metrics": {
    "contextPrecision": { "median": 0.79, "p10": 0.52, "p90": 0.94 },
    "contextRecall": { "median": 0.75, "p10": 0.48, "p90": 0.91 },
    "faithfulness": { "median": 0.82, "p10": 0.58, "p90": 0.96 },
    "answerRelevancy": { "median": 0.88, "p10": 0.65, "p90": 0.97 },
    "deepevalHallucination": { "median": 0.12, "p10": 0.02, "p90": 0.38 }
  },
  "runNumbers": [1, 2, 3],
  "note": "3회 평가 중앙값 사용 (run 간 변동 대비)"
}
```

---

#### POST `/admin/ai/ab-tests` — A/B 테스트 생성

**Request**
```json
{
  "name": "튜터 레벨 프롬프트 v3.2 vs v3.3",
  "variantA": { "promptVersionId": 12, "description": "기존 레벨링 프롬프트" },
  "variantB": { "promptVersionId": 13, "description": "비유 강화 레벨링 프롬프트" },
  "target": "TUTOR",
  "startDate": "2026-04-05T00:00:00Z",
  "endDate": "2026-04-19T23:59:59Z"
}
```

**Response** `201 Created`
```json
{
  "testId": 8,
  "name": "튜터 레벨 프롬프트 v3.2 vs v3.3",
  "status": "DRAFT",
  "startDate": "2026-04-05T00:00:00Z",
  "endDate": "2026-04-19T23:59:59Z"
}
```

---

#### GET `/admin/ai/ab-tests/{id}/results` — A/B 테스트 결과

**Response** `200 OK`
```json
{
  "testId": 8,
  "name": "튜터 레벨 프롬프트 v3.2 vs v3.3",
  "status": "COMPLETED",
  "variantA": {
    "variant": "A",
    "sampleCount": 620,
    "thumbsUpRate": 0.82,
    "avgLatencyMs": 2180,
    "avgTokenUsed": 380,
    "avgMasteryDelta": 0.042
  },
  "variantB": {
    "variant": "B",
    "sampleCount": 630,
    "thumbsUpRate": 0.89,
    "avgLatencyMs": 2350,
    "avgTokenUsed": 415,
    "avgMasteryDelta": 0.061
  },
  "winner": "B",
  "significance": 0.97,
  "recommendation": "Variant B(비유 강화) 채택 권장 — 만족도 +7%, mastery 개선 +45%"
}
```

---

#### PUT `/admin/ai/prompts/{id}/rollback` — 프롬프트 롤백

**Request**
```json
{
  "reason": "v3.3 배포 후 faithfulness 점수 0.08 하락 감지"
}
```

**Response** `200 OK`
```json
{
  "promptId": 13,
  "rolledBackTo": 12,
  "isActive": false,
  "message": "프롬프트 v13이 비활성화되고 v12가 활성화되었습니다.",
  "rolledBackAt": "2026-04-02T16:00:00Z"
}
```

---

## 9.9 FinOps (Admin)

### 엔드포인트 목록

| Method | URL | 설명 | 권한 |
|--------|-----|------|------|
| GET | `/admin/finops/dashboard` | FinOps 종합 대시보드 | ADMIN |
| GET | `/admin/finops/unit-economics` | 서비스별 단가 분석 | ADMIN |
| PUT | `/admin/finops/kill-switch` | Kill-switch ON/OFF | ADMIN |
| PUT | `/admin/finops/thresholds` | Limit 임계값 조정 | ADMIN |

---

#### GET `/admin/finops/dashboard` — FinOps 대시보드

**Response** `200 OK`
```json
{
  "date": "2026-04-02",
  "dailySummary": {
    "totalCostUsd": 68.42,
    "softLimitUsd": 80.0,
    "hardLimitUsd": 150.0,
    "usagePercent": 45.6,
    "isKilled": false,
    "cacheHitRate": 0.52,
    "estimatedSavingsUsd": 31.5
  },
  "byService": [
    { "service": "TUTOR", "costUsd": 42.10, "requestCount": 8420, "avgCostPerRequest": 0.005 },
    { "service": "QUIZ_GEN", "costUsd": 14.80, "requestCount": 2960, "avgCostPerRequest": 0.005 },
    { "service": "GRADING", "costUsd": 8.22, "requestCount": 2740, "avgCostPerRequest": 0.003 },
    { "service": "SUMMARY", "costUsd": 3.30, "requestCount": 660, "avgCostPerRequest": 0.005 }
  ],
  "budgetRouting": {
    "currentBudgetRemaining": 54.3,
    "activeMode": "NORMAL",
    "tier4Active": true
  }
}
```

---

#### GET `/admin/finops/unit-economics` — 단가 분석

**Response** `200 OK`
```json
{
  "period": "2026-04",
  "unitEconomics": [
    {
      "service": "TUTOR",
      "costPerSession": 0.082,
      "target": 0.15,
      "status": "OK",
      "cacheContribution": "Semantic Cache로 $0.048 절감"
    },
    {
      "service": "QUIZ_GEN",
      "costPerGeneration": 0.043,
      "target": 0.05,
      "status": "OK"
    },
    {
      "service": "GRADING",
      "costPerGrading": 0.028,
      "target": 0.03,
      "status": "WARNING",
      "note": "rubric_coverage 계산 추가로 +12% 비용 증가"
    }
  ]
}
```

---

#### PUT `/admin/finops/kill-switch` — Kill-switch

**Request**
```json
{
  "action": "ACTIVATE",
  "reason": "일일 비용 $145 도달 — Hard Limit 근접"
}
```

**Response** `200 OK`
```json
{
  "isKilled": true,
  "activeMode": "HAIKU_ONLY",
  "batchStopped": true,
  "tier4Disabled": true,
  "message": "Kill-switch 활성화됨. Haiku 전용 모드로 전환. Admin 수동 해제 필요.",
  "activatedAt": "2026-04-02T22:30:00Z",
  "event": "CostThresholdReached"
}
```

> **이벤트**: `CostThresholdReached` → Kafka(`finops.threshold`) → Admin Notification

---

#### PUT `/admin/finops/thresholds` — Limit 조정

**Request**
```json
{
  "period": "DAILY",
  "softLimitUsd": 100.0,
  "hardLimitUsd": 200.0
}
```

**Response** `200 OK`
```json
{
  "period": "DAILY",
  "softLimitUsd": 100.0,
  "hardLimitUsd": 200.0,
  "updatedAt": "2026-04-02T09:00:00Z",
  "updatedBy": "admin@learnflow.ai"
}
```

---

## 부록 A. SSE 스트리밍 API 목록

| 엔드포인트 | 설명 | 이벤트 타입 |
|-----------|------|------------|
| `POST /ai/chat/sessions/{id}/messages` | AI 튜터 대화 | start, chunk, end, error |
| `POST /ai/summarize/lesson/{id}` | 레슨 요약 | start, chunk, end, error |

**SSE 공통 헤더**:
```
Content-Type: text/event-stream
Cache-Control: no-cache
Connection: keep-alive
X-Accel-Buffering: no
```

**에러 이벤트**:
```
data: {"type":"error","code":"AI_SERVICE_UNAVAILABLE","message":"AI 서비스가 일시적으로 사용 불가합니다. (Kill-switch 활성화)"}
```

---

## 부록 B. 이벤트 트리거 API 요약

| API | 이벤트 | destination_topic | Consumer |
|-----|--------|-------------------|----------|
| POST `/sections/{id}/lessons` | ContentCreated | `content.created` | Embedding Worker |
| PUT `/lessons/{id}` | ContentUpdated | `content.updated` | Embedding Worker |
| DELETE `/lessons/{id}` | ContentDeleted | `content.deleted` | Embedding Worker |
| PUT `/lessons/{id}/complete` | LessonCompleted | `lesson.completed` | Analytics Worker |
| POST `/quizzes/{id}/submit` | QuizSubmitted | `quiz.submitted` | AI Grading Worker |
| POST `/assignments/{id}/submit` | AssignmentSubmitted | `assignment.submitted` | AI Grading Worker |
| POST `/*/appeal` | GradingAppeal | `grading.appeal` | Notification Consumer |
| PUT `/admin/finops/kill-switch` | CostThresholdReached | `finops.threshold` | Admin Notification |
