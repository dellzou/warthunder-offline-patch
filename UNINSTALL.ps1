param([string]$GamePath = "", [string]$BackupDir = "")
# 从最近一次安装的备份还原补丁覆盖的文件
$ErrorActionPreference = 'Stop'

function Fail($message) { Write-Host "[失败] $message" -ForegroundColor Red; exit 1 }

if (-not $GamePath) {
  foreach ($candidate in @((Get-Location).Path, (Split-Path -Parent $PSScriptRoot), $PSScriptRoot)) {
    if (Test-Path -LiteralPath (Join-Path $candidate 'WarThunderOffline.exe')) { $GamePath = $candidate; break }
  }
}
if (-not $GamePath -or -not (Test-Path -LiteralPath (Join-Path $GamePath 'WarThunderOffline.exe'))) {
  Fail "找不到离线版目录，请用 -GamePath 指定"
}
$GamePath = (Resolve-Path -LiteralPath $GamePath).Path
if (Get-Process aces -ErrorAction SilentlyContinue) { Fail '游戏正在运行，请先完全退出' }

if (-not $BackupDir) {
  $latest = Get-ChildItem -LiteralPath $GamePath -Directory -Filter 'patch-backup-*' -ErrorAction SilentlyContinue |
    Sort-Object Name -Descending | Select-Object -First 1
  if (-not $latest) { Fail "在 $GamePath 下找不到 patch-backup-* 备份目录" }
  $BackupDir = $latest.FullName
}
Write-Host "从备份还原: $BackupDir"

$restored = 0
foreach ($file in (Get-ChildItem -LiteralPath $BackupDir -Recurse -File)) {
  $rel = $file.FullName.Substring($BackupDir.Length).TrimStart('\')
  if ($rel -eq 'backup-info.txt') { continue }
  $dst = Join-Path $GamePath $rel
  New-Item -ItemType Directory -Path (Split-Path -Parent $dst) -Force | Out-Null
  Copy-Item -LiteralPath $file.FullName -Destination $dst -Force
  Write-Host "  还原 $rel"
  $restored++
}
Write-Host ''
Write-Host "已还原 $restored 个文件。" -ForegroundColor Green
