# 一键发布：Obsidian 笔记库 → content → GitHub → 自动构建上线
#
# 用法：
#   .\publish.ps1                          同步并发布（提交信息自动带时间戳）
#   .\publish.ps1 "补充 Peloton 财务数据"    自定义提交信息
#   .\publish.ps1 -Preview                 只同步 + 本地预览，不发布

param(
    [Parameter(Position = 0)]
    [string]$Message,
    [switch]$Preview
)

# 注意：这里不能用 ErrorActionPreference = "Stop"。
# git / robocopy 会把正常的进度信息写到 stderr，PowerShell 5.1 会把原生命令的
# stderr 当成致命错误抛出，导致明明推送成功却报错。一律改为检查退出码。
$ErrorActionPreference = "Continue"

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $here

function Assert-Ok($what) {
    if ($LASTEXITCODE -ne 0) {
        Write-Host "`n$what 失败（退出码 $LASTEXITCODE）" -ForegroundColor Red
        exit 1
    }
}

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
$changes | ForEach-Object { "  $_" }

if (-not $Message) {
    $Message = "更新笔记 " + (Get-Date -Format "yyyy-MM-dd HH:mm")
}

git add -A
Assert-Ok "git add"

git commit -q -m $Message
Assert-Ok "git commit"

# 3. 推送，GitHub Actions 会自动构建并发布
Write-Host "`n推送到 GitHub..." -ForegroundColor Cyan
git push origin main 2>&1 | ForEach-Object { "  $_" }
if ($LASTEXITCODE -ne 0) {
    Write-Host "`n推送失败（退出码 $LASTEXITCODE）" -ForegroundColor Red
    Write-Host "  连接被重置 → 检查代理是否开着（git 走的是 http.proxy 配置，不是系统代理）"
    Write-Host "  提示认证   → 重新登录 GitHub，或在凭据管理器里删掉旧的 github.com 条目"
    exit 1
}

Write-Host "`n已推送，提交信息：$Message" -ForegroundColor Green
Write-Host "GitHub Actions 正在构建，约 1-2 分钟后生效：" -ForegroundColor Green
Write-Host "  站点  https://lafei5986.github.io/treadmill-wiki/"
Write-Host "  进度  https://github.com/LAFEI5986/treadmill-wiki/actions"
