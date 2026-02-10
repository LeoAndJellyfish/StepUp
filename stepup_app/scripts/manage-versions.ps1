# StepUp版本管理辅助工具
# 功能：查看、比较和管理版本

param(
    [Parameter(Mandatory=$false)]
    [string]$Action = "list",
    
    [Parameter(Mandatory=$false)]
    [string]$Version = ""
)

# releases 目录独立于 build 目录，避免 flutter clean 清理
$ReleasesRoot = "c:\Users\Lenovo\Documents\GitHub\StepUp\stepup_app\releases"

function Write-ColorText {
    param([string]$Text, [string]$Color = "White")
    Write-Host $Text -ForegroundColor $Color
}

function Show-AllVersions {
    Write-ColorText "StepUp综测系统 - 版本列表" "Cyan"
    Write-ColorText "=========================" "Cyan"
    
    if (-not (Test-Path $ReleasesRoot)) {
        Write-ColorText "发行版目录不存在" "Red"
        return
    }
    
    $versions = Get-ChildItem $ReleasesRoot -Directory | Where-Object { $_.Name -match '^v\d+\.\d+\.\d+$' } | Sort-Object Name
    
    if ($versions.Count -eq 0) {
        Write-ColorText "未找到任何版本" "Yellow"
        return
    }
    
    # 获取最新版本
    $latestFile = "$ReleasesRoot\latest.txt"
    $latest = if (Test-Path $latestFile) { Get-Content $latestFile } else { "" }
    
    foreach ($version in $versions) {
        $versionName = $version.Name
        $isLatest = if ($versionName -eq $latest) { " [最新]" } else { "" }
        
        Write-ColorText "📦 $versionName$isLatest" "Green"
        
        # 读取版本信息
        $versionFile = "$($version.FullName)\StepUp_$($versionName)_*\version.json"
        $versionFiles = Get-ChildItem $versionFile -ErrorAction SilentlyContinue
        
        if ($versionFiles.Count -gt 0) {
            $versionInfo = Get-Content $versionFiles[0].FullName | ConvertFrom-Json
            Write-ColorText "   类型：$($versionInfo.description)" "Gray"
            Write-ColorText "   构建时间：$($versionInfo.buildTime)" "Gray"
            Write-ColorText "   平台：$($versionInfo.platform)" "Gray"
        }
        
        # 显示包含的文件
        $packages = Get-ChildItem $version.FullName -Directory
        $zipFiles = Get-ChildItem $version.FullName -File -Filter "*.zip"
        
        foreach ($package in $packages) {
            $size = (Get-ChildItem $package.FullName -Recurse | Measure-Object -Property Length -Sum).Sum / 1MB
            Write-ColorText "   📁 $($package.Name) ($([math]::Round($size, 2)) MB)" "White"
        }
        
        foreach ($zip in $zipFiles) {
            $size = $zip.Length / 1MB
            Write-ColorText "   📦 $($zip.Name) ($([math]::Round($size, 2)) MB)" "White"
        }
        
        Write-Host ""
    }
}

function Show-VersionDetails {
    param([string]$Version)
    
    $versionDir = "$ReleasesRoot\v$Version"
    
    if (-not (Test-Path $versionDir)) {
        Write-ColorText "版本 v$Version 不存在" "Red"
        return
    }
    
    Write-ColorText "版本详情：v$Version" "Cyan"
    Write-ColorText "================" "Cyan"
    
    # 显示版本信息
    $versionFiles = Get-ChildItem "$versionDir\*\version.json" -ErrorAction SilentlyContinue
    if ($versionFiles.Count -gt 0) {
        $versionInfo = Get-Content $versionFiles[0].FullName | ConvertFrom-Json
        Write-ColorText "类型：$($versionInfo.description)" "White"
        Write-ColorText "构建时间：$($versionInfo.buildTime)" "White"
        Write-ColorText "平台：$($versionInfo.platform)" "White"
        Write-ColorText "构建ID：$($versionInfo.buildId)" "White"
        Write-Host ""
    }
    
    # 显示文件结构
    Write-ColorText "文件结构：" "Yellow"
    Get-ChildItem $versionDir -Recurse | ForEach-Object {
        $relativePath = $_.FullName.Substring($versionDir.Length + 1)
        $indent = "  " * ($relativePath.Split('\').Count - 1)
        
        if ($_.PSIsContainer) {
            Write-ColorText "$indent📁 $($_.Name)/" "Cyan"
        } else {
            $size = if ($_.Length -gt 1MB) { 
                "$([math]::Round($_.Length / 1MB, 2)) MB" 
            } else { 
                "$([math]::Round($_.Length / 1KB, 1)) KB" 
            }
            Write-ColorText "$indent📄 $($_.Name) ($size)" "Gray"
        }
    }
}

function Clean-OldVersions {
    param([int]$KeepCount = 3)
    
    Write-ColorText "清理旧版本（保留最新 $KeepCount 个版本）" "Yellow"
    
    $versions = Get-ChildItem $ReleasesRoot -Directory | Where-Object { $_.Name -match '^v\d+\.\d+\.\d+$' } | Sort-Object Name -Descending
    
    if ($versions.Count -le $KeepCount) {
        Write-ColorText "版本数量不超过保留数量，无需清理" "Green"
        return
    }
    
    $toDelete = $versions | Select-Object -Skip $KeepCount
    $archiveDir = "c:\Users\Lenovo\Documents\GitHub\StepUp\stepup_app\build\archive"
    
    foreach ($version in $toDelete) {
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $archivePath = "$archiveDir\$($version.Name)_$timestamp"
        
        Write-ColorText "归档版本：$($version.Name) -> $archivePath" "Yellow"
        Move-Item $version.FullName $archivePath -Force
    }
    
    Write-ColorText "✓ 清理完成" "Green"
}

function Show-Usage {
    Write-ColorText "StepUp版本管理工具使用说明" "Cyan"
    Write-ColorText "=========================" "Cyan"
    Write-Host ""
    Write-ColorText "查看所有版本：" "Yellow"
    Write-ColorText "  .\manage-versions.ps1 -Action list" "Gray"
    Write-Host ""
    Write-ColorText "查看特定版本详情：" "Yellow"
    Write-ColorText "  .\manage-versions.ps1 -Action details -Version 1.0.2" "Gray"
    Write-Host ""
    Write-ColorText "清理旧版本：" "Yellow"
    Write-ColorText "  .\manage-versions.ps1 -Action clean" "Gray"
    Write-Host ""
    Write-ColorText "构建新版本：" "Yellow"
    Write-ColorText "  .\build-release.ps1 -Version 1.0.3 -Description '新功能版'" "Gray"
    Write-Host ""
}

# 主逻辑
switch ($Action.ToLower()) {
    "list" { Show-AllVersions }
    "details" { 
        if ($Version -eq "") {
            Write-ColorText "请指定版本号" "Red"
            Show-Usage
        } else {
            Show-VersionDetails -Version $Version
        }
    }
    "clean" { Clean-OldVersions }
    "help" { Show-Usage }
    default { 
        Write-ColorText "未知操作：$Action" "Red"
        Show-Usage 
    }
}