# Claude Code 워크숍 - Windows 자동 설치 스크립트
#
# 사용법 (PowerShell 관리자 권한):
#   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
#   .\install-windows.ps1            # 단계별 Y/N 확인
#   .\install-windows.ps1 -Yes       # 모든 단계 자동 진행 (기본값 사용)
#
# 이 스크립트가 하는 일:
#   1. winget(Windows 패키지 관리자) 사용 가능 여부 확인
#   2. Node.js LTS 설치 (Claude Code 본체용)
#   3. Python 3 설치 (자동화 스킬용)
#   4. Git 설치 (변경 이력 추적/플러그인 다운로드용)
#   5. Visual Studio Code 설치 (에디터)
#   6. Claude Code 설치
#   7. 설치 검증

param(
    [switch]$Yes
)

$ErrorActionPreference = "Stop"

function Write-Info  { param($msg) Write-Host "[INFO]  $msg" -ForegroundColor Cyan }
function Write-Ok    { param($msg) Write-Host "[ OK ]  $msg" -ForegroundColor Green }
function Write-Warn  { param($msg) Write-Host "[WARN]  $msg" -ForegroundColor Yellow }
function Write-Err   { param($msg) Write-Host "[FAIL]  $msg" -ForegroundColor Red }

function Has-Cmd {
    param([string]$Name)
    return $null -ne (Get-Command $Name -ErrorAction SilentlyContinue)
}

# Ask-Yes <prompt> <default("y"|"n")>
#   default: "y" → Enter 시 Yes / [Y/n] 표시
#            "n" → Enter 시 No  / [y/N] 표시
#   -Yes 옵션이면 무조건 default 값 사용 (질문 생략)
function Ask-Yes {
    param(
        [string]$Prompt,
        [string]$Default = "y"
    )
    $hint = if ($Default -eq "y") { "[Y/n]" } else { "[y/N]" }
    if ($Yes) {
        return ($Default -eq "y")
    }
    Write-Host "[ASK ]  $Prompt $hint " -ForegroundColor Yellow -NoNewline
    $reply = Read-Host
    if ($null -eq $reply) { $reply = "" }
    $reply = $reply.ToLower().Trim()
    if ([string]::IsNullOrEmpty($reply)) {
        return ($Default -eq "y")
    }
    return ($reply -eq "y" -or $reply -eq "yes")
}

Write-Host ""
Write-Host "================================================================"
Write-Host " Claude Code 워크숍 - Windows 사전 설치"
Write-Host "================================================================"
Write-Host ""
Write-Info "이 스크립트는 5~15분 정도 소요됩니다."
Write-Info "사용자 계정 컨트롤(UAC) 창이 뜨면 '예'를 눌러주세요."
Write-Info "이미 설치된 단계는 건너뛸 수 있습니다 (모두 자동: .\install-windows.ps1 -Yes)."
Write-Host ""

# 관리자 권한 확인
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Warn "관리자 권한이 아닐 수 있습니다."
    Write-Warn "PowerShell을 닫고 '관리자 권한으로 실행'으로 다시 열어주세요."
    Write-Host ""
}

# winget 사용 가능 여부 확인
Write-Info "winget(Windows 패키지 관리자) 확인 중..."
if (-not (Has-Cmd "winget")) {
    Write-Err "winget을 찾을 수 없습니다."
    Write-Host ""
    Write-Host "해결 방법:"
    Write-Host "  1) Microsoft Store 에서 'App Installer' 를 검색해 설치 또는 업데이트"
    Write-Host "  2) Windows 10 (1809+) 또는 Windows 11 사용 권장"
    Write-Host "  3) 또는 가이드의 '경로 B: 수동 설치' 를 따라가세요."
    exit 1
}
Write-Ok "winget 사용 가능"
Write-Host ""

# Step 1: Node.js
Write-Info "[1/5] Node.js"
if (Has-Cmd "node") {
    $current = (& node --version) 2>$null
    Write-Info "이미 설치됨: Node.js $current"
    $doInstall = Ask-Yes "재설치(업그레이드)할까요?" "n"
} else {
    $doInstall = Ask-Yes "Node.js LTS 를 설치할까요?" "y"
}
if ($doInstall) {
    try {
        winget install -e --id OpenJS.NodeJS.LTS --accept-package-agreements --accept-source-agreements --silent
        Write-Ok "Node.js 설치 완료"
    } catch {
        Write-Warn "Node.js 가 이미 최신 버전이거나 설치 중 경고가 발생했습니다."
    }
} else {
    Write-Info "Node.js 단계 건너뜀"
}
Write-Host ""

