# 一键发布：Obsidian 笔记库 → content → GitHub → 自动构建上线
#
# 用法：
#   .\publish.ps1                    同步并发布（提交信息自动带时间戳）
#   .\publish.ps1 "补充 Peloton 财务数据"   自定义提交信息
#   .\publish.ps1 -Preview           只同步 + 本地预览，不发布

param(
    [Parameter(Position = 0)]
    [string]$Message,
    [switch]$Preview
)

$ErrorActionPreference = "Stop"
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $here

# 1. 把笔记库同步到 content
& "$here\sync-vault.ps1" -NoBuild

if ($Preview) {
    Write-Host "`n本地预览：http://localhost:8080  (Ctrl+C 结束)" -ForegroundColor Cyan
    npx quartz build --serve
    return
}

# 2. 有变化才提交
$changes = git status --porcelain
if (-not $changes) {
    Write-Host "`n笔记没有变化，无需发布。" -ForegroundColor Yellow
    return
}

Write-Host "`n本次变更：" -ForegroundColor Cyan
git status --short

if (-not $Message) {
    $Message = "更新笔记 " + (Get-Date -Format "yyyy-MM-dd HH:mm")
}

git add -A
git commit -q -m $Message
if ($LASTEXITCODE -ne 0) { Write-Error "提交失败" }

# 3. 推送，GitHub Actions 会自动构建并发布
Write-Host "`n推送到 GitHub..." -ForegroundColor Cyan
git push origin main
if ($LASTEXITCODE -ne 0) {
    Write-Error "推送失败。若提示连接被重置，检查代理是否开着；若提示认证，重新登录 GitHub。"
}

Write-Host "`n已推送。GitHub Actions 正在构建，约 1-2 分钟后生效：" -ForegroundColor Green
Write-Host "  站点  https://lafei5986.github.io/treadmill-wiki/"
Write-Host "  进度  https://github.com/LAFEI5986/treadmill-wiki/actions"
