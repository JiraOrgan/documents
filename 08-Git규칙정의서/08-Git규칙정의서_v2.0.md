---
문서명: Jira 프로젝트 관리 시스템 Git 규칙 정의서
버전: v2.0
작성일: 2026-03-21
최종수정일: 2026-03-21
작성자: 팀
상태: 검토중
---

# Jira 프로젝트 관리 시스템 Git 규칙 정의서

## 목차

1. [브랜치 전략](#1-브랜치-전략)
2. [커밋 컨벤션](#2-커밋-컨벤션)
3. [PR (Pull Request) 규칙](#3-pr-pull-request-규칙)
4. [Jira Smart Commit 연동](#4-jira-smart-commit-연동)
5. [브랜치 보호 규칙](#5-브랜치-보호-규칙)
6. [Git Hook 설정](#6-git-hook-설정)
7. [태그 전략](#7-태그-전략)
8. [충돌 해결 가이드](#8-충돌-해결-가이드)
9. [브랜치 생명주기 관리](#9-브랜치-생명주기-관리)
10. [Git LFS](#10-git-lfs)
11. [비밀값 보호](#11-비밀값-보호)
12. [.gitignore 기본 설정](#12-gitignore-기본-설정)
13. [변경 이력](#13-변경-이력)

---

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

---

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

### 2.3 Scope 값 — 프로젝트 모듈 매핑

커밋 메시지의 `scope`는 아래 프로젝트 모듈 식별자를 사용합니다.

| Scope | 대상 모듈 |
|-------|-----------|
| issue | 이슈 생성·수정·삭제 |
| board | 스크럼/칸반 보드 |
| workflow | 상태 전환·워크플로우 규칙 |
| jql | JQL 파서·검색 필터 |
| auth | 인증·권한 관리 |
| sprint | 스프린트 생성·운영 |
| dashboard | 대시보드·가젯 |
| audit | Audit Log·히스토리 |

### 2.4 Footer — Jira 이슈 참조

커밋 footer에 Jira 이슈 키를 반드시 포함합니다.

```
# 이슈 참조 (완료되지 않은 경우)
Refs: PROJ-123

# 이슈 종료 (Done 상태로 자동 전환)
Closes: PROJ-456

# 복수 이슈 참조
Refs: PROJ-123, PROJ-124
Closes: PROJ-456
```

### 2.5 Breaking Change

하위 호환이 깨지는 변경은 두 가지 방법 중 하나로 명시합니다.

```
# 방법 1: ! 접미사 (subject 앞)
feat(auth)!: OAuth2 토큰 구조 변경

# 방법 2: BREAKING CHANGE footer
feat(workflow): 전환 규칙 API 재설계

BREAKING CHANGE: /api/v1/transitions 엔드포인트 제거.
/api/v2/workflow/transitions 로 마이그레이션 필요.
Refs: PROJ-789
```

### 2.6 커밋 메시지 전체 예시

```
feat(issue): 이슈 일괄 상태 전환 API 구현

칸반 보드에서 여러 이슈를 동시에 상태 전환할 수 있도록
bulk transition 엔드포인트를 추가합니다.

Refs: PROJ-201
```

---

## 3. PR (Pull Request) 규칙

### 3.1 PR 템플릿

```markdown
## 변경 사항
-

## 변경 사유
- Jira Issue: [PROJ-{번호}](https://your-domain.atlassian.net/browse/PROJ-{번호})

## 테스트 결과
- [ ] 단위 테스트 통과
- [ ] 기능 테스트 완료

## 스크린샷 (UI 변경 시)

## 관련 이슈
- Closes PROJ-{번호}
```

> PR 본문에 `PROJ-{번호}` 형식으로 이슈 키를 포함하면 Jira에서 자동으로 PR과 이슈가 연결됩니다.

### 3.2 PR 규칙

- [ ] 최소 1명 이상의 리뷰어 승인 필요 (Code Review → QA 전환 조건)
- [ ] CI 빌드 통과 필수
- [ ] 충돌 해결 후 병합
- [ ] Squash Merge 사용 (feature → develop)
- [ ] PR 크기 400줄 이하 권장

### 3.3 PR 라벨 체계

| 라벨 | 기준 | 설명 |
|------|------|------|
| size/S | 변경 50줄 미만 | 소규모 변경 |
| size/M | 변경 50~200줄 | 중간 규모 |
| size/L | 변경 200줄 초과 | 대규모, 분리 검토 권장 |
| hotfix | hotfix 브랜치 PR | 긴급 수정 |
| breaking-change | Breaking Change 포함 | MAJOR 버전 검토 필요 |

### 3.4 Draft PR 활용 가이드

WIP(Work In Progress) 상태의 작업을 팀과 공유할 때 Draft PR을 활용합니다.

```
활용 시점
  - 구현 방향에 대한 조기 피드백이 필요할 때
  - 공유 브랜치에서 병렬 작업 중일 때
  - 완성 전 CI 결과를 미리 확인할 때

Draft → Ready for Review 전환 조건
  - [ ] 구현 완료
  - [ ] 자체 리뷰(self-review) 완료
  - [ ] 커밋 메시지 정리 (Squash/Rebase)
  - [ ] 테스트 통과
```

### 3.5 Squash Merge와 이슈 추적성 보존

Squash Merge 시 커밋 이력이 단일 커밋으로 압축되므로, 아래 규칙으로 추적성을 보존합니다.

```
Squash 커밋 메시지 형식:
feat(board): 칸반 WIP 제한 UI 구현 (#42)

- WIP 초과 시 컬럼 헤더 색상 경고 추가
- 툴팁으로 현재/최대 WIP 수치 표시
- WIP 설정 화면 연동

Closes: PROJ-24
```

- PR 번호(`#42`)와 Jira 이슈 키(`Closes: PROJ-24`)를 Squash 커밋에 반드시 포함합니다.
- GitHub/GitLab의 PR 화면에서 전체 커밋 이력을 별도로 확인할 수 있습니다.

---

## 4. Jira Smart Commit 연동

Bitbucket, GitHub, GitLab과 Jira를 연동하면 커밋 메시지에 특수 키워드를 삽입하는 것만으로 이슈 상태 전환, 댓글 추가, 시간 기록을 자동화할 수 있습니다.

### 4.1 Jira 이슈 키 포함 필수 규칙

모든 커밋 메시지에는 관련 Jira 이슈 키가 반드시 포함되어야 합니다.

```
형식: {프로젝트키}-{번호}
예시: PROJ-123, BOARD-45, AUTH-7
```

이슈 키가 누락된 커밋은 `commit-msg` hook에 의해 거부됩니다. ([섹션 6.1](#61-commit-msg) 참조)

### 4.2 Smart Commit 문법

```
{이슈키} #{명령어} {값}
```

| 명령어 | 효과 | 예시 |
|--------|------|------|
| `#comment` | 이슈에 댓글 추가 | `PROJ-123 #comment 로그인 API 구현 완료` |
| `#time` | 작업 시간 기록 | `PROJ-123 #time 2h 30m` |
| `#resolve` | 이슈를 Done으로 전환 | `PROJ-123 #resolve` |
| `#review` | 이슈를 Code Review로 전환 | `PROJ-123 #review` |

### 4.3 Smart Commit 조합 예시

```bash
# 댓글 + 시간 기록 + 상태 전환 한 번에
git commit -m "feat(auth): JWT 토큰 갱신 로직 구현

PROJ-123 #comment 토큰 만료 30분 전 자동 갱신 처리 완료 #time 3h #resolve"

# 코드 리뷰 요청 상태 전환
git commit -m "fix(board): WIP 초과 시 경고 메시지 누락 수정

PROJ-145 #comment PR 생성, 리뷰 요청합니다 #time 1h #review"
```

### 4.4 자동 상태 전환 매핑

| Smart Commit 명령어 | Jira 이슈 전환 상태 |
|--------------------|-------------------|
| `#resolve` | → Done |
| `#review` | → Code Review |
| `#close` | → Done (Closed) |

> Smart Commit 기능은 Jira의 Development Tools(GitHub/Bitbucket 연동) 설정이 완료된 환경에서 동작합니다.

### 4.5 이슈 키 누락 시 커밋 거부 정책

`commit-msg` Git Hook을 통해 이슈 키 포함 여부를 자동 검증합니다. 이슈 키가 없는 커밋은 로컬에서 즉시 거부되며, 아래 안내 메시지가 출력됩니다.

```
[commit-msg hook] 오류: Jira 이슈 키가 누락되었습니다.
커밋 메시지에 이슈 키(예: PROJ-123)를 포함하세요.

올바른 예: feat(auth): 로그인 구현 / Refs: PROJ-123
```

Hook 설정 방법은 [섹션 6.1](#61-commit-msg)을 참조합니다.

---

## 5. 브랜치 보호 규칙

GitHub/GitLab Branch Protection Rules 또는 Bitbucket Branch Permissions를 통해 아래 정책을 적용합니다.

### 5.1 보호 정책 표

| 브랜치 | 직접 푸시 | Required Reviews | Status Checks | 비고 |
|--------|-----------|-----------------|---------------|------|
| main | 금지 | 2명 | CI 빌드 + E2E | 운영 |
| develop | 금지 | 1명 | CI 빌드 + 단위 테스트 | 개발 통합 |
| release/* | 금지 | 1명 | CI 빌드 | 배포 준비 |
| feature/* | 허용 | - | - | 기능 개발 |

### 5.2 GitHub Branch Protection 설정 예시 (main)

```
Branch name pattern: main

[v] Require a pull request before merging
    Required approving reviews: 2
    [v] Dismiss stale pull request approvals when new commits are pushed
    [v] Require review from Code Owners

[v] Require status checks to pass before merging
    Required checks:
      - ci/build
      - ci/e2e

[v] Require branches to be up to date before merging

[v] Do not allow bypassing the above settings
```

---

## 6. Git Hook 설정

Git Hook과 Husky를 조합하여 커밋 품질을 자동으로 보장합니다.

### 6.1 commit-msg

커밋 메시지의 Conventional Commits 형식 준수와 Jira 이슈 키 포함 여부를 검증합니다.

**commitlint.config.js**

```js
module.exports = {
  extends: ['@commitlint/config-conventional'],
  rules: {
    // Type 목록 제한
    'type-enum': [
      2,
      'always',
      ['feat', 'fix', 'docs', 'style', 'refactor', 'test', 'chore'],
    ],
    // Scope는 프로젝트 모듈 식별자로 제한
    'scope-enum': [
      2,
      'always',
      ['issue', 'board', 'workflow', 'jql', 'auth', 'sprint', 'dashboard', 'audit'],
    ],
    'scope-empty': [1, 'never'],
    'subject-case': [2, 'never', ['upper-case']],
    'subject-max-length': [2, 'always', 72],
    'body-max-line-length': [2, 'always', 100],
  },
  // Jira 이슈 키 포함 여부 커스텀 플러그인
  plugins: [
    {
      rules: {
        'jira-issue-key': ({ raw }) => {
          const hasIssueKey = /[A-Z]+-\d+/.test(raw);
          return [
            hasIssueKey,
            '커밋 메시지에 Jira 이슈 키(예: PROJ-123)가 포함되어야 합니다.',
          ];
        },
      },
    },
  ],
};
```

### 6.2 pre-commit

커밋 전 변경된 파일에 대해 ESLint와 Prettier를 실행합니다.

**.lintstagedrc**

```json
{
  "*.{ts,tsx,js,jsx}": [
    "eslint --fix --max-warnings=0",
    "prettier --write"
  ],
  "*.{css,scss,json,md}": [
    "prettier --write"
  ]
}
```

### 6.3 pre-push

푸시 전 단위 테스트를 실행하여 빌드 불안정성을 사전에 차단합니다.

**.husky/pre-push**

```bash
#!/bin/sh
. "$(dirname "$0")/_/husky.sh"

echo "Running unit tests before push..."
npm run test:unit

if [ $? -ne 0 ]; then
  echo "[pre-push] 단위 테스트가 실패했습니다. 푸시가 중단됩니다."
  exit 1
fi
```

### 6.4 Husky 설정 방법

```bash
# 1. 의존성 설치
npm install --save-dev husky @commitlint/cli @commitlint/config-conventional lint-staged

# 2. Husky 초기화
npx husky init

# 3. commit-msg hook 설정
echo 'npx --no -- commitlint --edit "$1"' > .husky/commit-msg
chmod +x .husky/commit-msg

# 4. pre-commit hook 설정
echo 'npx lint-staged' > .husky/pre-commit
chmod +x .husky/pre-commit

# 5. pre-push hook 설정 (내용은 6.3 참조)
chmod +x .husky/pre-push

# 6. package.json에 prepare 스크립트 추가 (팀원 자동 설치)
# "prepare": "husky"
```

**package.json 설정 예시**

```json
{
  "scripts": {
    "prepare": "husky",
    "test:unit": "jest --testPathPattern=unit"
  },
  "devDependencies": {
    "husky": "^9.0.0",
    "@commitlint/cli": "^19.0.0",
    "@commitlint/config-conventional": "^19.0.0",
    "lint-staged": "^15.0.0"
  }
}
```

---

## 7. 태그 전략

### 7.1 Semantic Versioning

태그는 `MAJOR.MINOR.PATCH` 형식을 따릅니다.

```
MAJOR : 하위 호환 불가 변경 (Breaking Change, 대규모 API 재설계)
MINOR : 하위 호환 신규 기능 추가
PATCH : 버그 수정, 마이너 개선

예시
  v1.0.0  → 최초 릴리즈
  v1.1.0  → 신규 기능(sprint 대시보드) 추가
  v1.1.1  → 긴급 버그 수정
  v2.0.0  → Breaking Change(API v2 전환)
```

### 7.2 태그와 Jira Fix Version 1:1 매핑

릴리즈 아티팩트의 일관성을 위해 Git 태그, Jira Fix Version, Docker 이미지 태그를 동일한 버전 식별자로 통일합니다.

| 구성 요소 | 식별자 예시 |
|-----------|------------|
| Git Tag | `v1.0.0` |
| Jira Fix Version | `v1.0.0` |
| Docker Image | `registry/app:v1.0.0` |

### 7.3 태그 생성 시점 및 절차

```
1. release/{버전} 브랜치에서 최종 QA 통과
2. release/{버전} → main Merge
3. main 브랜치에서 태그 생성
4. Jira Fix Version 상태를 Released로 전환
5. Docker 이미지 빌드 및 레지스트리 푸시 (태그 동일)
```

```bash
# 태그 생성 (GPG 서명 권장)
git checkout main
git pull origin main
git tag -s v1.0.0 -m "Release v1.0.0"

# 서명 없이 생성하는 경우 (최소)
git tag -a v1.0.0 -m "Release v1.0.0"

# 원격 저장소에 태그 푸시
git push origin v1.0.0
```

### 7.4 Pre-release 태그

정식 릴리즈 전 검증 단계에서 Pre-release 태그를 활용합니다.

| 단계 | 태그 형식 | 예시 | 설명 |
|------|-----------|------|------|
| 베타 | `vX.Y.Z-beta.N` | `v1.0.0-beta.1` | 내부 기능 검증 |
| RC | `vX.Y.Z-rc.N` | `v1.0.0-rc.1` | 최종 출시 후보 |

```bash
# RC 태그 생성 예시
git tag -s v1.0.0-rc.1 -m "Release Candidate 1 for v1.0.0"
git push origin v1.0.0-rc.1
```

### 7.5 태그 GPG 서명 권장

태그 위변조 방지를 위해 GPG 서명을 권장합니다.

```bash
# GPG 키 생성 (최초 1회)
gpg --full-generate-key

# Git에 GPG 키 등록
git config --global user.signingkey {GPG_KEY_ID}
git config --global tag.gpgSign true

# 서명 검증
git tag -v v1.0.0
```

---

## 8. 충돌 해결 가이드

### 8.1 Merge Conflict 해결 절차

```
1. 최신 대상 브랜치 동기화
   git fetch origin
   git checkout feature/PROJ-123-my-feature
   git merge origin/develop   (또는 git rebase origin/develop)

2. 충돌 파일 확인
   git status

3. IDE에서 충돌 마커 해결
   <<<<<<< HEAD (내 변경)
   ...
   =======
   ...
   >>>>>>> origin/develop (대상 브랜치 변경)

4. 해결 후 스테이징
   git add {해결된 파일}

5. 머지/리베이스 계속
   git merge --continue   또는   git rebase --continue

6. 충돌 해결 커밋 메시지
   chore: develop 브랜치 충돌 해결 / Refs: PROJ-123
```

### 8.2 Rebase vs Merge 선택 기준

| 상황 | 권장 방법 | 이유 |
|------|-----------|------|
| feature → develop PR 전 최신화 | `rebase` | 히스토리를 선형으로 유지, 리뷰 용이 |
| develop → release 병합 | `merge` | 병합 시점 명시, 롤백 용이 |
| release → main 병합 | `merge --no-ff` | 릴리즈 시점을 히스토리에 보존 |
| hotfix → main/develop | `merge --no-ff` | 긴급 수정 이력 명시적 보존 |

```bash
# feature 브랜치를 develop 기준으로 rebase (PR 전 권장)
git fetch origin
git rebase origin/develop

# 충돌 발생 시 각 커밋마다 해결 후 계속
git rebase --continue

# rebase 중단하고 원래 상태로 복구
git rebase --abort
```

### 8.3 충돌이 잦은 파일 처리

| 파일 유형 | 처리 방법 |
|-----------|-----------|
| `package-lock.json`, `yarn.lock` | 양쪽 삭제 후 `npm install` 재생성 |
| `pnpm-lock.yaml` | 양쪽 삭제 후 `pnpm install` 재생성 |
| 자동 생성 파일 (`*.generated.ts`) | 빌드 후 자동 생성 파일은 `.gitignore`에 추가 검토 |
| 마이그레이션 파일 | 타임스탬프 기반 순서 확인 후 수동 병합 |

> lock 파일 충돌은 "내 것"과 "상대방 것" 중 하나를 선택하지 않고 반드시 재생성합니다.

---

## 9. 브랜치 생명주기 관리

### 9.1 생명주기 정책

| 브랜치 유형 | 생성 시점 | 삭제 시점 | 권장 수명 |
|------------|-----------|-----------|-----------|
| feature/* | Jira 이슈 In Progress 전환 | PR 머지 후 즉시 | 1 Sprint (2주) 이내 |
| bugfix/* | Jira Bug 이슈 In Progress 전환 | PR 머지 후 즉시 | 1 Sprint (2주) 이내 |
| hotfix/* | 긴급 결함 발생 | main/develop 머지 후 즉시 | 1~3일 |
| release/* | Sprint 완료 후 QA 시작 | main 머지 후 즉시 | 1~2주 |

### 9.2 Stale 브랜치 정리 정책

```
30일 미활동 브랜치
  → 브랜치 담당자에게 슬랙 경고 알림 발송
  → 7일 내 활동 없으면 삭제 예정 안내

60일 미활동 브랜치
  → 자동 삭제 또는 관리자 수동 삭제
  → 삭제 전 팀 채널 공지 (3일 전)
```

**GitHub Actions stale 브랜치 정리 예시**

```yaml
# .github/workflows/stale-branch-cleanup.yml
name: Stale Branch Cleanup
on:
  schedule:
    - cron: '0 9 * * 1'  # 매주 월요일 오전 9시
jobs:
  cleanup:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - name: Find stale branches
        run: |
          git for-each-ref --format='%(refname:short) %(committerdate:relative)' refs/remotes/origin \
            | grep -v 'main\|develop\|release' \
            | awk '$2 ~ /months|years/ {print $1}'
```

### 9.3 브랜치 즉시 삭제 자동화

PR 머지 후 소스 브랜치를 자동으로 삭제하도록 저장소 설정을 적용합니다.

```
GitHub 설정:
  Settings > General > Pull Requests
  [v] Automatically delete head branches

GitLab 설정:
  Settings > General > Merge requests
  [v] Delete source branch after merge (기본값으로 체크)
```

---

## 10. Git LFS

바이너리 및 대용량 파일은 Git LFS(Large File Storage)를 통해 관리하여 저장소 크기를 최적화합니다.

### 10.1 LFS 추적 대상 기준

| 기준 | 설명 |
|------|------|
| 크기 기준 | 단일 파일 **10MB 이상** |
| 파일 유형 | 이미지, 바이너리, 대용량 데이터, 영상 |
| 예외 | 소스 코드, 텍스트 파일 (크기 무관) |

### 10.2 .gitattributes 설정 예시

```gitattributes
# 이미지
*.png  filter=lfs diff=lfs merge=lfs -text
*.jpg  filter=lfs diff=lfs merge=lfs -text
*.jpeg filter=lfs diff=lfs merge=lfs -text
*.gif  filter=lfs diff=lfs merge=lfs -text
*.webp filter=lfs diff=lfs merge=lfs -text
*.svg  filter=lfs diff=lfs merge=lfs -text
*.ico  filter=lfs diff=lfs merge=lfs -text

# 영상 및 오디오
*.mp4  filter=lfs diff=lfs merge=lfs -text
*.mov  filter=lfs diff=lfs merge=lfs -text
*.mp3  filter=lfs diff=lfs merge=lfs -text

# 바이너리 및 아카이브
*.pdf  filter=lfs diff=lfs merge=lfs -text
*.zip  filter=lfs diff=lfs merge=lfs -text
*.tar.gz filter=lfs diff=lfs merge=lfs -text
*.jar  filter=lfs diff=lfs merge=lfs -text

# 대용량 데이터
*.csv  filter=lfs diff=lfs merge=lfs -text
*.parquet filter=lfs diff=lfs merge=lfs -text
```

### 10.3 Git LFS 초기 설정

```bash
# LFS 설치 (최초 1회, 머신별)
git lfs install

# 특정 패턴 추적 시작
git lfs track "*.png"
git lfs track "*.pdf"

# .gitattributes 커밋
git add .gitattributes
git commit -m "chore: Git LFS 추적 설정 추가"

# LFS 추적 중인 파일 목록 확인
git lfs ls-files
```

---

## 11. 비밀값 보호

소스 코드 저장소에 인증 정보, API 키, 비밀번호가 포함되지 않도록 아래 정책을 준수합니다.

### 11.1 .gitignore 필수 항목

아래 파일 및 디렉터리는 반드시 `.gitignore`에 포함해야 합니다.

```gitignore
# 환경 변수 및 비밀값
.env
.env.local
.env.*.local
.env.development
.env.production
.env.test

# 인증 정보
credentials.json
service-account*.json
*.pem
*.key
*.p12
*.pfx
secrets/
```

### 11.2 git-secrets 설정

AWS 인증 정보 등 패턴 기반 비밀값 유출을 사전에 차단합니다.

```bash
# git-secrets 설치 (macOS)
brew install git-secrets

# 저장소에 훅 등록
git secrets --install

# AWS 패턴 등록
git secrets --register-aws

# 커스텀 패턴 추가 (예: 사내 API 키 접두어)
git secrets --add 'INTERNAL_API_KEY_[A-Z0-9]+'

# 전체 커밋 이력 스캔
git secrets --scan-history
```

### 11.3 gitleaks 설정

CI 파이프라인에 gitleaks를 통합하여 자동 스캔합니다.

**.gitleaks.toml**

```toml
[allowlist]
  description = "글로벌 허용 목록"
  paths = [
    '''.gitleaks.toml''',
    '''CHANGELOG.md''',
  ]
```

**GitHub Actions 통합 예시**

```yaml
# .github/workflows/secret-scan.yml
name: Secret Scan
on: [push, pull_request]
jobs:
  gitleaks:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - uses: gitleaks/gitleaks-action@v2
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

### 11.4 실수로 커밋된 비밀값 대응 절차

비밀값이 실수로 커밋된 경우 아래 절차를 즉시 수행합니다.

```
[즉시 조치 — 30분 이내]
1. 해당 API 키 / 비밀번호를 즉시 폐기(revoke) 및 재발급
2. 팀 리더 및 보안 담당자에게 즉시 보고

[이력 삭제 — BFG Repo-Cleaner 사용]
# BFG 다운로드 후 실행
java -jar bfg.jar --replace-text secrets.txt {저장소 경로}

# 또는 특정 파일 완전 삭제
java -jar bfg.jar --delete-files .env {저장소 경로}

# 이력 정리 및 강제 푸시
cd {저장소}
git reflog expire --expire=now --all
git gc --prune=now --aggressive
git push --force

[후속 조치]
3. 모든 팀원 로컬 저장소 재클론 안내
4. .gitignore 누락 원인 분석 및 보완
5. git-secrets / gitleaks 훅 설치 여부 점검
```

> `git filter-branch`보다 BFG Repo-Cleaner가 훨씬 빠르고 안전합니다. 단, 강제 푸시 전 반드시 팀 전체에 공지하고 작업 중인 PR이 없는지 확인합니다.

---

## 12. .gitignore 기본 설정

```gitignore
# 의존성
node_modules/
.pnp
.pnp.js

# 환경 변수 및 비밀값 (11.1 참조)
.env
.env.local
.env.*.local

# 빌드 산출물
dist/
build/
target/
out/
.next/
.nuxt/

# 로그
*.log
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# 운영체제
.DS_Store
Thumbs.db

# IDE
.idea/
.vscode/
*.swp
*.swo

# 테스트 커버리지
coverage/
.nyc_output/

# 캐시
.cache/
.eslintcache
.stylelintcache
```

---

## 13. 변경 이력

| 버전 | 날짜 | 작성자 | 변경 내용 |
|------|------|--------|-----------|
| v1.0 | 2026-03-21 | 팀 | 최초 작성 |
| v2.0 | 2026-03-21 | 팀 | Smart Commit, 브랜치 보호, Git Hook, 태그 전략, 충돌 해결, 브랜치 생명주기, LFS, 비밀값 보호 추가 |
