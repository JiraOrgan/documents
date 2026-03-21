#!/bin/bash
# ============================================================
# Project Document Manager - 문서 폴더 초기화 스크립트
# 13개 표준 문서 폴더와 v1.0 템플릿을 일괄 생성한다.
#
# 사용법:
#   bash init_docs.sh [프로젝트루트] [프로젝트명] [작성자]
#
# 예시:
#   bash init_docs.sh /home/user/my-project "쇼핑몰 프로젝트" "홍길동"
#   bash init_docs.sh . "My Project" "작성자"
# ============================================================

set -euo pipefail

PROJECT_ROOT="${1:-.}"
PROJECT_NAME="${2:-프로젝트명}"
AUTHOR="${3:-작성자}"
TODAY=$(date +%Y-%m-%d)

DOCS_DIR="$PROJECT_ROOT/docs"

# 문서 정의: "폴더명|파일 접두사"
DOCUMENTS=(
  "00-스케줄|00-스케줄"
  "01-프로젝트계획서|01-프로젝트계획서"
  "02-ERD|02-ERD"
  "03-아키텍처정의서|03-아키텍처정의서"
  "04-API정의서|04-API정의서"
  "05-화면흐름시퀀스|05-화면흐름시퀀스"
  "06-화면기능정의서|06-화면기능정의서"
  "07-요구사항정의서|07-요구사항정의서"
  "08-Git규칙정의서|08-Git규칙정의서"
  "09-스토리보드|09-스토리보드"
  "10-테스트전략서|10-테스트전략서"
  "11-코드리뷰규칙|11-코드리뷰규칙"
  "12-배포가이드|12-배포가이드"
)

# docs 디렉토리가 이미 있으면 확인
if [ -d "$DOCS_DIR" ]; then
  echo "[경고] $DOCS_DIR 디렉토리가 이미 존재합니다."
  read -p "계속 진행하시겠습니까? (y/N): " confirm
  if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "취소되었습니다."
    exit 0
  fi
fi

echo "========================================="
echo " 프로젝트 문서 초기화"
echo " 프로젝트: $PROJECT_NAME"
echo " 작성자: $AUTHOR"
echo " 날짜: $TODAY"
echo " 경로: $DOCS_DIR"
echo "========================================="

# docs 디렉토리 생성
mkdir -p "$DOCS_DIR"

# 각 문서 폴더 및 템플릿 생성
for doc in "${DOCUMENTS[@]}"; do
  IFS='|' read -r folder prefix <<< "$doc"
  dir_path="$DOCS_DIR/$folder"
  file_path="$dir_path/${prefix}_v1.0.md"

  mkdir -p "$dir_path"

  if [ -f "$file_path" ]; then
    echo "[스킵] 이미 존재: $file_path"
    continue
  fi

  # 기본 메타데이터 + 빈 템플릿 생성
  cat > "$file_path" << EOF
---
문서명: $PROJECT_NAME $folder
버전: v1.0
작성일: $TODAY
최종수정일: $TODAY
작성자: $AUTHOR
상태: 초안
---

# $PROJECT_NAME $folder

> 이 문서는 기본 템플릿입니다. 상세 내용은 references/templates.md의 해당 섹션을 참고하여 작성하세요.

## 변경 이력

| 버전 | 날짜 | 작성자 | 변경 내용 |
|------|------|--------|-----------|
| v1.0 | $TODAY | $AUTHOR | 최초 작성 |
EOF

  echo "[생성] $file_path"
done

# README.md (문서 인덱스) 생성
README_PATH="$DOCS_DIR/README.md"
if [ ! -f "$README_PATH" ]; then
  cat > "$README_PATH" << EOF
# $PROJECT_NAME - 프로젝트 문서

> 최종 갱신일: $TODAY

## 문서 인덱스

| 번호 | 문서명 | 최신 버전 | 상태 | 비고 |
|------|--------|-----------|------|------|
| 00 | [스케줄](./00-스케줄/00-스케줄_v1.0.md) | v1.0 | 초안 | |
| 01 | [프로젝트 계획서](./01-프로젝트계획서/01-프로젝트계획서_v1.0.md) | v1.0 | 초안 | |
| 02 | [ERD](./02-ERD/02-ERD_v1.0.md) | v1.0 | 초안 | |
| 03 | [아키텍처 정의서](./03-아키텍처정의서/03-아키텍처정의서_v1.0.md) | v1.0 | 초안 | |
| 04 | [API 정의서](./04-API정의서/04-API정의서_v1.0.md) | v1.0 | 초안 | |
| 05 | [화면 흐름 시퀀스](./05-화면흐름시퀀스/05-화면흐름시퀀스_v1.0.md) | v1.0 | 초안 | |
| 06 | [화면 기능 정의서](./06-화면기능정의서/06-화면기능정의서_v1.0.md) | v1.0 | 초안 | |
| 07 | [요구사항 정의서](./07-요구사항정의서/07-요구사항정의서_v1.0.md) | v1.0 | 초안 | |
| 08 | [Git 규칙 정의서](./08-Git규칙정의서/08-Git규칙정의서_v1.0.md) | v1.0 | 초안 | |
| 09 | [스토리보드](./09-스토리보드/09-스토리보드_v1.0.md) | v1.0 | 초안 | |
| 10 | [테스트 전략서](./10-테스트전략서/10-테스트전략서_v1.0.md) | v1.0 | 초안 | |
| 11 | [코드 리뷰 규칙](./11-코드리뷰규칙/11-코드리뷰규칙_v1.0.md) | v1.0 | 초안 | |
| 12 | [배포 가이드](./12-배포가이드/12-배포가이드_v1.0.md) | v1.0 | 초안 | |

## 문서 관리 규칙

- 파일명 형식: \`{번호}-{문서명}_v{Major}.{Minor}.md\`
- 버전 규칙: 구조 변경 시 Major 증가, 내용 수정 시 Minor 증가
- 모든 문서는 상단 메타데이터(YAML frontmatter)를 포함
- 다이어그램은 Mermaid 코드 블록으로 작성
EOF

  echo "[생성] $README_PATH"
else
  echo "[스킵] 이미 존재: $README_PATH"
fi

echo ""
echo "========================================="
echo " 초기화 완료!"
echo " 생성된 폴더: ${#DOCUMENTS[@]}개"
echo " 경로: $DOCS_DIR"
echo "========================================="
