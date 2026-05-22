<#
.SYNOPSIS
  Sync the roadmap figure (SVG + legend + priority) from the canonical source
  file into the site page roadmap/index.html.

.DESCRIPTION
  Reads the block between <!-- RM-FIGURE:START --> and <!-- RM-FIGURE:END -->
  in the source roadmap HTML, adapts class names to the site-scoped ones
  (legend -> rm-legend, priority -> rm-priority), and replaces the matching
  marked block in roadmap/index.html. Also stamps the "최종 업데이트" date.

  Called automatically by publish_report.ps1 when -Category 로드맵리뷰,
  so the refreshed figure rides along in the same commit/push.
  Can also be run standalone to preview the sync.

.PARAMETER Date
  Update date (YYYY-MM-DD) stamped into the page. Defaults to today.
#>
[CmdletBinding()]
param(
  [string]$Date = (Get-Date -Format "yyyy-MM-dd")
)

$ErrorActionPreference = "Stop"
$utf8 = [Text.UTF8Encoding]::new($false)

$RoadmapSrc  = "D:\분석 보고서\korea_stock_roadmap_2026H2.html"
$RoadmapPage = "C:\Users\USER\Documents\Stock_Report_Repo\roadmap\index.html"

if (-not (Test-Path $RoadmapSrc)) {
  Write-Host "⚠ 로드맵 원본 없음 — 동기화 건너뜀: $RoadmapSrc" -ForegroundColor Yellow
  return $false
}
if (-not (Test-Path $RoadmapPage)) { throw "로드맵 페이지 없음: $RoadmapPage" }

$src  = [IO.File]::ReadAllText($RoadmapSrc, $utf8)
$page = [IO.File]::ReadAllText($RoadmapPage, $utf8)

$rx = '(?s)<!-- RM-FIGURE:START -->(.*?)<!-- RM-FIGURE:END -->'

$mSrc = [regex]::Match($src, $rx)
if (-not $mSrc.Success) { throw "원본에 RM-FIGURE 마커가 없습니다: $RoadmapSrc" }

# Extract figure and adapt class names to site-scoped versions
$figure = $mSrc.Groups[1].Value
$figure = $figure -replace 'class="legend"',   'class="rm-legend"'
$figure = $figure -replace 'class="priority"', 'class="rm-priority"'

if ($page -notmatch $rx) { throw "페이지에 RM-FIGURE 마커가 없습니다: $RoadmapPage" }

# Replace via MatchEvaluator so literal '$' in the figure (e.g. $81.6B) is NOT
# treated as a regex group reference.
$evaluator = [System.Text.RegularExpressions.MatchEvaluator]{
  param($m)
  "<!-- RM-FIGURE:START -->$figure<!-- RM-FIGURE:END -->"
}
$page = [regex]::Replace($page, $rx, $evaluator)

# Stamp update date
$page = [regex]::Replace(
  $page,
  '(?s)(<p class="roadmap-updated">최종 업데이트: )\d{4}-\d{2}-\d{2}',
  ('${1}' + $Date)
)

[IO.File]::WriteAllText($RoadmapPage, $page, $utf8)
Write-Host "✓ 로드맵 그림 동기화 완료 → roadmap/index.html (기준일 $Date)" -ForegroundColor Green
return $true
