@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion

:: 设置项目路径（基于脚本所在位置）
set SCRIPT_DIR=%~dp0
set PROJECT_ROOT=%SCRIPT_DIR%..
set PUBSPEC=%PROJECT_ROOT%\pubspec.yaml

:: 检查 pubspec.yaml 是否存在
if not exist "%PUBSPEC%" (
    echo [错误] 未找到 pubspec.yaml 文件: %PUBSPEC%
    pause
    exit /b 1
)

:: 从 pubspec.yaml 读取版本号
for /f "tokens=2 delims= " %%a in ('findstr "^version:" "%PUBSPEC%"') do (
    set VERSION=%%a
    goto :version_found
)

:version_found
if "%VERSION%"=="" (
    echo [错误] 无法从 pubspec.yaml 读取版本号
    pause
    exit /b 1
)

echo ========================================
echo StepUp综测系统 - 一键构建打包工具
echo ========================================
echo.
echo 从 pubspec.yaml 读取到版本号: v%VERSION%
echo.

:: 获取版本描述
set DESCRIPTION=%1
if "%DESCRIPTION%"=="" set DESCRIPTION=正式版

echo 版本描述: %DESCRIPTION%
echo.

:: 询问是否清理构建缓存
set /p CLEAN_BUILD="是否清理构建缓存 (flutter clean)? (y/N): "

:: 询问用户是否确认
set /p CONFIRM="确认使用版本 v%VERSION% (%DESCRIPTION%) 进行构建打包? (Y/n): "
if /i "%CONFIRM%"=="n" (
    echo 已取消打包
    pause
    exit /b 0
)

cd /d "%PROJECT_ROOT%"

:: 清理构建缓存（如果需要）
if /i "%CLEAN_BUILD%"=="y" (
    echo.
    echo ========================================
    echo 清理构建缓存...
    echo ========================================
    cmd /c flutter clean
    if errorlevel 1 (
        echo [警告] flutter clean 失败，继续构建...
    )
    echo.
    echo ========================================
    echo 获取依赖...
    echo ========================================
    cmd /c flutter pub get
    if errorlevel 1 (
        echo [错误] flutter pub get 失败
        pause
        exit /b 1
    )
)

echo.
echo ========================================
echo 开始构建 Windows 版本...
echo ========================================
echo.

cmd /c flutter build windows --release
if errorlevel 1 (
    echo [错误] Windows 版本构建失败
    pause
    exit /b 1
)

echo.
echo ========================================
echo Windows 构建完成，开始打包...
echo ========================================
echo.

call "%PROJECT_ROOT%\scripts\package-release.bat" %VERSION% "%DESCRIPTION%"
if errorlevel 1 (
    echo [错误] Windows 版本打包失败
    pause
    exit /b 1
)

echo.
echo ========================================
echo 开始构建 Android 版本...
echo ========================================
echo.

cmd /c flutter build apk --release
if errorlevel 1 (
    echo [错误] Android 版本构建失败
    pause
    exit /b 1
)

echo.
echo ========================================
echo Android 构建完成，开始打包...
echo ========================================
echo.

call "%PROJECT_ROOT%\scripts\package-android.bat" %VERSION% "%DESCRIPTION%"
if errorlevel 1 (
    echo [错误] Android 版本打包失败
    pause
    exit /b 1
)

echo.
echo ========================================
echo 构建打包全部完成！
echo ========================================
echo.
echo 版本: v%VERSION% (%DESCRIPTION%)
echo.
echo 发行包位置:
echo - Windows: %PROJECT_ROOT%\releases\windows\v%VERSION%\
echo - Android: %PROJECT_ROOT%\releases\android\v%VERSION%\
echo.
pause
