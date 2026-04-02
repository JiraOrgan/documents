# 🎓 AI 기반 학습 관리 시스템 (AI-LMS) 프로젝트 계획서 [통합 완결본]

> **프로젝트명**: LearnFlow AI — AI 기반 적응형 학습 관리 시스템  
> **버전**: v4.0 통합 완결본  
> **작성일**: 2026-03-28  
> **기술 스택**: Spring Boot 4 + React 18 + Flutter 3.x + LLM API  
> **버전 이력**: v1.0(기반) → v2.0(AI 서비스 분리, RAG 고도화) → v3.0(Outbox, RAGAS, PII, FinOps) → v4.0(품질 현실화, Semantic Chunking, 컴플라이언스)

---

## 📋 전체 버전 변경 요약

| 영역 | v1.0 | v2.0 | v3.0 | v4.0 |
|------|------|------|------|------|
| 아키텍처 | AI 단일 서비스 | AI Gateway + 4 서브서비스 | + Outbox + Tracing | + OTel Sampling + destination_topic |
| 이벤트 | 동기 API | RabbitMQ 비동기 | + Transactional Outbox + Debezium | + DLQ + Consumer 멱등 전략 + dedup_key |
| RAG | Top-K 기본 | + Re-ranking + Query Rewrite + Hybrid + Compression | + Chunk Versioning + Tombstone | + Semantic Chunking + chunk_hash + Soft Delete 90일 |
| AI 메모리 | 최근 10턴 | Short-term + Long-term | (유지) | (유지) |
| AI 튜터 | 단일 level | 3단계 레벨링 + 프롬프트 분기 | (유지) | (유지) |
| LLM 라우팅 | 2분류 | 4분류 Rule+ML | + FinOps Kill-switch | + Unit Economics + 예산 동적 라우팅 |
| 캐싱 | Redis 캐시 | 3단계 캐시 | (유지) | + Semantic Cache 적극화 |
| 품질 관리 | 없음 | A/B 테스트 + 피드백 루프 | + RAGAS + LLM-as-Judge | + 3층 평가 + DeepEval + Importance Sampling |
| 보안 PII | 없음 | 없음 | + PII Masking/Demasking | + Output 스캔 + Presidio + Pseudonymization + 한국법 |
| 보안 Prompt | 필터링 | + System Prompt 격리 + Output Validation + 격리 | + Tool 제한 | (유지) |
| 온보딩 | 없음 | 없음 | + 진단 테스트 + 자가 진단 | + Bloom's 배분 + confidence weight |
| AI 채점 | AI + 강사 | (유지) | + Confidence + 이의 제기 + Manual Queue | + rubric_coverage |
| 모니터링 | Prometheus | (유지) | + Zipkin | + OTel + AI 전용 Grafana + Consumer Lag |
| Vector DB | pgvector | (유지) | (유지) | + Qdrant 전환 로드맵 + 멀티모달 준비 |

---

## 1. 프로젝트 개요

### 1.1 프로젝트 배경

기존 LMS는 모든 학습자에게 동일한 콘텐츠를 동일한 순서로 제공하는 일방향 구조이다.
학습자의 이해도, 취약점, 학습 속도에 대한 개인화가 부재하여 학습 효율이 떨어진다.
AI/LLM 기술을 접목하면 학습자 맞춤형 콘텐츠 추천, 자동 퀴즈 생성, 실시간 질의응답,
학습 분석 등을 통해 능동적이고 적응형인 학습 경험을 제공할 수 있다.

### 1.2 프로젝트 목표

```
┌─────────────────────────────────────────────────────────────────┐
│                     LearnFlow AI 핵심 목표                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ① 적응형 학습    : 학습자 수준에 맞는 콘텐츠 자동 조정          │
│  ② AI 튜터       : LLM 기반 실시간 질의응답 및 개념 설명         │
│  ③ 자동 평가     : AI 퀴즈/과제 자동 생성 및 채점                │
│  ④ 학습 분석     : 취약점 분석, 학습 패턴 시각화, 추천           │
│  ⑤ 협업 학습     : 스터디 그룹, 토론, 피어 리뷰                  │
│  ⑥ AI 품질 관리  : 3층 평가, A/B 테스트, 지속 개선               │
│  ⑦ 프로덕션 안정성: Outbox, 분산 추적, Chaos Testing            │
│  ⑧ 컴플라이언스  : PII 양방향 보호, 감사 추적, 신뢰 채점        │
│  ⑨ FinOps       : Unit Economics, 동적 라우팅, Semantic Cache   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 1.3 대상 사용자

| 역할 | 설명 | 주요 기능 |
|------|------|-----------|
| **학습자 (Learner)** | 강의를 수강하고 학습하는 사용자 | 수강, AI 튜터, 퀴즈, 학습 분석, 채점 이의 제기 |
| **강사 (Instructor)** | 강의를 생성하고 관리하는 사용자 | 강의 관리, 과제 출제, 수강생 분석, Manual Review Queue |
| **관리자 (Admin)** | 시스템 전체를 관리하는 운영자 | 사용자 관리, AI 품질, FinOps, 분산 추적, 감사 로그 |

---

## 2. 시스템 아키텍처

### 2.1 전체 아키텍처

```
┌──────────────────────────────────────────────────────────────────────────┐
│                           Client Layer                                   │
│                                                                          │
│   ┌──────────────┐    ┌──────────────┐    ┌──────────────────────┐       │
│   │  React 18    │    │ Flutter 3.x  │    │  Admin Dashboard     │       │
│   │  (Web SPA)   │    │ (Mobile App) │    │  (React)             │       │
│   └──────┬───────┘    └──────┬───────┘    └──────────┬───────────┘       │
└──────────┼───────────────────┼───────────────────────┼───────────────────┘
           └───────────────────┼───────────────────────┘
                               │
                        ┌──────▼──────┐
                        │  API Gateway │ ← Spring Cloud Gateway
                        │  + Trace ID  │ ← OTel Sampling 10~30%
                        └──────┬──────┘
                               │
        ┌──────────────────────┼────────────────────────┐
        │                      │                        │
 ┌──────▼──────┐       ┌──────▼──────┐          ┌──────▼──────┐
 │  학습 서비스  │       │  사용자 서비스│          │  AI Gateway  │
 │ (Course &   │       │ (Auth &     │          │ (Orchestrator)│
 │  Content)   │       │  Profile)   │          └──────┬──────┘
 └──────┬──────┘       └──────┬──────┘                 │
        │                     │          ┌─────────────┤
 ┌──────▼──────┐       ┌──────▼──────┐   │   ┌─────────▼────────┐
 │  MySQL      │       │  MySQL      │   │   │ PII Masking Layer │
 │  (학습 데이터)│       │  (사용자)    │   │   │ (Input + Output)  │
 │  + Outbox   │       └─────────────┘   │   └─────────┬────────┘
 └──────┬──────┘                         │             │
        │ CDC (Debezium)        ┌────────┼─────────────┼──────────┐
        ▼                      │   AI Service Layer    │          │
 ┌──────────────┐              │                      │          │
 │  Outbox      │              │  ┌──────────┐  ┌──────▼────┐    │
 │  Relay       │              │  │ LLM      │  │ RAG       │    │
 └──────┬───────┘              │  │ Service  │  │ Service   │    │
        │                      │  └──────────┘  └───────────┘    │
 ┌──────▼──────┐               │  ┌──────────┐  ┌───────────┐    │
 │  Kafka      │               │  │ Embedding│  │ Evaluation│    │
 └──────┬──────┘               │  │ Service  │  │ Service   │    │
        │                      │  └──────────┘  └───────────┘    │
   ┌────┼────┬────┬────┐       └─────────────────────────────────┘
   ▼    ▼    ▼    ▼    ▼
 ┌────┐┌────┐┌────┐┌────┐┌──────────┐
 │Read││Noti││Stat││ES  ││AI 분석   │
 │Mod ││fi  ││    ││Idx ││Consumer  │
 │Upd ││    ││    ││    ││          │
 └────┘└────┘└────┘└────┘└──────────┘

        ┌──────────────────────────────────────┐
        │  Observability                        │
        │  Zipkin + Prometheus + Grafana        │
        │  + Kafka Consumer Lag                 │
        │  + AI-Specific Dashboard              │
        └──────────────────────────────────────┘