# Step 2: Python
Write-Info "[2/5] Python 3"
$pythonCmd = $null
foreach ($c in @("python","python3","py")) {
    if (Has-Cmd $c) { $pythonCmd = $c; break }
}
if ($pythonCmd) {
    $current = (& $pythonCmd --version) 2>&1
    Write-Info "이미 설치됨: $current"
    $doInstall = Ask-Yes "재설치(업그레이드)할까요?" "n"
} else {
    $doInstall = Ask-Yes "Python 3 를 설치할까요?" "y"
}
if ($doInstall) {
    try {
        winget install -e --id Python.Python.3.12 --accept-package-agreements --accept-source-agreements --silent
        Write-Ok "Python 설치 완료"
    } catch {
        Write-Warn "Python 이 이미 최신 버전이거나 설치 중 경고가 발생했습니다."
    }
} else {
    Write-Info "Python 단계 건너뜀"
}
Write-Host ""

# Step 3: Git
Write-Info "[3/5] Git"
if (Has-Cmd "git") {
    $current = (& git --version) 2>$null
    Write-Info "이미 설치됨: $current"
    $doInstall = Ask-Yes "재설치(업그레이드)할까요?" "n"
} else {
    $doInstall = Ask-Yes "Git 을 설치할까요?" "y"
}
if ($doInstall) {
    try {
        winget install -e --id Git.Git --accept-package-agreements --accept-source-agreements --silent
        Write-Ok "Git 설치 완료"
    } catch {
        Write-Warn "Git 이 이미 최신 버전이거나 설치 중 경고가 발생했습니다."
    }
} else {
    Write-Info "Git 단계 건너뜀"
}
Write-Host ""

# Step 4: Visual Studio Code
Write-Info "[4/5] Visual Studio Code"
if (Has-Cmd "code") {
    Write-Info "이미 설치됨: VS Code (code 명령어 감지)"
    $doInstall = Ask-Yes "재설치(업그레이드)할까요?" "n"
} else {
    $doInstall = Ask-Yes "VS Code 를 설치할까요?" "y"
}
if ($doInstall) {
    try {
        winget install -e --id Microsoft.VisualStudioCode --accept-package-agreements --accept-source-agreements --silent
        Write-Ok "VS Code 설치 완료"
    } catch {
        Write-Warn "VS Code 가 이미 최신 버전이거나 설치 중 경고가 발생했습니다."
    }
} else {
    Write-Info "VS Code 단계 건너뜀"
}
Write-Host ""

# 새로 설치된 도구의 PATH를 현재 세션에 반영
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

# Step 5: Claude Code
Write-Info "[5/5] Claude Code"
if (Has-Cmd "claude") {
    $current = (& claude --version) 2>$null
    if (-not $current) { $current = "version unknown" }
    Write-Info "이미 설치됨: Claude Code $current"
    $doInstall = Ask-Yes "재설치(업그레이드)할까요?" "n"
} else {
    $doInstall = Ask-Yes "Claude Code 를 설치할까요?" "y"
}
if ($doInstall) {
    if (-not (Has-Cmd "npm")) {
        Write-Err "npm 명령어를 찾을 수 없습니다."
        Write-Host ""
        Write-Host "다음 단계로 해결하세요:"
        Write-Host "  1) 이 PowerShell 창을 완전히 닫습니다"
        Write-Host "  2) 새 PowerShell(관리자)을 엽니다"
        Write-Host "  3) 'npm --version' 으로 동작 확인"
        Write-Host "  4) 다음 명령어로 Claude Code 만 별도 설치:"
        Write-Host "       npm install -g @anthropic-ai/claude-code"
    } else {
        npm install -g @anthropic-ai/claude-code
        if (Has-Cmd "claude") {
            Write-Ok "Claude Code 설치 완료"
        } else {
            Write-Warn "claude 명령어가 즉시 잡히지 않습니다. 새 PowerShell 창에서 다시 시도하세요."
        }
    }
} else {
    Write-Info "Claude Code 단계 건너뜀"
}
Write-Host ""

Write-Host "================================================================"
Write-Ok "스크립트 종료. 다음 단계로 진행하세요."
Write-Host "================================================================"
Write-Host ""
Write-Host "다음 단계:"
Write-Host "  1) 이 PowerShell 창을 완전히 닫고 새 PowerShell 창을 엽니다."
Write-Host "  2) 다음 명령어로 검증 스크립트를 실행합니다:"
Write-Host ""
Write-Host "       .\verify-windows.ps1"
Write-Host ""
Write-Host "  3) 검증이 통과하면 'claude' 명령어로 로그인을 진행합니다."
Write-Host ""
