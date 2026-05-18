<#
.SYNOPSIS
  Add an entry to the encrypted Journal on the Stock_Report_Repo site.

.DESCRIPTION
  Decrypts journal/entries.enc, appends a new entry, re-encrypts with a
  fresh salt/IV, writes back to journal/entries.enc, then commits and
  pushes. If no entries.enc exists, treats this as first-time setup.

.PARAMETER Title
  Entry title. Required.

.PARAMETER Content
  Entry body (markdown OK). If omitted, opens notepad to write.

.PARAMETER Date
  Override date (YYYY-MM-DD). Defaults to today.

.PARAMETER List
  Decrypt and print a summary of all entries (no edit, no push).

.PARAMETER NoPush
  Stage and commit but skip git push.

.EXAMPLE
  .\journal_add.ps1 -Title "오늘 생각" -Content "..."

.EXAMPLE
  .\journal_add.ps1 -Title "주말 회고"
  # opens notepad to write content

.EXAMPLE
  .\journal_add.ps1 -List
#>
[CmdletBinding(DefaultParameterSetName = 'Add')]
param(
  [Parameter(ParameterSetName = 'Add', Mandatory = $true)][string]$Title,
  [Parameter(ParameterSetName = 'Add')][string]$Content = "",
  [Parameter(ParameterSetName = 'Add')][string]$Date = (Get-Date -Format "yyyy-MM-dd"),
  [Parameter(ParameterSetName = 'Add')][switch]$NoPush,
  [Parameter(ParameterSetName = 'List')][switch]$List
)

$ErrorActionPreference = "Stop"
$RepoRoot   = "C:\Users\USER\Documents\Stock_Report_Repo"
$JournalDir = Join-Path $RepoRoot "journal"
$EncPath    = Join-Path $JournalDir "entries.enc"
$Iterations = 200000

# ----- Helpers ---------------------------------------------------------------

function Read-PasswordPlain {
  param([string]$Prompt = "비밀번호")
  $secure = Read-Host -Prompt $Prompt -AsSecureString
  $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
  try {
    return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
  } finally {
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
  }
}

function Derive-Key {
  param([string]$Password, [byte[]]$Salt, [int]$Iter)
  $pbkdf2 = [System.Security.Cryptography.Rfc2898DeriveBytes]::new(
    $Password, $Salt, $Iter,
    [System.Security.Cryptography.HashAlgorithmName]::SHA256
  )
  try { return $pbkdf2.GetBytes(32) }
  finally { $pbkdf2.Dispose() }
}

function Encrypt-Text {
  param([string]$Plaintext, [string]$Password)
  $salt = [byte[]]::new(16)
  $iv   = [byte[]]::new(12)
  [System.Security.Cryptography.RandomNumberGenerator]::Fill($salt)
  [System.Security.Cryptography.RandomNumberGenerator]::Fill($iv)
  $key = Derive-Key -Password $Password -Salt $salt -Iter $Iterations
  $plainBytes = [Text.Encoding]::UTF8.GetBytes($Plaintext)
  $cipher = [byte[]]::new($plainBytes.Length)
  $tag    = [byte[]]::new(16)
  $aes = [System.Security.Cryptography.AesGcm]::new($key)
  try { $aes.Encrypt($iv, $plainBytes, $cipher, $tag) }
  finally { $aes.Dispose() }
  $ctWithTag = New-Object byte[] ($cipher.Length + 16)
  [Array]::Copy($cipher, 0, $ctWithTag, 0, $cipher.Length)
  [Array]::Copy($tag, 0, $ctWithTag, $cipher.Length, 16)
  return [ordered]@{
    v          = 1
    kdf        = "PBKDF2"
    iterations = $Iterations
    hash       = "SHA-256"
    alg        = "AES-GCM"
    salt       = [Convert]::ToBase64String($salt)
    iv         = [Convert]::ToBase64String($iv)
    ct         = [Convert]::ToBase64String($ctWithTag)
  }
}

function Decrypt-Envelope {
  param([object]$Envelope, [string]$Password)
  $salt = [Convert]::FromBase64String($Envelope.salt)
  $iv   = [Convert]::FromBase64String($Envelope.iv)
  $ctT  = [Convert]::FromBase64String($Envelope.ct)
  $iter = if ($Envelope.iterations) { [int]$Envelope.iterations } else { $Iterations }
  $cipher = $ctT[0..($ctT.Length - 17)]
  $tag    = $ctT[($ctT.Length - 16)..($ctT.Length - 1)]
  $key = Derive-Key -Password $Password -Salt $salt -Iter $iter
  $plain = [byte[]]::new($cipher.Length)
  $aes = [System.Security.Cryptography.AesGcm]::new($key)
  try { $aes.Decrypt($iv, $cipher, $tag, $plain) }
  finally { $aes.Dispose() }
  return [Text.Encoding]::UTF8.GetString($plain)
}

function Read-Content-FromEditor {
  param([string]$Initial = "")
  $tmp = [IO.Path]::Combine([IO.Path]::GetTempPath(), "journal-$(Get-Random).md")
  $header = "# 본문을 여기에 작성하고 저장 후 메모장을 닫으세요.`r`n# 첫 줄의 이 안내는 자동으로 삭제됩니다.`r`n`r`n"
  [IO.File]::WriteAllText($tmp, $header + $Initial, [Text.UTF8Encoding]::new($false))
  Write-Host "메모장을 엽니다. 내용 작성 후 저장하고 메모장을 닫으세요…" -ForegroundColor Yellow
  Start-Process notepad -ArgumentList $tmp -Wait
  $raw = [IO.File]::ReadAllText($tmp, [Text.UTF8Encoding]::new($false))
  Remove-Item $tmp -Force -ErrorAction SilentlyContinue
  # Strip the header lines (those starting with "# ")
  $lines = $raw -split "`r?`n"
  $cleaned = New-Object System.Collections.Generic.List[string]
  $headerDone = $false
  foreach ($line in $lines) {
    if (-not $headerDone) {
      if ($line -match '^\s*#' -or $line -match '^\s*$') { continue }
      $headerDone = $true
    }
    $cleaned.Add($line)
  }
  return ($cleaned -join "`n").TrimEnd()
}