```

### 2.2 AI 서비스 분리

```
┌─────────────────────────────────────────────────────────────────┐
│  AI Gateway (Orchestrator)                                       │
│  ├── 요청 라우팅 + 모델 선택 (4분류 + 예산 동적 라우팅)          │
│  ├── PII Masking 전처리/후처리 (Input + Output 양방향)           │
│  ├── Rate Limiting + 토큰 관리                                   │
│  ├── FinOps Kill-switch (Unit Economics 연동)                    │
│  ├── Circuit Breaker + Fallback (Resilience4j)                   │
│  └── Trace ID 전파 (OTel, Sampling 10~30%, 에러 100%)            │
│                                                                 │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐           │
│  │ LLM      │ │ Embedding│ │ RAG      │ │Evaluation│           │
│  │ Service  │ │ Service  │ │ Service  │ │ Service  │           │
│  │          │ │          │ │          │ │          │           │
│  │ • Chat   │ │ • 벡터생성│ │ • 검색   │ │ • 퀴즈생성│           │
│  │ • Tutor  │ │ • Semantic│ │ • Re-rank│ │ • 채점   │           │
│  │ • 요약   │ │   Chunk  │ │ • 압축   │ │ • Conf.  │           │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘           │
└─────────────────────────────────────────────────────────────────┘
```

### 2.3 Transactional Outbox Pattern

```
┌─────────────────────────────────────────────────────────────────┐
│  @Transactional (하나의 DB 트랜잭션)                             │
│  ├── ① 비즈니스 데이터 저장 (MySQL)                              │
│  └── ② outbox_events INSERT (같은 트랜잭션)                      │
│                                                                 │
│  Outbox Relay (Debezium CDC or Polling):                        │
│  outbox_events → Kafka (destination_topic별 라우팅)              │
│                                                                 │
│  Consumer 멱등성 (Holy Trinity):                                │
│  ├── dedup_key 체크 (aggregate_id + event_type + version)       │
│  ├── Version OCC (Read Model) / dedup_key (알림/AI)             │
│  └── DLQ: Relay 5회 실패 → DEAD_LETTER, Consumer 3회 → DLQ 토픽│
│                                                                 │
│  Polling vs CDC:                                                │
│  Phase 1: Polling + ShedLock (간단, Lock contention은 단일 인스턴스로 해소)│
│  Phase 2: Debezium CDC (Scale 시 binlog 기반 실시간 전환)        │
└─────────────────────────────────────────────────────────────────┘
```

### 2.4 이벤트 목록

| 이벤트 | Producer | Consumer | 처리 |
|--------|----------|----------|------|
| `ContentCreated` | 학습 서비스 (Outbox) | Embedding Worker | 청킹 + 임베딩 생성 |
| `ContentUpdated` | 학습 서비스 (Outbox) | Embedding Worker | chunk_hash 비교 → 변경분만 재임베딩 |
| `ContentDeleted` | 학습 서비스 (Outbox) | Embedding Worker | 해당 청크 INACTIVE 처리 |
| `QuizSubmitted` | 퀴즈 서비스 (Outbox) | AI Grading Worker | 자동 채점 + Confidence |
| `AssignmentSubmitted` | 과제 서비스 (Outbox) | AI Grading Worker | 과제 AI 채점 |
| `GradingAppeal` | 퀴즈/과제 서비스 | Notification | 강사 Manual Review Queue |
| `LessonCompleted` | 학습 서비스 (Outbox) | Analytics Worker | 진도/취약점 갱신 |
| `CostThresholdReached` | FinOps Monitor | Admin Notification | 비용 경고 + Kill-switch |

### 2.5 Distributed Tracing (OTel)

```
┌─────────────────────────────────────────────────────────────────┐
│  Sampling: dev 100% / staging 50% / prod 10~30%                │
│  예외: 5xx 에러 → 100%, AI API 호출 → 100%                     │
│                                                                 │
│  Span Attributes (Business Context):                            │
│  user.id, course.id, ai.model, ai.tokens.input/output,         │
│  ai.cost_usd, rag.chunks_retrieved, rag.rerank_score, cache.hit│
│                                                                 │
│  Trace 예시:                                                     │
│  API Gateway(2ms) → AI Gateway → PII Masking(5ms)              │
│  → RAG Service: Query Rewrite(120ms) + Hybrid Search(85ms)     │
│  + Re-ranking(200ms) + Compression(30ms)                        │
│  → LLM Service: Prompt(15ms) + LLM API(1800ms)                 │
│  → PII Demasking(3ms)                                           │
│  Total: ~2265ms                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 3. 기술 스택

### 3.1 Backend

| 영역 | 기술 | 버전 | 용도 |
|------|------|------|------|
| Framework | Spring Boot | 4.x | 메인 애플리케이션 |
| Language | Java | 21+ | Virtual Threads |
| ORM | Spring Data JPA + QueryDSL | 5.x | 데이터 접근 |
| Security | Spring Security | 7.x | JWT 인증/인가 |
| API 문서 | SpringDoc OpenAPI | 2.x | Swagger UI |
| Build | Gradle | 8.x | Kotlin DSL |
| DB | MySQL | 8.x | Source of Truth |
| Cache | Redis | 7.x | 세션, 캐시, Rate Limiting |
| 메시징 | Kafka | - | 이벤트 기반 비동기 |
| CDC | Debezium | 2.x | Outbox → Kafka 릴레이 |
| 검색 | Elasticsearch | 8.x | BM25 Hybrid Search |
| 스토리지 | MinIO / AWS S3 | - | 파일 저장 |
| Resilience | Resilience4j | - | Circuit Breaker |
| Tracing | Micrometer + Zipkin | - | 분산 추적 (OTel) |
| PII | Presidio + KoNLPy | - | 개인정보 마스킹 |
| DB 마이그레이션 | Flyway | - | 스키마 버전 관리 |

### 3.2 AI / LLM

| 영역 | 기술 | 용도 |
|------|------|------|
| LLM API | Claude API (Anthropic) | 메인 AI 엔진 |
| Fallback | OpenAI GPT API | 보조 LLM |
| Embedding | text-embedding-3-small | 콘텐츠 임베딩 |
| Vector DB | pgvector (Phase 1) → Qdrant (Phase 2) | RAG 벡터 저장 |
| Re-ranking | CrossEncoder (ms-marco) | 검색 결과 재정렬 |
| RAG 평가 | RAGAS + DeepEval | 자동 품질 평가 |
| Prompt 관리 | 자체 Template Engine | 프롬프트 버전 관리 |

### 3.3 Frontend

| 영역 | 기술 | 용도 |
|------|------|------|
| Web | React 18 + TypeScript | SPA 웹 클라이언트 |
| 상태 | Zustand + TanStack Query | 상태 + API 캐싱 |
| UI | shadcn/ui + Tailwind CSS | 컴포넌트 |
| 차트 | Recharts | 학습 분석 시각화 |
| 에디터 | TipTap | 마크다운/리치텍스트 |
| Mobile | Flutter 3.x + Riverpod | 크로스플랫폼 모바일 |

### 3.4 인프라

| 영역 | 기술 | 용도 |
|------|------|------|
| 컨테이너 | Docker + Docker Compose | 개발/배포 |
| CI/CD | GitHub Actions | 자동 빌드/배포 |
| 모니터링 | Prometheus + Grafana | 시스템 + AI + FinOps |
| 분산 추적 | Zipkin (OTel) | 서비스 간 추적 |
| CDC | Debezium | Outbox 릴레이 |

