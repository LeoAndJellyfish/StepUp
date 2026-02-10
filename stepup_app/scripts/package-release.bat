@echo off
chcp 65001 >nul

if "%1"=="" (
    echo 使用方法: package-release.bat [版本号] [描述]
    echo 示例: package-release.bat 1.0.3 "新功能版"
    pause
    exit /b 1
)

set VERSION=%1
set DESCRIPTION=%2
if "%DESCRIPTION%"=="" set DESCRIPTION=正式版

set PROJECT_ROOT=c:\Users\Lenovo\Documents\GitHub\StepUp\stepup_app
set BUILD_ROOT=%PROJECT_ROOT%\build
REM releases 目录独立于 build 目录，避免 flutter clean 清理
set RELEASES_ROOT=%PROJECT_ROOT%\releases\windows
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

set PACKAGE_NAME=StepUp_v%VERSION%_%DESCRIPTION%
set PACKAGE_DIR=%VERSION_DIR%\%PACKAGE_NAME%
set SOURCE_DIR=%PROJECT_ROOT%\build\windows\x64\runner\Release

echo 创建发行包...
mkdir "%PACKAGE_DIR%"
xcopy "%SOURCE_DIR%\*" "%PACKAGE_DIR%\" /E /I /Q /Y

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
echo - 外部应用打开文件
echo.
echo 文件存储：
echo - 数据库文件：应用目录下自动创建
echo - 证明材料：应用目录\data\proof_materials\
echo - 配置文件：应用目录下自动创建
echo.
echo 技术支持：
echo 如有问题，请联系开发团队
) > "%PACKAGE_DIR%\README.txt"

echo 创建版本信息文件...
(
echo {
echo   "version": "%VERSION%",
echo   "description": "%DESCRIPTION%",
echo   "buildTime": "%date% %time%",
echo   "platform": "Windows x64",
echo   "buildId": "%date:~0,4%%date:~5,2%%date:~8,2%_%time:~0,2%%time:~3,2%%time:~6,2%"
echo }
) > "%PACKAGE_DIR%\version.json"

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

dir "%VERSION_DIR%" /B

echo.
echo 版本管理完成！按任意键退出...
pause >nul