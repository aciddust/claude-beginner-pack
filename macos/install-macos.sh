#!/usr/bin/env bash
#
# Claude Code 워크숍 - macOS 자동 설치 스크립트
#
# 사용법:
#   bash install-macos.sh           # 단계별 Y/N 확인
#   bash install-macos.sh -y        # 모든 단계 자동 진행 (기본값 사용)
#
# 이 스크립트가 하는 일:
#   1. Homebrew (macOS 패키지 관리자) 설치 확인 및 설치
#   2. Node.js LTS 설치 (Claude Code 본체용)
#   3. Python 3 설치 (자동화 스킬용)
#   4. Git 설치 (변경 이력 추적/플러그인 다운로드용)
#   5. Visual Studio Code 설치 (에디터)
#   6. Claude Code 설치
#

set -e
set -u

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

log()  { printf "${BLUE}[INFO]${NC}  %s\n" "$*"; }
ok()   { printf "${GREEN}[ OK ]${NC}  %s\n" "$*"; }
warn() { printf "${YELLOW}[WARN]${NC}  %s\n" "$*"; }
err()  { printf "${RED}[FAIL]${NC}  %s\n" "$*"; }

AUTO_YES=0
for arg in "$@"; do
  case "$arg" in
    -y|--yes) AUTO_YES=1 ;;
    -h|--help)
      sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
  esac
done

# ask_yes <prompt> <default>
#   default: "y" → Enter 시 Yes / [Y/n] 표시
#            "n" → Enter 시 No  / [y/N] 표시
#   -y 옵션이면 무조건 default 값 사용 (질문 생략)
ask_yes() {
  local prompt="$1"
  local default="${2:-y}"
  local hint
  if [[ "$default" == "y" ]]; then hint="[Y/n]"; else hint="[y/N]"; fi
  if [[ "$AUTO_YES" == "1" ]]; then
    [[ "$default" == "y" ]] && return 0 || return 1
  fi
  local reply
  printf "${YELLOW}[ASK ]${NC}  %s %s " "$prompt" "$hint"
  read -r reply
  reply=$(echo "$reply" | tr '[:upper:]' '[:lower:]')
  if [[ -z "$reply" ]]; then
    [[ "$default" == "y" ]] && return 0 || return 1
  fi
  case "$reply" in
    y|yes) return 0 ;;
    *) return 1 ;;
  esac
}

trap 'err "설치 중 문제가 발생했습니다. 가이드의 FAQ를 참고하거나 진행자에게 문의하세요."' ERR

echo ""
echo "================================================================"
echo " Claude Code 워크숍 - macOS 사전 설치"
echo "================================================================"
echo ""
log "이 스크립트는 5~15분 정도 소요됩니다."
log "중간에 비밀번호 입력 요청이 나오면 Mac 로그인 비밀번호를 입력하세요."
log "이미 설치된 단계는 건너뛸 수 있습니다 (모두 자동: bash install-macos.sh -y)."
echo ""

# Architecture detection
ARCH=$(uname -m)
if [[ "$ARCH" == "arm64" ]]; then
  BREW_PREFIX="/opt/homebrew"
else
  BREW_PREFIX="/usr/local"
fi

# Step 1: Homebrew
log "[1/6] Homebrew"
if command -v brew >/dev/null 2>&1; then
  ok "이미 설치됨: $(brew --version | head -n 1)"
else
  warn "Homebrew가 설치되어 있지 않습니다."
  if ask_yes "Homebrew 를 설치할까요? (이후 단계에 필요)" y; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    if [[ -x "${BREW_PREFIX}/bin/brew" ]]; then
      eval "$(${BREW_PREFIX}/bin/brew shellenv)"
    fi
    ok "Homebrew 설치 완료 ($(brew --version | head -n 1))"
  else
    err "Homebrew 가 없으면 이 스크립트의 나머지 단계를 진행할 수 없습니다."
    exit 1
  fi
fi
echo ""

# Step 2: Node.js
log "[2/6] Node.js"
if command -v node >/dev/null 2>&1; then
  log "이미 설치됨: Node.js $(node --version)"
  if ask_yes "재설치(업그레이드)할까요?" n; then
    brew install node
    ok "Node.js: $(node --version) / npm: $(npm --version)"
  else
    log "Node.js 단계 건너뜀"
  fi
