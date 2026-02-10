@echo off
chcp 65001 >nul

REM releases 目录独立于 build 目录，避免 flutter clean 清理
set RELEASES_ROOT=c:\Users\Lenovo\Documents\GitHub\StepUp\stepup_app\releases

echo ========================================
echo StepUp综测系统 - 版本管理
echo ========================================
echo.

if not exist "%RELEASES_ROOT%" (
    echo 发行版目录不存在
    pause
    exit /b 1
)

echo 已发布的版本：
echo.

for /d %%i in ("%RELEASES_ROOT%\v*") do (
    set "VERSION_NAME=%%~ni"
    echo 📦 !VERSION_NAME!
    
    if exist "%%i\*.zip" (
        for %%j in ("%%i\*.zip") do (
            set "SIZE=%%~zj"
            set /a "SIZE_MB=!SIZE!/1024/1024"
            echo    📁 %%~nj (约 !SIZE_MB! MB)
        )
    )
    
    if exist "%%i\*\version.json" (
        for /f "tokens=2 delims=:" %%k in ('findstr "description" "%%i\*\version.json" 2^>nul') do (
            set "DESC=%%k"
            set "DESC=!DESC: "=!"
            set "DESC=!DESC:",=!"
            echo    📋 类型：!DESC!
        )
    )
    echo.
)

if exist "%RELEASES_ROOT%\latest.txt" (
    set /p LATEST=<"%RELEASES_ROOT%\latest.txt"
    echo 🔥 最新版本：!LATEST!
) else (
    echo ⚠️  未设置最新版本
)

echo.
echo 当前版本管理架构：
echo 📂 build/releases/
echo    📂 v1.0.0/
echo    📂 v1.0.1/
echo    📂 v1.0.2/
echo    📄 latest.txt
echo.

echo 使用说明：
echo - 构建新版本：package-release.bat [版本号] [描述]
echo - 例如：package-release.bat 1.0.3 "新功能版"
echo.

pause