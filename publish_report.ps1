<#
.SYNOPSIS
  Publish a stock or wine report to the Chory & Rochet Stock_Report_Repo
  GitHub Pages site.

.DESCRIPTION
  Copies the HTML report into the repo (reports/ or wine/), updates
  data/reports.json with a new metadata entry, commits, and pushes.
  Prints the public site URL and copies it to the clipboard.

.PARAMETER File
  Absolute or relative path to the HTML report.

.PARAMETER Title
  Card title shown on the site.

.PARAMETER Summary
  2-3 line summary shown on the card.

.PARAMETER Category
  One of: 시황, 종목분석, 섹터·테마, 공지, 와인

.PARAMETER Slug
  Optional. Filename stem used inside the repo (date is prepended automatically).
  e.g. -Slug "kr-daily-close" → 2026-05-16-kr-daily-close.html
  If omitted, the source filename is preserved.

.PARAMETER Tags
  Comma-separated tags. e.g. "반도체,외인매수,Tier1"

.PARAMETER Date
  Report date (YYYY-MM-DD). Defaults to today.

.PARAMETER NoPush
  Stage and commit but skip git push. Useful for batching.

.EXAMPLE
  .\publish_report.ps1 `
    -File "C:\Users\USER\Documents\daily_close_report_20260516.html" `
    -Title "2026-05-16 일일 마감 정리 및 익일 준비" `
    -Summary "KOSPI +0.8%, 외인 코스피 +5,200억. 반도체·2차전지 주도. 익일 시나리오 A 우선." `
    -Category "시황" `
    -Slug "kr-daily-close" `
    -Tags "마감,반도체,Tier1"
#>
[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)][string]$File,
  [Parameter(Mandatory = $true)][string]$Title,
  [Parameter(Mandatory = $true)][string]$Summary,
  [Parameter(Mandatory = $true)]
  [ValidateSet("시황", "종목분석", "섹터·테마", "공지", "와인")]
  [string]$Category,
  [string]$Slug = "",
  [string]$Tags = "",
  [string]$Date = (Get-Date -Format "yyyy-MM-dd"),
  [switch]$NoPush
)

$ErrorActionPreference = "Stop"

$RepoRoot = "C:\Users\USER\Documents\Stock_Report_Repo"
$SiteBase = "https://choryian.github.io/Stock_Report_Repo"

# 1. Resolve source ---------------------------------------------------------
if (-not (Test-Path $File)) { throw "File not found: $File" }
$src = (Resolve-Path $File).Path

# 2. Decide target path -----------------------------------------------------
$targetFolder = if ($Category -eq "와인") { "wine" } else { "reports" }

if ($Slug) {
  $clean = $Slug -replace '[^\w\-]', '-'
  $targetName = "$Date-$clean.html"
} else {
  $targetName = Split-Path $src -Leaf
  if ($targetName -notmatch '^\d{4}-\d{2}-\d{2}') {
    $targetName = "$Date-$targetName"
  }
}

$targetPath = Join-Path $RepoRoot "$targetFolder\$targetName"
$relPath    = "$targetFolder/$targetName"

# 3. Copy file --------------------------------------------------------------
Copy-Item $src $targetPath -Force
Write-Host "✓ Copied → $relPath" -ForegroundColor Green

# 4. Update reports.json ----------------------------------------------------
$jsonPath = Join-Path $RepoRoot "data\reports.json"
$jsonRaw  = Get-Content $jsonPath -Raw -Encoding UTF8
$json     = $jsonRaw | ConvertFrom-Json

$id = [IO.Path]::GetFileNameWithoutExtension($targetName)
$tagArray = @()
if ($Tags) {
  $tagArray = $Tags.Split(",") | ForEach-Object { $_.Trim() } | Where-Object { $_ }
}

# Remove existing entry with same id (re-publish overwrites)
$kept = @($json.reports | Where-Object { $_.id -ne $id })

$newEntry = [ordered]@{
  id       = $id
  title    = $Title
  summary  = $Summary
  category = $Category
  date     = $Date
  path     = $relPath
  tags     = $tagArray
}

$json.reports = @($newEntry) + $kept

# Serialize with UTF-8 (preserve Korean)
$out = [ordered]@{ reports = $json.reports } | ConvertTo-Json -Depth 6
[IO.File]::WriteAllText($jsonPath, $out, [Text.UTF8Encoding]::new($false))
Write-Host "✓ Updated data/reports.json (id=$id)" -ForegroundColor Green

# 5. Git add / commit / push -----------------------------------------------
Push-Location $RepoRoot
try {
  & git add -A | Out-Null
  $commitMsg = "Publish: [$Category] $Title ($Date)"
  & git commit -m $commitMsg | Out-Null
  Write-Host "✓ Committed: $commitMsg" -ForegroundColor Green

  if (-not $NoPush) {
    & git push origin main 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "git push failed (exit $LASTEXITCODE)" }
    Write-Host "✓ Pushed to GitHub" -ForegroundColor Green
  } else {
    Write-Host "  (push skipped — -NoPush)" -ForegroundColor Yellow
  }
} finally {
  Pop-Location
}

# 6. Output URL -------------------------------------------------------------
$publicUrl = "$SiteBase/$relPath"
Write-Host ""
Write-Host "🌐 Published" -ForegroundColor Cyan
Write-Host "   $publicUrl" -ForegroundColor White

try {
  $publicUrl | Set-Clipboard
  Write-Host "   (URL copied to clipboard)" -ForegroundColor Gray
} catch {
  # Set-Clipboard not available in some shells; ignore
}

return $publicUrl