---

## 4. ERD 설계 (전체)

### 4.1 사용자 도메인

```
┌──────────────────────┐       ┌──────────────────────┐
│       users           │       │    user_profiles      │
├──────────────────────┤       ├──────────────────────┤
│ PK  id        BIGINT │───┐   │ PK  id        BIGINT │
│     email     VARCHAR│   │   │ FK  user_id   BIGINT │
│     password  VARCHAR│   │   │     nickname  VARCHAR│
│     role      ENUM   │   │   │     avatar    VARCHAR│
│     status    ENUM   │   │   │     bio       TEXT   │
│     created_at DATETIME│  │   │     level     INT    │
│     updated_at DATETIME│  │   │     exp_point INT    │
└──────────────────────┘   │   └──────────────────────┘
                           │
                           │   ┌──────────────────────┐
                           └──→│  user_learning_prefs  │
                               │     preferred_pace ENUM│
                               │     daily_goal_min INT │
                               │     interests   JSON  │
                               │     difficulty  ENUM  │
                               └──────────────────────┘
```

### 4.2 강의 도메인

```
┌──────────────────────┐       ┌──────────────────────┐
│      courses          │       │      sections         │
├──────────────────────┤       ├──────────────────────┤
│ PK  id        BIGINT │───┐   │ PK  id        BIGINT │
│ FK  instructor_id    │   │   │ FK  course_id BIGINT │
│     title     VARCHAR│   │   │     title     VARCHAR│
│     description TEXT  │   │   │     order_num INT    │
│     category  VARCHAR│   │   └──────────┬───────────┘
│     level     ENUM   │   │              │
│     thumbnail VARCHAR│   │   ┌──────────▼───────────┐
│     price     DECIMAL│   │   │      lessons          │
│     status    ENUM   │   │   │ PK  id        BIGINT │
│     avg_rating DECIMAL│  │   │ FK  section_id BIGINT│
│     created_at DATETIME│ │   │     title     VARCHAR│
└──────────────────────┘   │   │     type      ENUM   │
                           │   │     content   TEXT   │
                           │   │     video_url VARCHAR│
                           │   │     duration_min INT │
                           │   │     order_num INT    │
                           │   └──────────────────────┘
                           │
                           │   ┌──────────────────────┐
                           └──→│    enrollments        │
                               │ FK  user_id   BIGINT │
                               │ FK  course_id BIGINT │
                               │     status    ENUM   │
                               │     progress  DECIMAL│
                               │     enrolled_at DATETIME│
                               │     completed_at DATETIME│
                               └──────────────────────┘
```

### 4.3 AI 채팅 도메인

```
┌──────────────────────┐       ┌──────────────────────────┐
│    ai_chat_sessions   │       │    ai_chat_messages       │
├──────────────────────┤       ├──────────────────────────┤
│ PK  id        BIGINT │───┐   │ PK  id          BIGINT   │
│ FK  user_id   BIGINT │   │   │ FK  session_id  BIGINT   │
│ FK  course_id BIGINT │   │   │     role        ENUM     │
│     title     VARCHAR│   └──▶│     content     TEXT     │
│     context   JSON   │       │     token_used  INT      │
│     created_at DATETIME│     │     feedback    ENUM     │ (GOOD/BAD/null)
└──────────────────────┘       │     model_used  VARCHAR  │
                               │     created_at  DATETIME │
                               └──────────────────────────┘
```

### 4.4 퀴즈/과제 도메인

```
┌──────────────────────┐       ┌──────────────────────┐
│       quizzes         │       │    quiz_questions     │
├──────────────────────┤       ├──────────────────────┤
│ PK  id        BIGINT │──┐    │ PK  id        BIGINT │
│ FK  lesson_id BIGINT │  │    │ FK  quiz_id   BIGINT │
│     title     VARCHAR│  │    │     question   TEXT   │
│     difficulty ENUM  │  └──▶ │     type       ENUM  │
│     ai_generated BOOL│       │     options    JSON   │
│     prompt_ver VARCHAR│      │     answer     TEXT   │
│     created_at DATETIME│     │     explanation TEXT  │
└──────────────────────┘       │     bloom_level ENUM  │
                               └──────────────────────┘

┌──────────────────────────────────┐
│   quiz_attempts                   │
├──────────────────────────────────┤
│ FK  user_id, quiz_id             │
│     score          DECIMAL       │
│     answers        JSON          │
│     ai_feedback    TEXT          │
│     started_at, submitted_at     │
└──────────────────────────────────┘

┌──────────────────────────────────┐
│   assignment_submissions          │
├──────────────────────────────────┤
│ FK  assignment_id, user_id       │
│     content        TEXT          │
│     ai_score       DECIMAL       │
│     ai_confidence  DECIMAL       │  ← Confidence Score
│     ai_feedback    TEXT          │
│     instructor_score DECIMAL     │
│     instructor_feedback TEXT     │
│     status         ENUM         │  SUBMITTED → AI_GRADED
│                                  │  → CONFIRMED / APPEALED / MANUAL_REVIEW
│     appeal_reason  TEXT          │
│     appeal_at      DATETIME     │
│     reviewed_at    DATETIME     │
└──────────────────────────────────┘
```

### 4.5 학습 분석 도메인

```
┌──────────────────────┐       ┌──────────────────────────┐
│  learning_activities  │       │  concept_mastery          │
├──────────────────────┤       ├──────────────────────────┤
│ FK  user_id, lesson_id│       │ FK  user_id, course_id   │
│     activity_type ENUM│       │     concept      VARCHAR │
│     duration_sec INT │       │     mastery_score DECIMAL│
│     completed  BOOL  │       │     confidence   DECIMAL │ ← v4.0
│     created_at DATETIME│     │     source       ENUM    │ (DIAGNOSTIC/QUIZ/MANUAL)
└──────────────────────┘       │     attempt_count INT    │
                               │     last_updated  DATETIME│
┌──────────────────────┐       └──────────────────────────┘
│  weakness_analyses    │
├──────────────────────┤
│ FK  user_id, course_id│
│     topic     VARCHAR│
│     mastery_level DECIMAL│
│     suggestion TEXT  │
│     analyzed_at DATETIME│
└──────────────────────┘
```

### 4.6 임베딩 도메인

```
┌─────────────────────────────────────┐
│  content_embeddings                  │
├─────────────────────────────────────┤
│ PK  id            BIGINT           │
│ FK  course_id     BIGINT           │
│ FK  lesson_id     BIGINT           │
│     chunk_index   INT              │
│     chunk_text    TEXT             │
│     embedding     VECTOR(1536)     │  ← pgvector
│     token_count   INT              │
│     chunk_hash    VARCHAR          │  ← SHA-256 (v4.0: 중복 스킵)
│     metadata      JSONB            │  {section, page, timestamp, type}
│     chunking_strategy VARCHAR      │  (RECURSIVE, SEMANTIC, HYBRID)
│     version       INT              │
│     status        ENUM             │  ACTIVE / INACTIVE
│     last_modified_at DATETIME      │
│     created_at    DATETIME         │
│     updated_at    DATETIME         │
└─────────────────────────────────────┘
INDEX: HNSW on embedding WHERE status = 'ACTIVE'
INDEX: (course_id, lesson_id, status)
INDEX: (chunk_hash)
```

### 4.7 이벤트/운영 도메인

```
┌────────────────────────────────────┐
│  outbox_events                      │
├────────────────────────────────────┤
│ PK  id              BIGINT        │
│     aggregate_type  VARCHAR       │
│     aggregate_id    BIGINT        │
│     event_type      VARCHAR       │
│     dedup_key       VARCHAR UNIQUE│  ← aggregate_id+event_type+version
│     destination_topic VARCHAR     │  ← v4.0: 토픽별 라우팅
│     payload         JSON          │
│     status          ENUM          │  PENDING → PUBLISHED → CONSUMED
│     retry_count     INT           │
│     max_retries     INT DEFAULT 5 │
│     error_message   TEXT          │
│     created_at, published_at, consumed_at │
└────────────────────────────────────┘

┌──────────────────────────────────┐
│  audit_logs                       │
├──────────────────────────────────┤
│ FK  user_id                      │
│     action, entity_type, entity_id│
│     before_value JSON, after_value JSON│
│     ip_address, user_agent       │
│     created_at                   │
└──────────────────────────────────┘
```

