param([string]$GamePath = "")
# 战争雷霆离线版补丁安装脚本 —— 备份 → 覆盖 → 校验 SHA-256
# 用法: powershell -ExecutionPolicy Bypass -File .\INSTALL.ps1 -GamePath "D:\...\WarThunderOffline"
$ErrorActionPreference = 'Stop'

function Fail($message) { Write-Host "[失败] $message" -ForegroundColor Red; exit 1 }

# 定位游戏目录：参数 > 当前目录 > 脚本上一级
if (-not $GamePath) {
  foreach ($candidate in @((Get-Location).Path, (Split-Path -Parent $PSScriptRoot), $PSScriptRoot)) {
    if (Test-Path -LiteralPath (Join-Path $candidate 'WarThunderOffline.exe')) { $GamePath = $candidate; break }
  }
}
if (-not $GamePath -or -not (Test-Path -LiteralPath (Join-Path $GamePath 'WarThunderOffline.exe'))) {
  Fail "找不到离线版目录。请用 -GamePath 指定，例如 -GamePath 'D:\GameApp\WarThunderOffline'"
}
$GamePath = (Resolve-Path -LiteralPath $GamePath).Path
Write-Host "游戏目录: $GamePath"

if (Get-Process aces -ErrorAction SilentlyContinue) { Fail '游戏正在运行，请先完全退出 WarThunderOffline.exe' }

$sourceRoot = Join-Path $PSScriptRoot 'files'
$manifestPath = Join-Path $PSScriptRoot 'patch-manifest.json'
if (-not (Test-Path -LiteralPath $sourceRoot)) { Fail '补丁包不完整：缺少 files 目录（请先解压压缩包）' }
if (-not (Test-Path -LiteralPath $manifestPath)) { Fail '补丁包不完整：缺少 patch-manifest.json' }
$manifest = Get-Content -Raw -LiteralPath $manifestPath | ConvertFrom-Json

# 1) 先校验补丁包本身，避免复制到一半发现文件坏了
Write-Host '校验补丁包...'
foreach ($rel in $manifest.PSObject.Properties.Name) {
  $src = Join-Path $sourceRoot ($rel -replace '/', '\')
  if (-not (Test-Path -LiteralPath $src)) { Fail "补丁包缺少文件: $rel" }
  $hash = (Get-FileHash -LiteralPath $src -Algorithm SHA256).Hash.ToLower()
  if ($hash -ne $manifest.$rel) { Fail "补丁文件校验失败（可能下载不完整）: $rel" }
}
Write-Host "  7 个文件全部通过"

# 2) 备份将被覆盖的文件
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$backupRoot = Join-Path $GamePath "patch-backup-$stamp"
Write-Host "备份到: $backupRoot"
foreach ($rel in $manifest.PSObject.Properties.Name) {
  $dst = Join-Path $GamePath ($rel -replace '/', '\')
  if (Test-Path -LiteralPath $dst) {
    $backup = Join-Path $backupRoot ($rel -replace '/', '\')
    New-Item -ItemType Directory -Path (Split-Path -Parent $backup) -Force | Out-Null
    Copy-Item -LiteralPath $dst -Destination $backup -Force
  }
}
$backupMeta = Join-Path $backupRoot 'backup-info.txt'
New-Item -ItemType Directory -Path $backupRoot -Force | Out-Null
"补丁安装时间: $stamp`n游戏目录: $GamePath" | Set-Content -LiteralPath $backupMeta -Encoding UTF8

# 3) 复制并逐个校验
Write-Host '写入文件...'
foreach ($rel in $manifest.PSObject.Properties.Name) {
  $src = Join-Path $sourceRoot ($rel -replace '/', '\')
  $dst = Join-Path $GamePath ($rel -replace '/', '\')
  New-Item -ItemType Directory -Path (Split-Path -Parent $dst) -Force | Out-Null
  Copy-Item -LiteralPath $src -Destination $dst -Force
  $hash = (Get-FileHash -LiteralPath $dst -Algorithm SHA256).Hash.ToLower()
  if ($hash -ne $manifest.$rel) { Fail "写入后校验失败: $rel（请从 $backupRoot 还原后重试）" }
  Write-Host "  OK  $rel"
}

Write-Host ''
Write-Host "安装完成。备份目录: $backupRoot" -ForegroundColor Green
Write-Host '现在可以启动 WarThunderOffline.exe（需要管理员权限）。'
Write-Host "如需回滚: powershell -ExecutionPolicy Bypass -File .\UNINSTALL.ps1 -GamePath `"$GamePath`""
