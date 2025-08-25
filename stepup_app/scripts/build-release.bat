@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

if "%1"=="" (
    echo 使用方法: build-release.bat [版本号] [描述]
    echo 示例: build-release.bat 1.0.3 "新功能版"
    exit /b 1
)

set VERSION=%1
set DESCRIPTION=%2
if "%DESCRIPTION%"=="" set DESCRIPTION=正式版

set PROJECT_ROOT=c:\Users\Lenovo\Documents\GitHub\StepUp\stepup_app
set BUILD_ROOT=%PROJECT_ROOT%\build
set RELEASES_ROOT=%BUILD_ROOT%\releases
set VERSION_DIR=%RELEASES_ROOT%\v%VERSION%

echo ========================================
echo StepUp综测系统版本管理工具
echo ========================================
echo.
echo 构建版本: v%VERSION% (%DESCRIPTION%)
echo.

if exist "%VERSION_DIR%" (
    echo 版本目录已存在，将被覆盖...
    rmdir /s /q "%VERSION_DIR%"
)

mkdir "%VERSION_DIR%" 2>nul

echo 开始构建Windows发行版...
cd /d "%PROJECT_ROOT%"
call flutter build windows --release
if errorlevel 1 (
    echo 构建失败！
    exit /b 1
)
echo 构建完成
echo.

set PACKAGE_NAME=StepUp_v%VERSION%_%DESCRIPTION%
set PACKAGE_DIR=%VERSION_DIR%\%PACKAGE_NAME%
set SOURCE_DIR=%PROJECT_ROOT%\build\windows\x64\runner\Release

echo 创建发行包...
mkdir "%PACKAGE_DIR%"
xcopy "%SOURCE_DIR%\*" "%PACKAGE_DIR%\" /E /I /Q

echo 创建README文件...
(
echo StepUp综测系统 v%VERSION% %DESCRIPTION%
echo ================================================================
echo.
echo 版本信息：
echo - 版本号：v%VERSION%
echo - 版本类型：%DESCRIPTION%
echo - 构建时间：%date% %time%
echo - 目标平台：Windows 10+ ^(64位^)
echo.
echo 安装和运行：
echo 1. 本应用为便携式版本，无需安装
echo 2. 直接双击 stepup_app.exe 启动应用
echo 3. 首次运行会自动创建数据库文件
echo.
echo 主要功能：
echo - 综合测评条目管理
echo - 分类和级别管理
echo - 证明材料上传^(图片和文档^)
echo - 数据统计和分析
echo - 文件预览功能
echo.
echo 技术支持：
echo 如有问题，请联系开发团队
) > "%PACKAGE_DIR%\README.txt"

echo 创建压缩包...
cd /d "%VERSION_DIR%"
powershell -Command "Compress-Archive -Path '%PACKAGE_NAME%' -DestinationPath '%PACKAGE_NAME%.zip' -Force"

echo v%VERSION% > "%RELEASES_ROOT%\latest.txt"

echo.
echo ========================================
echo 发布完成！
echo ========================================
echo 版本：v%VERSION% (%DESCRIPTION%)
echo 发行包路径：%PACKAGE_DIR%
echo 压缩包路径：%VERSION_DIR%\%PACKAGE_NAME%.zip
echo.

pause