### 4.8 AI 품질 관리 도메인

```
┌──────────────────────────┐       ┌──────────────────────────┐
│  ai_feedback_logs         │       │  prompt_versions          │
├──────────────────────────┤       ├──────────────────────────┤
│ FK  user_id, message_id  │       │     name, version         │
│     feedback ENUM (GOOD/BAD)│    │     template TEXT         │
│     comment  TEXT         │       │     is_active BOOL       │
│     created_at            │       │     created_at           │
└──────────────────────────┘       └──────────────────────────┘

┌──────────────────────────┐       ┌──────────────────────────┐
│  ab_tests                 │       │  ab_test_results          │
├──────────────────────────┤       ├──────────────────────────┤
│     name, variant_a/b JSON│      │ FK  test_id, user_id     │
│     target ENUM, status   │       │     variant ENUM (A/B)   │
│     start_date, end_date  │       │     feedback, latency_ms │
│                           │       │     token_used, mastery_delta│ ← v4.0
└──────────────────────────┘       └──────────────────────────┘

┌──────────────────────────┐
│  ragas_evaluations        │
├──────────────────────────┤
│ FK  message_id           │
│     context_precision    DECIMAL│
│     context_recall       DECIMAL│
│     faithfulness         DECIMAL│
│     answer_relevancy     DECIMAL│
│     deepeval_hallucination DECIMAL│ ← v4.0
│     overall_score        DECIMAL│
│     run_number           INT    │  ← v4.0: 3회 평가 중 몇 번째
│     evaluated_at         │
└──────────────────────────┘
```

### 4.9 FinOps 도메인

```
┌──────────────────────────────────┐
│  ai_cost_logs                     │
├──────────────────────────────────┤
│ FK  user_id                      │
│     service (TUTOR, QUIZ_GEN, GRADING, SUMMARY)│
│     model   VARCHAR              │
│     input_tokens, output_tokens INT│
│     cost_usd DECIMAL             │
│     cache_hit BOOL               │  ← v4.0: Semantic Cache 여부
│     created_at                   │
└──────────────────────────────────┘

┌──────────────────────────────────┐
│  cost_thresholds                  │
├──────────────────────────────────┤
│     period (DAILY/MONTHLY)       │
│     soft_limit_usd, hard_limit_usd│
│     current_usage_usd            │
│     is_killed BOOL               │
└──────────────────────────────────┘
```

### 4.10 온보딩 도메인

```
┌──────────────────────────────────┐       ┌──────────────────────────────┐
│  diagnostic_tests                 │       │  diagnostic_results           │
├──────────────────────────────────┤       ├──────────────────────────────┤
│ FK  course_id                    │───┐   │ FK  test_id, user_id         │
│     title, questions JSON        │   │   │     answers JSON              │
│     level_ranges JSON            │   └──▶│     diagnosed_level ENUM     │
│     bloom_distribution JSON      │ ←v4.0 │     concept_scores JSON      │
│     created_at                   │       │     confidence_weight DECIMAL│ ←v4.0
└──────────────────────────────────┘       │     taken_at                 │
                                           └──────────────────────────────┘
```

---

## 5. AI/LLM 기능 상세 설계

### 5.1 RAG 파이프라인

```
┌─────────────────────────────────────────────────────────────────┐
│                   RAG 파이프라인 (최종)                           │
│                                                                 │
│  ═══ 인덱싱 (비동기, Outbox → Embedding Worker) ═══             │
│                                                                 │
│  콘텐츠 등록 → Semantic Chunking 하이브리드                      │
│  ├── Recursive Splitter (200~400토큰, 20% overlap)              │
│  ├── Semantic Boundary Detection (유사도 기반 병합/분리)         │
│  └── chunk_hash(SHA-256) → 동일 내용 재임베딩 스킵              │
│  → 임베딩 변환 → pgvector 저장 (status=ACTIVE)                  │
│                                                                 │
│  ═══ 검색 (실시간) ═══                                           │
│                                                                 │
│  Step 1: Query Rewrite                                          │
│  └── "이거 왜 안됨?" → "JPA Lazy Loading 동작 원리"             │
│                                                                 │
│  Step 2: Hybrid Search (병렬)                                   │
│  ├── Vector Search (pgvector) Top 20                            │
│  ├── BM25 (Elasticsearch) Top 20                                │
│  └── RRF 융합 정렬 → Top 20                                     │
│                                                                 │
│  Step 3: Re-ranking                                             │
│  └── CrossEncoder (ms-marco) → Top 5                            │
│                                                                 │
│  Step 4: Context Compression                                    │
│  └── 질문 관련 핵심 문장만 추출 (토큰 40~60% 절감)              │
│                                                                 │
│  Step 5: LLM 응답 생성 (SSE 스트리밍)                            │
│  └── System Prompt + 압축 컨텍스트 + 메모리 + 사용자 질문        │
│                                                                 │
│  course_id 기반 격리: 수강 강의 내에서만 검색                    │
└─────────────────────────────────────────────────────────────────┘
```

### 5.2 AI 튜터 메모리 구조

```
┌─────────────────────────────────────────────────────────────────┐
│  Short-term Memory (세션 내)                                     │
│  ├── 현재 대화 히스토리 (최근 10턴)                              │
│  ├── 현재 학습 중인 레슨 컨텍스트                                │
│  └── 저장: Redis (TTL: 세션 종료 후 24시간)                      │
│                                                                 │
│  Long-term Memory (학습자 프로필)                                │
│  ├── concept_mastery (개념별 숙련도 + confidence)                │
│  ├── 자주 틀리는 패턴 (오답 이력)                                │
│  ├── 선호 학습 스타일 (피드백 데이터 기반)                       │
│  └── 저장: MySQL (concept_mastery, weakness_analyses)            │
│                                                                 │
│  프롬프트 구성 순서:                                             │
│  System Prompt (역할 + 레벨링)                                   │
│  → Long-term Memory → RAG 컨텍스트 → Short-term → User Message  │
└─────────────────────────────────────────────────────────────────┘
```

### 5.3 AI 튜터 3단계 레벨링

```
┌─────────────────────────────────────────────────────────────────┐
│  Level 결정: concept_mastery 평균 기반 자동 분류                  │
│                                                                 │
│  Level 1 (초보, mastery < 0.4):                                  │
│  → "비유와 그림으로 설명. 전문 용어 사용 시 쉬운 설명 추가."     │
│                                                                 │
│  Level 2 (중급, 0.4 ≤ mastery < 0.7):                            │
│  → "개념 + 코드 예시. 원리 설명 + 실무 실수 언급."              │
│                                                                 │
│  Level 3 (고급, mastery ≥ 0.7):                                  │
│  → "내부 구현, 소스 코드 레벨, 트레이드오프 비교 분석."          │
└─────────────────────────────────────────────────────────────────┘
```

### 5.4 AI 품질 관리 — 3층 평가 체계

