# render.ps1 -- Stock report JSON -> PDF via Microsoft Edge / Chrome headless.
#
# This script is intentionally ASCII-only. All locale text lives in:
#   - the JSON input (data)
#   - template.html in the same folder (static Korean labels)
# This avoids Windows PowerShell 5.1 misreading non-ASCII script bytes as CP949
# when the script lacks a UTF-8 BOM.
#
# Usage:
#   powershell -ExecutionPolicy Bypass -File render.ps1 -JsonPath <abs-path> [-OutputPdf <abs-path>]

param(
    [Parameter(Mandatory=$true)][string]$JsonPath,
    [string]$OutputPdf = $null
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path $JsonPath)) {
    Write-Error "JSON file not found: $JsonPath"
    exit 1
}

$JsonPath = (Resolve-Path $JsonPath).Path
if (-not $OutputPdf) {
    $OutputPdf = [System.IO.Path]::ChangeExtension($JsonPath, '.pdf')
}
$OutputPdf = [System.IO.Path]::GetFullPath($OutputPdf)

$scriptDir   = Split-Path -Parent $PSCommandPath
$templatePath = Join-Path $scriptDir 'template.html'
if (-not (Test-Path $templatePath)) {
    Write-Error "Template not found: $templatePath"
    exit 1
}

# --- Load template + JSON (both explicitly UTF-8) ---
$template = [System.IO.File]::ReadAllText($templatePath, [System.Text.UTF8Encoding]::new($false))
$raw      = [System.IO.File]::ReadAllText($JsonPath,    [System.Text.UTF8Encoding]::new($false))
$data     = $raw | ConvertFrom-Json

function Html-Escape([string]$s) {
    if ($null -eq $s) { return '' }
    return ($s -replace '&','&amp;' -replace '<','&lt;' -replace '>','&gt;' -replace '"','&quot;')
}

# --- Build dynamic HTML fragments from JSON ---
$perfRows = foreach ($p in $data.performance) {
    "      <tr><td>$(Html-Escape $p.period)</td><td><strong>$(Html-Escape $p.value)</strong></td><td>$(Html-Escape $p.note)</td></tr>"
}
$catItems  = foreach ($c in $data.catalysts) { "    <li>$(Html-Escape $c)</li>" }
$riskItems = foreach ($r in $data.risks)     { "    <li>$(Html-Escape $r)</li>" }
$srcItems  = foreach ($s in $data.sources) {
    "    <li><a href=`"$(Html-Escape $s.url)`">$(Html-Escape $s.title)</a></li>"
}

# --- Token substitution ---
$tokens = @{
    'TICKER'       = Html-Escape $data.ticker
    'COMPANY'      = Html-Escape $data.company
    'COMPANY_KR'   = Html-Escape $data.company_kr
    'EXCHANGE'     = Html-Escape $data.exchange
    'REPORT_DATE'  = Html-Escape $data.report_date_kst
    'GENERATED_AT' = Html-Escape $data.generated_at
    'MARKET_CAP'   = Html-Escape $data.price.market_cap_usd
    'SUMMARY'      = Html-Escape $data.summary
    'DISCLAIMER'   = Html-Escape $data.disclaimer
    'PERF_ROWS'    = ($perfRows  -join "`n")
    'CATALYSTS'    = ($catItems  -join "`n")
    'RISKS'        = ($riskItems -join "`n")
    'SOURCES'      = ($srcItems  -join "`n")
}

$html = $template
foreach ($k in $tokens.Keys) {
    $html = $html.Replace('{{' + $k + '}}', [string]$tokens[$k])
}

# --- Write temp HTML as UTF-8 with BOM (helps Edge sniff charset) ---
$tempHtml = [System.IO.Path]::ChangeExtension($OutputPdf, '.html')
$utf8Bom  = New-Object System.Text.UTF8Encoding($true)
[System.IO.File]::WriteAllText($tempHtml, $html, $utf8Bom)

# --- Locate Edge or Chrome ---
$browserCandidates = @(
    'C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe',
    'C:\Program Files\Microsoft\Edge\Application\msedge.exe',
    "$env:LOCALAPPDATA\Microsoft\Edge\Application\msedge.exe",
    'C:\Program Files\Google\Chrome\Application\chrome.exe',
    'C:\Program Files (x86)\Google\Chrome\Application\chrome.exe',
    "$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe"
)
$browser = $browserCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $browser) {
    Remove-Item $tempHtml -ErrorAction SilentlyContinue
    # Exit 2 = no headless-capable browser. The skill must keep .md/.json and notify the user.
    Write-Host 'PDF_SKIP: No headless-capable browser found (Microsoft Edge / Chrome). MD and JSON were written; PDF was not produced.'
    exit 2
}

# --- Run headless print-to-pdf ---
$htmlUri     = 'file:///' + ($tempHtml -replace '\\','/')
$tempProfile = Join-Path $env:TEMP "headless-pdf-$([guid]::NewGuid().ToString('N'))"

$browserArgs = @(
    '--headless=new',
    '--disable-gpu',
    '--no-sandbox',
    "--user-data-dir=$tempProfile",
    "--print-to-pdf=$OutputPdf",
    '--no-pdf-header-footer',
    $htmlUri
)

$proc = Start-Process -FilePath $browser -ArgumentList $browserArgs -Wait -PassThru -NoNewWindow

Remove-Item $tempHtml -ErrorAction SilentlyContinue
if (Test-Path $tempProfile) {
    Remove-Item $tempProfile -Recurse -Force -ErrorAction SilentlyContinue
}

if (-not (Test-Path $OutputPdf)) {
    # Exit 3 = browser ran but PDF not produced. Skill should keep .md/.json.
    Write-Host "PDF_FAIL: Headless browser ran but PDF was not produced at $OutputPdf (exit=$($proc.ExitCode))."
    exit 3
}

Write-Output $OutputPdf
