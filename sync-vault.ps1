# 把 Obsidian 笔记库同步到 Quartz 的 content 目录，然后构建。
# 用法：
#   .\sync-vault.ps1            同步 + 构建
#   .\sync-vault.ps1 -Serve     同步 + 构建 + 本地预览 (http://localhost:8080)
#   .\sync-vault.ps1 -NoBuild   只同步

param(
    [string]$Vault = "C:\hermes-web-ui\hermes_data\Desktop\米粒\跑步机行业研究",
    [switch]$Serve,
    [switch]$NoBuild
)

# git/robocopy 的进度信息走 stderr，PS 5.1 会误判为致命错误，故不用 Stop$([char]10)$ErrorActionPreference = "Continue"
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$content = Join-Path $here "content"

if (-not (Test-Path $Vault)) {
    Write-Error "找不到笔记库：$Vault"
}

Write-Host "同步 $Vault  →  $content" -ForegroundColor Cyan

# /MIR 镜像同步：vault 里删掉的笔记，content 里也会删掉。
# 排除 Obsidian 自己的配置目录和工作区文件。
robocopy $Vault $content /MIR /XD ".obsidian" ".trash" /XF "*.tmp" "~*" /NFL /NDL /NJH /NJS /NP | Out-Null

# robocopy 的退出码 0-7 都算成功，8 及以上才是真失败
if ($LASTEXITCODE -ge 8) {
    Write-Error "robocopy 同步失败，退出码 $LASTEXITCODE"
}
$LASTEXITCODE = 0

$count = (Get-ChildItem $content -Filter *.md -Recurse -File).Count
Write-Host "已同步 $count 篇笔记" -ForegroundColor Green

if ($NoBuild) { return }

Push-Location $here
try {
    if ($Serve) {
        npx quartz build --serve
    } else {
        npx quartz build
    }
} finally {
    Pop-Location
}