```
┌─────────────────────────────────────────────────────────────────┐
│  Layer 1: 실시간 사용자 피드백 (1차 신호)                         │
│  ├── 👍👎 피드백, "다시 설명" 요청 빈도                          │
│  ├── 응답 후 퀴즈 정답률 (간접 품질 지표)                        │
│  └── 세션 이탈률                                                │
│                                                                 │
│  Layer 2: 자동 평가 배치 (2차 객관화)                             │
│  ├── RAGAS (보조): Faithfulness, Context Precision/Recall        │
│  │   → 3회 평가 중앙값 사용 (run 간 변동 대비)                   │
│  ├── DeepEval 병행: G-Eval, Hallucination Score                 │
│  ├── End-to-End Retrieval Accuracy (Ground Truth 기반)           │
│  ├── Importance Sampling: 저성능 토픽 가중 샘플링                │
│  └── 비용 절감: 평가용 LLM은 소형 모델 사용                     │
│                                                                 │
│  Layer 3: 인간 전문가 평가 (3차 최종 검증)                       │
│  ├── Faithfulness < 0.7 응답 → 자동 리포트 → 주간 리뷰          │
│  ├── 월간 50개 무작위 → 인간 평가자 5점 척도                    │
│  └── 인간 vs 자동 상관관계 추적 → 기준 보정                     │
│                                                                 │
│  개선 루프: 주간 리뷰 → 프롬프트/청킹 개선 → A/B 테스트 검증    │
│  A/B 측정: RAGAS + DeepEval + 학습 성과 (mastery 변화량)        │
└─────────────────────────────────────────────────────────────────┘
```

### 5.5 AI 채점 Human-in-the-Loop

```
┌─────────────────────────────────────────────────────────────────┐
│  채점 흐름:                                                      │
│  제출 → AI Grading Worker → Confidence Score 계산               │
│                                                                 │
│  Confidence = weighted_avg(                                     │
│    rubric_match_clarity  * 0.3,                                  │
│    answer_determinism    * 0.25,                                 │
│    score_consistency     * 0.25,   (2회 채점 일관성)             │
│    rubric_coverage       * 0.2     (v4.0: 루브릭 항목 커버율)   │
│  )                                                              │
│                                                                 │
│  Confidence ≥ 0.8 → 자동 확정 (CONFIRMED)                       │
│  Confidence < 0.8 → Manual Review Queue 자동 이관               │
│                                                                 │
│  학습자: 채점 후 7일 이내 이의 제기(Appeal) 가능                 │
│  → GradingAppeal 이벤트 → 강사 Manual Review Queue              │
│  → 강사 최종 점수 확정                                           │
└─────────────────────────────────────────────────────────────────┘
```

### 5.6 온보딩 — Cold Start 해결

```
┌─────────────────────────────────────────────────────────────────┐
│  Option A: 진단 테스트 (3~5분, 5문항)                            │
│  ├── Bloom's 배분: 기억(Q1) + 이해(Q2) + 적용(Q3)              │
│  │                + 분석(Q4) + 평가(Q5)                        │
│  ├── 결과 → concept별 초기 mastery 산출                         │
│  └── confidence = 0.7 (테스트 기반 → 비교적 신뢰)               │
│                                                                 │
│  Option B: 자가 진단 (30초)                                      │
│  ├── 입문(0.1) / 초급(0.3) / 중급(0.5) / 고급(0.7)             │
│  └── confidence = 0.3 (자가 → 빠르게 퀴즈로 보정 필요)          │
│                                                                 │
│  confidence 낮은 concept → 더 빠르게 퀴즈 제안                  │
│  → 퀴즈 결과로 mastery + confidence 동시 갱신                   │
└─────────────────────────────────────────────────────────────────┘
```

### 5.7 LLM 라우팅 + 토큰 관리

```
┌─────────────────────────────────────────────────────────────────┐
│  4분류 모델 라우팅:                                              │
│  Tier 1 (Haiku):  짧은 Q&A, OX, 용어 정의         ~$0.001/요청  │
│  Tier 2 (Sonnet): 코드 설명, 디버깅, 리팩토링      ~$0.005/요청  │
│  Tier 3 (Sonnet): 개념 설명, 비교 분석, 원리       ~$0.010/요청  │
│  Tier 4 (Opus):   복잡한 설계, 아키텍처 질문       ~$0.050/요청  │
│                                                                 │
│  예산 기반 동적 라우팅 (v4.0):                                   │
│  잔여 > 70%: 정상 (4분류) | 50~70%: Opus 비활성                 │
│  30~50%: Haiku 우선 | < 30%: Haiku 전용 + 배치 중단             │
│                                                                 │
│  3단계 캐싱:                                                     │
│  Layer 1: Embedding Cache (hash → embedding)                    │
│  Layer 2: RAG Result Cache (query embedding → results)          │
│  Layer 3: Semantic Response Cache (similarity > 0.95 → 재사용)  │
│  → Semantic Cache 히트 시 LLM API 호출 0 → 비용 40~60% 절감    │
│                                                                 │
│  요금제: Free 5K토큰/일 | Basic 50K/일 | Premium 200K/일        │
└─────────────────────────────────────────────────────────────────┘
```

---

## 6. PII Masking Pipeline

```
┌─────────────────────────────────────────────────────────────────┐
│  ── 입력 마스킹 (전처리) ──                                     │
│  Step 1: Regex (한국 특화 — 이메일, 전화, 주민번호, 카드번호,    │
│          계좌번호(은행별), 여권, 운전면허, 사업자등록번호)        │
│  Step 2: NER (Presidio + KoNLPy — 인명, 주소, 기관명)           │
│  Step 3: 토큰 치환 ("김철수" → <NAME_1> 또는 "학습자A")         │
│          매핑: Redis session-scoped, 세션 종료 시 자동 삭제      │
│                                                                 │
│  Anonymization 옵션: 완전 마스킹(기본) / Pseudonymization(가명화)│
│                                                                 │
│  ── 출력 스캔 (후처리, v4.0) ──                                 │
│  Step 1: Demasking (<NAME_1> → 원본 복원)                       │
│  Step 2: Output PII 스캔 (LLM이 새로 생성한 PII 감지)           │
│          → 탐지 시 마스킹 + 감사 로그 "OUTPUT_PII_DETECTED"     │
│                                                                 │
│  ── 컴플라이언스 ──                                             │
│  한국 PIPA: 처리 목적 명시, 위탁 고지, PII 전송 유형 기록       │
│  EU AI Act: 교육 AI → 투명성, AI 생성 결과 명시, 감사 추적      │
└─────────────────────────────────────────────────────────────────┘
```

---

## 7. FinOps Kill-switch

```
┌─────────────────────────────────────────────────────────────────┐
│  Unit Economics (v4.0):                                         │
│  cost_per_tutor_session < $0.15                                 │
│  cost_per_quiz_generation < $0.05                               │
│  cost_per_grading < $0.03                                       │
│  cost_per_mastery_improvement (학습 성과당 비용)                 │
│                                                                 │
│  Soft Limit ($80/일) → Slack/이메일 알림                        │
│  Hard Limit ($150/일) → Opus 비활성 + Haiku 강제 + 배치 중단    │
│  is_killed = true → Admin 수동 해제                             │
│                                                                 │
│  이상 패턴 자동 제한:                                            │
│  5분 내 50회 호출 → rate limit 강화                              │
│  동일 질문 반복 10회 → 캐시 강제 적용                            │
│  비정상 시간대 대량 호출 → 알림 + 임시 차단                     │
└─────────────────────────────────────────────────────────────────┘
```

---

## 8. 보안 설계 (7 Layer + PII + FinOps)

```
Layer 1: 입력 필터링 — 길이 제한 + 위험 패턴 감지
Layer 2: PII Masking — Input + Output 양방향 스캔
Layer 3: System Prompt 격리 — 절대 노출 금지
Layer 4: Output Validation — 점수 범위/JSON 스키마 검증
Layer 5: 데이터 격리 — course_id 기반 RAG 범위 제한
Layer 6: Tool 사용 제한 — DB 직접 조회/외부 URL/파일 차단
Layer 7: FinOps Kill-switch — Soft/Hard 한도 + 자동 다운그레이드
```

---

## 9. 핵심 API 설계

### 9.1 사용자 / 인증

