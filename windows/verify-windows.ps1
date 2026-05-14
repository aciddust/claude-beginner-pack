# Claude Code 워크숍 - Windows 설치 검증 스크립트
#
# 사용법 (PowerShell):
#   .\verify-windows.ps1
#
# (Set-ExecutionPolicy 가 막혀있다면 먼저:
#    Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass )

$ErrorActionPreference = "Continue"

$pass = 0
$fail = 0

function Check-Ok   { param($msg) Write-Host "[ OK ]  $msg" -ForegroundColor Green; $script:pass++ }
function Check-Fail { param($msg) Write-Host "[FAIL]  $msg" -ForegroundColor Red;   $script:fail++ }
function Info       { param($msg) Write-Host "[INFO]  $msg" -ForegroundColor Cyan }

Write-Host ""
Write-Host "================================================================"
Write-Host " Claude Code 사전 설치 검증 (Windows)"
Write-Host "================================================================"
Write-Host ""

# Node.js
if (Get-Command node -ErrorAction SilentlyContinue) {
    $v = (& node --version) 2>$null
    Check-Ok "Node.js: $v"
} else {
    Check-Fail "Node.js 가 설치되어 있지 않거나 PATH에 잡히지 않습니다."
}

# npm
if (Get-Command npm -ErrorAction SilentlyContinue) {
    $v = (& npm --version) 2>$null
    Check-Ok "npm: $v"
} else {
    Check-Fail "npm 명령어를 찾을 수 없습니다."
}

# Python
$pythonCmd = $null
foreach ($candidate in @("python", "python3", "py")) {
    if (Get-Command $candidate -ErrorAction SilentlyContinue) {
        $pythonCmd = $candidate
        break
    }
}
if ($pythonCmd) {
    $v = (& $pythonCmd --version) 2>&1
    Check-Ok "Python: $v"
} else {
    Check-Fail "Python 이 설치되어 있지 않거나 PATH에 잡히지 않습니다."
}

# pip
$pipCmd = $null
foreach ($candidate in @("pip", "pip3")) {
    if (Get-Command $candidate -ErrorAction SilentlyContinue) {
        $pipCmd = $candidate
        break
    }
}
if ($pipCmd) {
    $v = (& $pipCmd --version) 2>&1
    Check-Ok "pip: $($v -split ' ' | Select-Object -Index 1)"
} else {
    Check-Fail "pip 명령어를 찾을 수 없습니다."
}

# Git
if (Get-Command git -ErrorAction SilentlyContinue) {
    $v = (& git --version) 2>$null
    Check-Ok "Git: $($v -replace '^git version ', '')"
} else {
    Check-Fail "Git 이 설치되어 있지 않거나 PATH에 잡히지 않습니다."
}

# VS Code
if (Get-Command code -ErrorAction SilentlyContinue) {
    $v = (& code --version 2>$null | Select-Object -First 1)
    Check-Ok "VS Code: $v"
} else {
    Check-Fail "VS Code (code 명령어)가 PATH에 잡히지 않습니다. 새 PowerShell 창을 열었나요?"
}

# Claude Code
if (Get-Command claude -ErrorAction SilentlyContinue) {
    $v = (& claude --version) 2>$null
    if (-not $v) { $v = "version check failed" }
    Check-Ok "Claude Code: $v"
} else {
    Check-Fail "claude 명령어를 찾을 수 없습니다. 설치 후 새 PowerShell 창을 열었나요?"
}

# 로그인 상태(간이 체크)
if (Get-Command claude -ErrorAction SilentlyContinue) {
    $authPaths = @(
        "$HOME\.claude",
        "$HOME\.claude.json",
        "$env:APPDATA\claude\auth.json"
    )
    $hasAuth = $false
    foreach ($p in $authPaths) {
        if (Test-Path $p) { $hasAuth = $true; break }
    }
    if ($hasAuth) {
        Check-Ok "Claude 설정 디렉터리 존재"
    } else {
        Info "로그인 미완료로 보입니다. 'claude' 명령어를 한 번 실행해 로그인을 끝내주세요."
    }
}

Write-Host ""
Write-Host "================================================================"
Write-Host " 결과: 통과 $pass 개 / 실패 $fail 개"
Write-Host "================================================================"
Write-Host ""

if ($fail -eq 0) {
    Write-Host "축하합니다! 모든 준비가 끝났습니다." -ForegroundColor Green
    Write-Host ""
    Write-Host "마지막 단계 - 'claude' 명령어를 실행해 로그인을 마치고,"
    Write-Host "이 검증 결과 화면을 캡처해서 진행자에게 인증해 주세요."
    exit 0
} else {
    Write-Host "일부 항목이 실패했습니다. FAQ.md 를 확인하거나 진행자에게 문의하세요." -ForegroundColor Red
    exit 1
}
