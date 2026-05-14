#!/usr/bin/env bash
#
# Claude Code 워크숍 - macOS 설치 검증 스크립트
#
# 사용법:
#   bash verify-macos.sh
#

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

PASS=0
FAIL=0

check_ok()   { printf "${GREEN}[ OK ]${NC}  %s\n" "$*"; PASS=$((PASS+1)); }
check_fail() { printf "${RED}[FAIL]${NC}  %s\n" "$*"; FAIL=$((FAIL+1)); }
info()       { printf "${BLUE}[INFO]${NC}  %s\n" "$*"; }

echo ""
echo "================================================================"
echo " Claude Code 사전 설치 검증 (macOS)"
echo "================================================================"
echo ""

# Node.js
if command -v node >/dev/null 2>&1; then
  check_ok "Node.js: $(node --version)"
else
  check_fail "Node.js 가 설치되어 있지 않거나 PATH에 잡히지 않습니다."
fi

# npm
if command -v npm >/dev/null 2>&1; then
  check_ok "npm: $(npm --version)"
else
  check_fail "npm 명령어를 찾을 수 없습니다."
fi

# Python
if command -v python3 >/dev/null 2>&1; then
  check_ok "Python: $(python3 --version)"
else
  check_fail "Python 3 가 설치되어 있지 않거나 PATH에 잡히지 않습니다."
fi

# pip
if command -v pip3 >/dev/null 2>&1; then
  check_ok "pip: $(pip3 --version | awk '{print $2}')"
else
  check_fail "pip3 명령어를 찾을 수 없습니다."
fi

# Git
if command -v git >/dev/null 2>&1; then
  check_ok "Git: $(git --version | awk '{print $3}')"
else
  check_fail "Git 이 설치되어 있지 않거나 PATH에 잡히지 않습니다."
fi

# Claude Code
if command -v claude >/dev/null 2>&1; then
  CLAUDE_VERSION=$(claude --version 2>/dev/null || echo "version check failed")
  check_ok "Claude Code: ${CLAUDE_VERSION}"
else
  check_fail "claude 명령어를 찾을 수 없습니다. 설치 후 새 터미널을 열었나요?"
fi

# 로그인 상태(간이 체크)
if command -v claude >/dev/null 2>&1; then
  if [[ -d "$HOME/.claude" ]] || [[ -f "$HOME/.config/claude/auth.json" ]] || [[ -f "$HOME/.claude.json" ]]; then
    check_ok "Claude 설정 디렉터리 존재"
  else
    info "로그인 미완료로 보입니다. 'claude' 명령어를 한 번 실행해 로그인을 끝내주세요."
  fi
fi

echo ""
echo "================================================================"
echo " 결과: 통과 ${PASS}개 / 실패 ${FAIL}개"
echo "================================================================"
echo ""

if [[ $FAIL -eq 0 ]]; then
  printf "${GREEN}축하합니다! 모든 준비가 끝났습니다.${NC}\n"
  echo ""
  echo "마지막 단계 - 'claude' 명령어를 실행해 로그인을 마치고,"
  echo "이 검증 결과 화면을 캡처해서 진행자에게 인증해 주세요."
  exit 0
else
  printf "${RED}일부 항목이 실패했습니다. FAQ.md 를 확인하거나 진행자에게 문의하세요.${NC}\n"
  exit 1
fi