| Method | Endpoint | 설명 | 권한 |
|--------|----------|------|------|
| POST | `/api/v1/auth/signup` | 회원가입 | PUBLIC |
| POST | `/api/v1/auth/login` | 로그인 (JWT) | PUBLIC |
| POST | `/api/v1/auth/refresh` | 토큰 갱신 | AUTHENTICATED |
| GET | `/api/v1/users/me` | 내 프로필 | AUTHENTICATED |
| PUT | `/api/v1/users/me` | 프로필 수정 | AUTHENTICATED |
| PUT | `/api/v1/users/me/learning-prefs` | 학습 선호 | LEARNER |

### 9.2 강의

| Method | Endpoint | 설명 | 권한 |
|--------|----------|------|------|
| GET | `/api/v1/courses` | 강의 목록 | PUBLIC |
| GET | `/api/v1/courses/{id}` | 강의 상세 | PUBLIC |
| POST | `/api/v1/courses` | 강의 생성 | INSTRUCTOR |
| PUT | `/api/v1/courses/{id}` | 강의 수정 | INSTRUCTOR |
| POST | `/api/v1/courses/{id}/sections` | 섹션 추가 | INSTRUCTOR |
| POST | `/api/v1/sections/{id}/lessons` | 레슨 추가 → Event | INSTRUCTOR |
| POST | `/api/v1/courses/{id}/enroll` | 수강 신청 | LEARNER |
| GET | `/api/v1/courses/{id}/progress` | 진도율 | LEARNER |
| PUT | `/api/v1/lessons/{id}/complete` | 레슨 완료 → Event | LEARNER |

### 9.3 AI 튜터

| Method | Endpoint | 설명 | 권한 |
|--------|----------|------|------|
| POST | `/api/v1/ai/chat/sessions` | 채팅 세션 생성 | LEARNER |
| POST | `/api/v1/ai/chat/sessions/{id}/messages` | 메시지 (SSE 스트리밍) | LEARNER |
| GET | `/api/v1/ai/chat/sessions` | 세션 목록 | LEARNER |
| GET | `/api/v1/ai/chat/sessions/{id}/messages` | 대화 히스토리 | LEARNER |
| POST | `/api/v1/ai/chat/messages/{id}/feedback` | 피드백 (👍👎) | LEARNER |
| GET | `/api/v1/ai/chat/sessions/{id}/suggestions` | 추천 질문 | LEARNER |

### 9.4 퀴즈 / 과제

| Method | Endpoint | 설명 | 권한 |
|--------|----------|------|------|
| POST | `/api/v1/ai/quizzes/generate` | AI 퀴즈 생성 | INSTRUCTOR |
| GET | `/api/v1/lessons/{id}/quizzes` | 레슨별 퀴즈 | LEARNER |
| POST | `/api/v1/quizzes/{id}/submit` | 퀴즈 제출 → Event | LEARNER |
| GET | `/api/v1/quizzes/{id}/results` | 결과 + AI 피드백 | LEARNER |
| POST | `/api/v1/assignments/{id}/submit` | 과제 제출 → Event | LEARNER |
| POST | `/api/v1/quizzes/attempts/{id}/appeal` | 채점 이의 제기 | LEARNER |
| POST | `/api/v1/assignments/submissions/{id}/appeal` | 과제 이의 제기 | LEARNER |
| GET | `/api/v1/instructor/review-queue` | 수동 검토 대기 | INSTRUCTOR |
| PUT | `/api/v1/instructor/review-queue/{id}/resolve` | 검토 완료 | INSTRUCTOR |

### 9.5 학습 분석

| Method | Endpoint | 설명 | 권한 |
|--------|----------|------|------|
| GET | `/api/v1/analytics/me/dashboard` | 학습 대시보드 | LEARNER |
| GET | `/api/v1/analytics/me/weaknesses` | 취약점 분석 | LEARNER |
| GET | `/api/v1/analytics/me/concept-mastery` | 개념별 숙련도 | LEARNER |
| GET | `/api/v1/analytics/me/recommendations` | AI 추천 | LEARNER |
| GET | `/api/v1/analytics/me/study-time` | 학습 시간 | LEARNER |
| GET | `/api/v1/analytics/courses/{id}/overview` | 강의 분석 | INSTRUCTOR |

### 9.6 온보딩

| Method | Endpoint | 설명 | 권한 |
|--------|----------|------|------|
| GET | `/api/v1/onboarding/diagnostic/{courseId}` | 진단 문제 | LEARNER |
| POST | `/api/v1/onboarding/diagnostic/{courseId}/submit` | 진단 결과 제출 | LEARNER |
| POST | `/api/v1/onboarding/self-assess` | 자가 진단 | LEARNER |

### 9.7 콘텐츠 요약

| Method | Endpoint | 설명 | 권한 |
|--------|----------|------|------|
| POST | `/api/v1/ai/summarize/lesson/{id}` | 레슨 요약 | LEARNER |
| POST | `/api/v1/ai/flashcards/generate/{lessonId}` | 플래시카드 생성 | LEARNER |

### 9.8 AI 품질 관리 (Admin)

| Method | Endpoint | 설명 | 권한 |
|--------|----------|------|------|
| GET | `/api/v1/admin/ai/quality/dashboard` | AI 품질 대시보드 | ADMIN |
| GET | `/api/v1/admin/ai/quality/ragas/summary` | RAGAS 주간 요약 | ADMIN |
| GET | `/api/v1/admin/ai/quality/ragas/trends` | 지표 트렌드 | ADMIN |
| POST | `/api/v1/admin/ai/ab-tests` | A/B 테스트 생성 | ADMIN |
| GET | `/api/v1/admin/ai/ab-tests/{id}/results` | A/B 결과 | ADMIN |
| GET | `/api/v1/admin/ai/prompts` | 프롬프트 버전 | ADMIN |
| POST | `/api/v1/admin/ai/prompts` | 새 버전 등록 | ADMIN |
| PUT | `/api/v1/admin/ai/prompts/{id}/rollback` | 롤백 | ADMIN |

### 9.9 FinOps (Admin)

| Method | Endpoint | 설명 | 권한 |
|--------|----------|------|------|
| GET | `/api/v1/admin/finops/dashboard` | FinOps 대시보드 | ADMIN |
| GET | `/api/v1/admin/finops/unit-economics` | 서비스별 단가 | ADMIN |
| PUT | `/api/v1/admin/finops/kill-switch` | Kill-switch ON/OFF | ADMIN |
| PUT | `/api/v1/admin/finops/thresholds` | Limit 조정 | ADMIN |

---

## 10. 화면 구성

### 10.1 학습자 — 강의 수강 화면

```
┌──────────────────────────────────┬───────────────────────┐
│  [영상 플레이어]                  │  [AI 튜터 채팅]        │
│  ┌──────────────────────────┐   │  ┌─────────────────┐  │
│  │     ▶  강의 영상          │   │  │ 🤖 무엇이든      │  │
│  │                          │   │  │    물어보세요!   │  │
│  └──────────────────────────┘   │  │                 │  │
│  ┌──────────────────────────┐   │  │ ─ 추천 질문 ─   │  │
│  │  📝 강의 노트             │   │  │ [N+1 문제란?]   │  │
│  │  [AI 요약] [플래시카드]   │   │  │ [Fetch 전략?]   │  │
│  └──────────────────────────┘   │  │                 │  │
│                                 │  │ 👤 JPA에서      │  │
│  ── AI 사이드 패널 ──           │  │  N+1 문제란?    │  │
│  ┌──────────────────────────┐   │  │                 │  │
│  │ 📊 이번 레슨 AI 요약      │   │  │ 🤖 (스트리밍)   │  │
│  │ • 핵심 개념 3가지         │   │  │                 │  │
│  │ [전체 요약] [마인드맵]    │   │  │ 👍 👎           │  │
│  └──────────────────────────┘   │  │ [이해도 체크]    │  │
│                                 │  │ [더 쉽게] [더 깊이]│ │
│  커리큘럼:                       │  └─────────────────┘  │
│  ✅ 1. 소개  ✅ 2. 기본         │  ┌─────────────────┐  │
│  ▶️ 3. 심화  🔒 4. 실습        │  │ 메시지 입력...   │  │
│  [집중 모드 ON]                  │  └─────────────────┘  │
└──────────────────────────────────┴───────────────────────┘
```

