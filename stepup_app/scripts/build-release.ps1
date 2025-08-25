# StepUp版本管理脚本
param(
    [Parameter(Mandatory=$true)]
    [string]$Version,
    
    [Parameter(Mandatory=$false)]
    [string]$Description = "正式版",
    
    [Parameter(Mandatory=$false)]
    [switch]$Clean = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipBuild = $false
)

function Write-ColorText {
    param([string]$Text, [string]$Color = "White")
    Write-Host $Text -ForegroundColor $Color
}

function Test-VersionFormat {
    param([string]$Version)
    return $Version -match '^\d+\.\d+\.\d+$'
}

Write-ColorText "========================================" "Cyan"
Write-ColorText "StepUp综测系统版本管理工具" "Cyan"
Write-ColorText "========================================" "Cyan"
Write-Host ""

if (-not (Test-VersionFormat -Version $Version)) {
    Write-ColorText "错误：版本号格式不正确，请使用 x.y.z 格式" "Red"
    exit 1
}

$ProjectRoot = "c:\Users\Lenovo\Documents\GitHub\StepUp\stepup_app"
$BuildRoot = "$ProjectRoot\build"
$ReleasesRoot = "$BuildRoot\releases"
$VersionDir = "$ReleasesRoot\v$Version"

Write-ColorText "构建版本：v$Version ($Description)" "Green"
Write-Host ""

if (Test-Path $VersionDir) {
    $overwrite = Read-Host "版本 v$Version 已存在，是否覆盖？(y/N)"
    if ($overwrite -ne "y" -and $overwrite -ne "Y") {
        Write-ColorText "操作已取消" "Yellow"
        exit 0
    }
    Remove-Item $VersionDir -Recurse -Force
}

New-Item -ItemType Directory -Path $VersionDir -Force | Out-Null
Write-ColorText "已创建版本目录：$VersionDir" "Green"

if ($Clean) {
    Write-ColorText "清理构建缓存..." "Yellow"
    Set-Location $ProjectRoot
    flutter clean
    Write-ColorText "构建缓存已清理" "Green"
}

if (-not $SkipBuild) {
    Write-ColorText "开始构建Windows发行版..." "Yellow"
    Set-Location $ProjectRoot
    
    flutter build windows --release
    if ($LASTEXITCODE -ne 0) {
        Write-ColorText "构建失败！" "Red"
        exit 1
    }
    Write-ColorText "构建完成" "Green"
}

$PackageName = "StepUp_v${Version}_${Description}"
$PackageDir = "$VersionDir\$PackageName"
$SourceDir = "$ProjectRoot\build\windows\x64\runner\Release"

Write-ColorText "创建发行包..." "Yellow"

New-Item -ItemType Directory -Path $PackageDir -Force | Out-Null
Copy-Item "$SourceDir\*" $PackageDir -Recurse -Force

Write-ColorText "文件已复制到：$PackageDir" "Green"

$readmeContent = @"
StepUp综合测评系统 v$Version $Description
================================================================

版本信息：
- 版本号：v$Version
- 版本类型：$Description
- 构建时间：$(Get-Date -Format 'yyyy年MM月dd日 HH:mm:ss')
- 目标平台：Windows 10+ (64位)

安装和运行：
1. 本应用为便携式版本，无需安装
2. 直接双击 stepup_app.exe 启动应用
3. 首次运行会自动创建数据库文件

主要功能：
- 综合测评条目管理
- 分类和级别管理
- 证明材料上传（图片和文档）
- 数据统计和分析
- 文件预览功能

技术支持：
如有问题，请联系开发团队

发布信息：
- 版本：v$Version $Description
- 发布日期：$(Get-Date -Format 'yyyy年MM月dd日')
"@

$readmeContent | Out-File -FilePath "$PackageDir\README.txt" -Encoding UTF8
Write-ColorText "已创建README文件" "Green"

$versionInfo = @{
    version = $Version
    description = $Description
    buildTime = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    platform = "Windows x64"
    buildId = Get-Date -Format 'yyyyMMddHHmmss'
} | ConvertTo-Json -Depth 2

$versionInfo | Out-File -FilePath "$PackageDir\version.json" -Encoding UTF8
Write-ColorText "已创建版本信息文件" "Green"

Write-ColorText "创建压缩包..." "Yellow"
$zipPath = "$VersionDir\${PackageName}.zip"
Compress-Archive -Path $PackageDir -DestinationPath $zipPath -Force
Write-ColorText "压缩包已创建：$zipPath" "Green"

$packageSize = (Get-ChildItem $PackageDir -Recurse | Measure-Object -Property Length -Sum).Sum / 1MB
$zipSize = (Get-Item $zipPath).Length / 1MB

"v$Version" | Out-File -FilePath "$ReleasesRoot\latest.txt" -Encoding UTF8 -NoNewline
Write-ColorText "已更新最新版本指向：v$Version" "Green"

Write-Host ""
Write-ColorText "========================================" "Cyan"
Write-ColorText "发布完成！" "Green"
Write-ColorText "========================================" "Cyan"
Write-ColorText "版本：v$Version ($Description)" "White"
Write-ColorText "发行包大小：$([math]::Round($packageSize, 2)) MB" "White"
Write-ColorText "压缩包大小：$([math]::Round($zipSize, 2)) MB" "White"
Write-ColorText "发行包路径：$PackageDir" "White"
Write-ColorText "压缩包路径：$zipPath" "White"