else
  if ask_yes "Node.js LTS 를 설치할까요?" y; then
    brew install node
    ok "Node.js: $(node --version) / npm: $(npm --version)"
  else
    warn "Node.js 건너뜀 — Claude Code 실행이 불가능할 수 있습니다."
  fi
fi
echo ""

# Step 3: Python
log "[3/6] Python 3"
if command -v python3 >/dev/null 2>&1; then
  log "이미 설치됨: $(python3 --version)"
  if ask_yes "재설치(업그레이드)할까요?" n; then
    brew install python
    ok "Python: $(python3 --version)"
  else
    log "Python 단계 건너뜀"
  fi
else
  if ask_yes "Python 3 를 설치할까요?" y; then
    brew install python
    ok "Python: $(python3 --version)"
  else
    warn "Python 건너뜀 — 일부 자동화 스킬이 동작하지 않을 수 있습니다."
  fi
fi
echo ""

# Step 4: Git
log "[4/6] Git"
if command -v git >/dev/null 2>&1; then
  log "이미 설치됨: $(git --version)"
  if ask_yes "재설치(업그레이드)할까요?" n; then
    brew install git
    ok "Git: $(git --version)"
  else
    log "Git 단계 건너뜀"
  fi
else
  if ask_yes "Git 을 설치할까요?" y; then
    brew install git
    ok "Git: $(git --version)"
  else
    warn "Git 건너뜀 — 일부 워크숍 과제에 영향이 있을 수 있습니다."
  fi
fi
echo ""

# Step 5: Visual Studio Code (cask)
log "[5/6] Visual Studio Code"
if [ -d "/Applications/Visual Studio Code.app" ]; then
  log "이미 설치됨: VS Code"
  if ask_yes "재설치할까요?" n; then
    brew install --cask visual-studio-code --force
    ok "VS Code 재설치 완료"
  else
    log "VS Code 단계 건너뜀"
  fi
else
  if ask_yes "VS Code 를 설치할까요?" y; then
    brew install --cask visual-studio-code
    if [ -d "/Applications/Visual Studio Code.app" ]; then
      ok "VS Code 설치 완료"
    else
      warn "VS Code 설치를 확인할 수 없습니다 (수동 확인 필요)."
    fi
  else
    warn "VS Code 건너뜀 — 다른 에디터를 사용 중이라면 무관합니다."
  fi
fi
echo ""

# Step 6: Claude Code
log "[6/6] Claude Code"
if command -v claude >/dev/null 2>&1; then
  log "이미 설치됨: Claude Code $(claude --version 2>/dev/null || echo 'version unknown')"
  if ask_yes "재설치(업그레이드)할까요?" n; then
    npm install -g @anthropic-ai/claude-code
    ok "Claude Code 재설치 완료"
  else
    log "Claude Code 단계 건너뜀"
  fi
else
  if ask_yes "Claude Code 를 설치할까요?" y; then
    if ! command -v npm >/dev/null 2>&1; then
      err "npm 을 찾을 수 없어 Claude Code 설치를 진행할 수 없습니다."
    else
      npm install -g @anthropic-ai/claude-code
      if command -v claude >/dev/null 2>&1; then
        ok "Claude Code: $(claude --version 2>/dev/null || echo 'version unknown')"
      else
        warn "claude 명령어가 즉시 잡히지 않습니다. 새 터미널 창에서 다시 확인하세요."
      fi
    fi
  else
    warn "Claude Code 건너뜀 — 워크숍에 필수입니다."
  fi
fi
echo ""

echo "================================================================"
ok "스크립트 종료. 다음 단계로 진행하세요."
echo "================================================================"
echo ""
echo "다음 단계:"
echo "  1) 이 터미널 창을 닫고 새 터미널 창을 엽니다."
echo "  2) 다음 명령어로 검증 스크립트를 실행합니다:"
echo ""
echo "       bash verify-macos.sh"
echo ""
echo "  3) 검증이 통과하면 'claude' 명령어로 로그인을 진행합니다."
echo ""