### 10.2 학습자 — 학습 분석 대시보드

```
┌──────────────────────────────────────────────────────────┐
│  [주간 학습 시간]     [개념별 숙련도]     [취약점 맵]      │
│  ┌──────────┐       ┌──────────────┐   ┌──────────┐     │
│  │ █ █ █     │       │  JPA ██░░ 0.35│   │ ⚠ JPA    │     │
│  │ 월화수목금│       │  SQL ███░ 0.68│   │ ⚠ 트랜잭션│     │
│  └──────────┘       │  HTTP████ 0.92│   │ ✅ HTTP   │     │
│                     └──────────────┘   └──────────┘     │
│                                                          │
│  🤖 AI 추천: "JPA 연관관계 숙련도 0.35로 낮습니다.       │
│      Section 2 복습 + 보충 퀴즈를 추천합니다."            │
│      [보충 퀴즈 시작] [관련 레슨 바로가기]                │
└──────────────────────────────────────────────────────────┘
```

### 10.3 관리자 — AI 운영 대시보드

```
┌──────────────────────────────────────────────────────────┐
│  ── FinOps ──                                            │
│  Today: $42.30 / $80(Soft) / $150(Hard)  Kill: 🟢 OFF   │
│  Unit: Tutor $0.12/session | Grading $0.02/건            │
│  Semantic Cache Hit: 45%  → 절감 $18.90                  │
│                                                          │
│  ── AI 품질 (3층 평가) ──                                │
│  Faithfulness:  0.88 (RAGAS) | 0.91 (DeepEval)           │
│  Retrieval Accuracy: 82% (Ground Truth)                  │
│  👍 비율: 78.3% | 👎 비율: 21.7%                        │
│  ⚠ Faithfulness < 0.7 응답 12건 [상세 보기]              │
│                                                          │
│  ── Observability ──                                     │
│  P50: 1.2s | P95: 3.8s | Consumer Lag: 12 ✅             │
│  Outbox Pending: 0 | DLQ: 0                              │
│  PII Input: 23건 | PII Output: 2건 ⚠                    │
└──────────────────────────────────────────────────────────┘
```

---

## 11. 프로젝트 구조

```
learnflow-api/src/main/java/com/learnflow/
├── global/
│   ├── config/ (Security, JPA, Redis, Kafka, Debezium, Zipkin, Resilience, Swagger)
│   ├── security/ (JWT, Filter, UserDetails)
│   ├── common/ (ApiResponse, PageResponse, BaseTimeEntity)
│   ├── exception/ (GlobalHandler, ErrorCode, BusinessException)
│   ├── event/
│   │   ├── outbox/ (OutboxEvent, OutboxRepository, OutboxPublisher, OutboxCleaner)
│   │   └── events/ (ContentCreated, QuizSubmitted, GradingAppeal, CostThreshold...)
│   ├── audit/ (AuditLog, AuditAspect)
│   └── tracing/ (TraceContextPropagator)
│
├── domain/
│   ├── user/        (entity, repo, service, controller, dto)
│   ├── course/      (entity, repo, service, controller, dto)
│   ├── quiz/        (entity, repo, service, controller, dto)
│   ├── assignment/  (entity, repo, service, controller, dto)
│   └── community/   (entity, repo, service, controller, dto)
│
├── ai/
│   ├── gateway/ (AiGatewayController, AiRequestRouter, ModelRouter, PiiMaskingService,
│   │             PiiDemaskingService, PiiOutputScanner, FinOpsGuard, AiRateLimiter)
│   ├── tutor/
│   │   ├── service/ (AiTutorService, ChatSessionService, ShortTermMemory,
│   │   │             LongTermMemory, SuggestedQuestion, LevelingService)
│   │   └── controller/ (AiTutorController — SSE)
│   ├── rag/
│   │   ├── service/ (RagOrchestrator, QueryRewrite, HybridSearch, Reranking,
│   │   │             ContextCompression, Embedding, VectorSearch, SemanticChunking,
│   │   │             ChunkVersioning)
│   │   └── repository/ (EmbeddingRepository)
│   ├── evaluation/
│   │   ├── service/ (AiQuizGenerator, AiGrading, ConfidenceScorer, AppealService,
│   │   │             ManualReviewQueue, OutputValidator)
│   │   └── dto/
│   ├── quality/
│   │   ├── service/ (FeedbackService, AbTestService, PromptVersionService,
│   │   │             RagasEvaluation, DeepEvalService, LlmJudge)
│   │   └── entity/ (AiFeedbackLog, AbTest, PromptVersion, RagasEvaluation)
│   ├── finops/
│   │   ├── service/ (CostTracking, KillSwitch, UnitEconomics, AnomalyDetection)
│   │   └── entity/ (AiCostLog, CostThreshold)
│   ├── client/ (LlmClient, ClaudeApiClient, OpenAiApiClient, CrossEncoderClient)
│   ├── prompt/ (TemplateEngine, Registry, templates/level1~3, quiz, grading...)
│   └── cache/ (EmbeddingCache, RagResultCache, SemanticResponseCache)
│
├── worker/ (EmbeddingWorker, AiGradingWorker, AnalyticsWorker, NotificationWorker)
├── onboarding/ (DiagnosticTestService, SelfAssessment, controller, entity)
├── analytics/ (LearningAnalytics, ConceptMastery, WeaknessDetection)
│
└── src/main/resources/
    ├── application.yml / application-dev.yml / application-prod.yml
    └── db/migration/ (V1~V12)
```

---

## 12. 개발 일정 (24주)

```
Phase 1: 기반 구축 (Week 1-4)
├── Week 1  : DB 설계 (Outbox 포함) + 엔티티 + 인증 (JWT)
├── Week 2  : 강의 CRUD + 수강 신청 + 파일 업로드
├── Week 3  : 콘텐츠 관리 (에디터 + 영상)
└── Week 4  : React 레이아웃 + 라우팅 + 강의 목록/상세

Phase 2: 핵심 학습 (Week 5-8)
├── Week 5  : 학습 진도 추적 + 레슨 완료
├── Week 6  : 퀴즈/과제 시스템 + 채점 이의 제기 UI
├── Week 7  : 온보딩 진단 (Bloom's 배분 + confidence weight)
└── Week 8  : 커뮤니티 (토론, Q&A)

Phase 3: 이벤트 인프라 + AI 기반 (Week 9-12)
├── Week 9  : Outbox + Debezium/Polling + Kafka + Consumer 멱등성 + DLQ
├── Week 10 : AI Gateway + PII Pipeline v4.0 (Input+Output + Presidio)
├── Week 11 : Distributed Tracing (OTel Sampling + Business Context)
└── Week 12 : FinOps (Unit Economics + 동적 라우팅 + Semantic Cache)

Phase 4: RAG + AI 튜터 (Week 13-16)
├── Week 13 : Semantic Chunking + chunk_hash + pgvector + Hybrid Search
├── Week 14 : Re-ranking + Query Rewrite + Compression + Chunk Versioning
├── Week 15 : AI 튜터 (SSE + 레벨링 + 이중 메모리)
└── Week 16 : AI 퀴즈 + AI 채점 (rubric_coverage + Confidence + HITL)

Phase 5: 분석 + 품질 관리 (Week 17-19)
├── Week 17 : 학습 분석 + concept_mastery + AI 추천 + Cold Start 연동
├── Week 18 : 3층 평가 (RAGAS 보조 + DeepEval + Importance Sampling)
└── Week 19 : A/B 테스트 (학습 성과 연동) + 프롬프트 관리

Phase 6: 고도화 및 완성 (Week 20-24)
├── Week 20 : Flutter 모바일 앱 (핵심 화면 + AI 튜터)
├── Week 21 : 알림 시스템 + 관리자 대시보드
├── Week 22 : AI 전용 Grafana (hallucination, RAG latency, PII, FinOps)
├── Week 23 : 보안 강화 + Chaos Testing (Kafka 다운, PII 대량, 비용 폭주)
└── Week 24 : 통합 테스트 + Docker 배포 + 문서화
```