# ----- Main ------------------------------------------------------------------

if (-not (Test-Path $JournalDir)) { New-Item -ItemType Directory -Path $JournalDir | Out-Null }

# Load existing entries (if any)
$existingEntries = @()
$firstTime = $false
if (Test-Path $EncPath) {
  $envJson = [IO.File]::ReadAllText($EncPath, [Text.UTF8Encoding]::new($false))
  $envelope = $envJson | ConvertFrom-Json
} else {
  $firstTime = $true
}

# Get password
if ($firstTime) {
  Write-Host "📔 첫 사용입니다. 일지 비밀번호를 새로 설정합니다." -ForegroundColor Cyan
  Write-Host "   16자 이상, 추측 어려운 비밀번호를 권장합니다." -ForegroundColor Gray
  Write-Host "   ⚠ 잊어버리면 영구 복구 불가합니다. 비밀번호 매니저에 꼭 저장하세요." -ForegroundColor Yellow
  while ($true) {
    $pw1 = Read-PasswordPlain "새 비밀번호"
    $pw2 = Read-PasswordPlain "비밀번호 확인"
    if ($pw1 -eq $pw2 -and $pw1.Length -ge 8) { break }
    if ($pw1 -ne $pw2) { Write-Host "비밀번호가 일치하지 않습니다. 다시 입력하세요." -ForegroundColor Red }
    elseif ($pw1.Length -lt 8) { Write-Host "비밀번호는 최소 8자 이상이어야 합니다." -ForegroundColor Red }
  }
  $password = $pw1
} else {
  $password = Read-PasswordPlain "일지 비밀번호"
  try {
    $plaintext = Decrypt-Envelope -Envelope $envelope -Password $password
    $obj = $plaintext | ConvertFrom-Json
    $existingEntries = @($obj.entries)
  } catch {
    Write-Host "✗ 복호화 실패. 비밀번호가 틀렸거나 파일이 손상되었습니다." -ForegroundColor Red
    exit 1
  }
}

# List mode: just print summary and exit
if ($List) {
  Write-Host ""
  Write-Host "📔 일지 목록 ($($existingEntries.Count) entries)" -ForegroundColor Cyan
  Write-Host ("-" * 60)
  foreach ($e in ($existingEntries | Sort-Object -Property datetime -Descending)) {
    Write-Host ("{0,-20} {1}" -f $e.datetime, $e.title)
  }
  Write-Host ""
  exit 0
}

# Get content
if (-not $Content -or $Content -eq "") {
  $Content = Read-Content-FromEditor
  if (-not $Content -or $Content.Trim() -eq "") {
    Write-Host "✗ 내용이 비어있습니다. 취소합니다." -ForegroundColor Red
    exit 1
  }
}

# Build new entry
$now = Get-Date -Format "yyyy-MM-ddTHH:mm:sszzz"
$newEntry = [ordered]@{
  id       = "$Date-$([guid]::NewGuid().ToString().Substring(0,8))"
  date     = $Date
  datetime = $now
  title    = $Title
  content  = $Content
}

$allEntries = @($newEntry) + $existingEntries
$payload    = [ordered]@{ entries = $allEntries } | ConvertTo-Json -Depth 10
$envelopeNew = Encrypt-Text -Plaintext $payload -Password $password
$envelopeJson = $envelopeNew | ConvertTo-Json
[IO.File]::WriteAllText($EncPath, $envelopeJson, [Text.UTF8Encoding]::new($false))

Write-Host "✓ 일지 항목 추가됨 → journal/entries.enc ($($allEntries.Count) total)" -ForegroundColor Green

# Self-test: decrypt back to make sure password works
try {
  $verify = Decrypt-Envelope -Envelope ($envelopeJson | ConvertFrom-Json) -Password $password
  $vObj = $verify | ConvertFrom-Json
  if ($vObj.entries[0].title -ne $Title) { throw "verification mismatch" }
  Write-Host "✓ 복호화 검증 통과" -ForegroundColor Green
} catch {
  Write-Host "✗ 복호화 검증 실패! 푸시 전에 확인 필요" -ForegroundColor Red
  exit 1
}

# Git
Push-Location $RepoRoot
try {
  & git add "journal/entries.enc" "journal/index.html" 2>&1 | Out-Null
  $msg = "Journal: $Title ($Date)"
  & git commit -m $msg 2>&1 | Out-Null
  if ($LASTEXITCODE -ne 0) {
    Write-Host "  (commit 변경사항 없음 — entries.enc만 변경됨)" -ForegroundColor Gray
    & git add "journal/entries.enc"
    & git commit -m $msg | Out-Null
  }
  Write-Host "✓ Committed: $msg" -ForegroundColor Green
  if (-not $NoPush) {
    & git push origin main 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "git push failed" }
    Write-Host "✓ Pushed to GitHub" -ForegroundColor Green
  }
} finally {
  Pop-Location
}

Write-Host ""
Write-Host "📔 Journal: https://choryian.github.io/Stock_Report_Repo/journal/" -ForegroundColor Cyan