### 마일스톤

| 마일스톤 | 시점 | 완료 기준 |
|----------|------|-----------|
| **M1: MVP 기반** | Week 4 | 회원, 강의 CRUD, 수강 |
| **M2: 학습 기능** | Week 8 | 퀴즈, 과제, 온보딩, 커뮤니티 |
| **M3: 인프라** | Week 12 | Outbox, AI Gateway, PII, OTel, FinOps |
| **M4: AI 통합** | Week 16 | RAG v4.0, AI 튜터, AI 채점+HITL |
| **M5: 품질 관리** | Week 19 | 3층 평가, DeepEval, A/B 테스트 |
| **M6: 릴리즈** | Week 24 | 모바일, Chaos Test, 배포, 문서 |

---

## 13. Docker Compose

```yaml
version: '3.8'
services:
  api:
    build: ./learnflow-api
    ports: ["8080:8080"]
    depends_on: [mysql, redis, kafka, elasticsearch]
    environment:
      SPRING_PROFILES_ACTIVE: dev
      CLAUDE_API_KEY: ${CLAUDE_API_KEY}

  web:
    build: ./learnflow-web
    ports: ["3000:3000"]

  mysql:
    image: mysql:8.0
    ports: ["3306:3306"]
    volumes: [mysql-data:/var/lib/mysql]
    environment:
      MYSQL_ROOT_PASSWORD: ${DB_ROOT_PASSWORD}
      MYSQL_DATABASE: learnflow

  redis:
    image: redis:7-alpine
    ports: ["6379:6379"]
    volumes: [redis-data:/data]

  zookeeper:
    image: confluentinc/cp-zookeeper:7.5.0
    environment:
      ZOOKEEPER_CLIENT_PORT: 2181

  kafka:
    image: confluentinc/cp-kafka:7.5.0
    ports: ["9092:9092"]
    depends_on: [zookeeper]

  debezium:
    image: debezium/connect:2.5
    ports: ["8083:8083"]
    depends_on: [mysql, kafka]

  pgvector:
    image: pgvector/pgvector:pg16
    ports: ["5433:5432"]
    volumes: [pgvector-data:/var/lib/postgresql/data]

  elasticsearch:
    image: elasticsearch:8.12.0
    ports: ["9200:9200"]
    environment:
      discovery.type: single-node
      xpack.security.enabled: "false"
    volumes: [es-data:/usr/share/elasticsearch/data]

  minio:
    image: minio/minio
    ports: ["9000:9000", "9001:9001"]
    command: server /data --console-address ":9001"
    volumes: [minio-data:/data]

  zipkin:
    image: openzipkin/zipkin
    ports: ["9411:9411"]

  prometheus:
    image: prom/prometheus
    ports: ["9090:9090"]

  grafana:
    image: grafana/grafana
    ports: ["3001:3000"]

volumes:
  mysql-data:
  redis-data:
  pgvector-data:
  es-data:
  minio-data:
```

---

## 14. Grafana AI 전용 대시보드

```
── AI Quality Panel ──
hallucination_rate, confidence_avg, cache_hit_rate,
reexplain_rate, post_tutor_quiz_accuracy

── RAG Performance Panel ──
rag_latency_breakdown (query_rewrite / search / rerank / compress / llm),
context_precision_weekly, retrieval_accuracy_weekly

── FinOps Panel ──
daily_cost, cost_per_session, cost_per_grading, budget_remaining_pct,
model_distribution, semantic_cache_savings

── PII Panel ──
pii_detected_input, pii_detected_output, pii_types, masking_failure

── Outbox + Consumer Panel ──
outbox_pending, relay_latency, dlq_count, consumer_lag, error_rate
```

---

## 15. 기술적 차별화 포인트

```
🧪 AI 품질 관리 (프로덕션 수준)
├── 3층 평가: 사용자 피드백 + 자동(RAGAS+DeepEval) + 인간
├── Importance Sampling + Ground Truth + 학습 성과 A/B 테스트
└── AI-Specific Grafana (RAG latency breakdown, hallucination rate)

🧠 RAG 고도화
├── Semantic Chunking 하이브리드 (의미 경계 보존)
├── chunk_hash 중복 스킵 + Soft Delete 90일
├── Hybrid Search + Re-ranking + Context Compression
└── Vector DB 전환 로드맵 (pgvector → Qdrant) + 멀티모달 준비

🔒 컴플라이언스
├── PII: Input + Output 양방향 + Presidio/KoNLPy + Pseudonymization
├── 한국 PIPA + EU AI Act 대응
├── AI 채점 투명성 (rubric_coverage + Confidence + Appeal)
└── 감사 로그 (AOP 기반 before/after)

💰 FinOps
├── Unit Economics (세션당·채점당·학습성과당 비용)
├── 예산 기반 동적 모델 라우팅 + Semantic Cache 40~60% 절감
└── 이상 패턴 자동 rate limit

🏗️ 아키텍처
├── AI Gateway + 4 서브서비스 (장애 격리, 독립 스케일링)
├── Transactional Outbox + Debezium (Holy Trinity)
├── Consumer 멱등성 (dedup_key + Version OCC + DLQ)
├── OTel Distributed Tracing (Sampling + Business Context)
└── Short-term + Long-term Memory + 3단계 레벨링

🧑‍🎓 학습 엔진
├── 온보딩 Bloom's 배분 + confidence weight
├── concept_mastery 기반 적응형 추천
├── Human-in-the-Loop (rubric_coverage 포함 Confidence)
└── Cold Start 해결 (진단 테스트 + 자가 진단)
```

---

## 16. 리스크 및 대응

| 리스크 | 영향도 | 대응 방안 |
|--------|--------|-----------|
| LLM API 장애 | 높음 | Circuit Breaker + Fallback 자동 전환 |
| Kafka 브로커 장애 | 높음 | Transactional Outbox → 이벤트 DB 안전 저장 + DLQ |
| 할루시네이션 | 높음 | 3층 평가 (RAGAS+DeepEval+인간) + Importance Sampling |
| RAGAS 점수 불안정 | 중간 | 3회 평가 중앙값 + DeepEval 병행 + 인간 보정 |
| API 비용 폭증 | 높음 | FinOps Kill-switch + Unit Economics + 동적 라우팅 + Semantic Cache |
| Prompt Injection | 높음 | 7 Layer 다층 방어 |
| PII 유출 (Output) | 높음 | Output PII 스캔 + 감사 로그 |
| Tombstone vector DB 부하 | 중간 | Soft Delete + chunk_hash 스킵 + 90일 보관 |
| 콜드 스타트 | 중간 | 온보딩 진단 (Bloom's + confidence weight) |
| AI 채점 분쟁 | 중간 | Confidence (rubric_coverage 포함) + Appeal + Manual Queue |
| pgvector 대규모 한계 | 낮음 | Qdrant 전환 로드맵 + VectorStore 추상화 |
| Tracing 오버헤드 | 낮음 | Sampling 10~30% + 에러 100% |
| 24주 일정 지연 | 중간 | Phase 6 버퍼 + Phase별 독립 배포 |

---

> **문서 끝**  
> v4.0 통합 완결본 — v1.0(기반) + v2.0(AI 서비스 분리, RAG) + v3.0(Outbox, RAGAS, PII, FinOps)  
> + v4.0(3층 평가, Semantic Chunking, Output PII, Unit Economics, OTel) 전체 내용 포함.  
> 이 문서 하나로 프로젝트 전체 설계를 파악할 수 있습니다.
