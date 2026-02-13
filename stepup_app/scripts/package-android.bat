@echo off
chcp 65001 >nul

if "%1"=="" (
    echo 使用方法: package-android.bat [版本号] [描述]
    echo 示例: package-android.bat 1.0.3 "正式版"
    pause
    exit /b 1
)

set VERSION=%1
set DESCRIPTION=%2
if "%DESCRIPTION%"=="" set DESCRIPTION=正式版

:: 设置项目路径（基于脚本所在位置）
set SCRIPT_DIR=%~dp0
set PROJECT_ROOT=%SCRIPT_DIR%..
set BUILD_ROOT=%PROJECT_ROOT%\build
REM releases 目录独立于 build 目录，避免 flutter clean 清理
set RELEASES_ROOT=%PROJECT_ROOT%\releases\android
set VERSION_DIR=%RELEASES_ROOT%\v%VERSION%

set APK_SOURCE=%PROJECT_ROOT%\build\app\outputs\flutter-apk\app-release.apk

echo ========================================
echo StepUp综测系统 Android 版本管理工具
echo ========================================
echo.
echo 构建版本: v%VERSION% (%DESCRIPTION%)
echo.

REM 检查 APK 文件是否存在
if not exist "%APK_SOURCE%" (
    echo [错误] 未找到 APK 文件: %APK_SOURCE%
    echo.
    echo 请先构建 Android 应用:
    echo   flutter build apk --release
echo.
    pause
    exit /b 1
)

if exist "%VERSION_DIR%" (
    echo 版本目录已存在，将被覆盖...
    rmdir /s /q "%VERSION_DIR%"
)

mkdir "%VERSION_DIR%" 2>nul

set PACKAGE_NAME=StepUp_v%VERSION%_%DESCRIPTION%
set PACKAGE_DIR=%VERSION_DIR%\%PACKAGE_NAME%

echo 创建发行包...
mkdir "%PACKAGE_DIR%"

REM 复制 APK 文件
copy "%APK_SOURCE%" "%PACKAGE_DIR%\app-release.apk" >nul
echo   ✓ 复制 APK 文件

echo 创建README文件...
echo StepUp综测系统 Android版 v%VERSION% %DESCRIPTION% > "%PACKAGE_DIR%\README.txt"
echo ================================================================ >> "%PACKAGE_DIR%\README.txt"
echo. >> "%PACKAGE_DIR%\README.txt"
echo 版本信息： >> "%PACKAGE_DIR%\README.txt"
echo - 版本号：v%VERSION% >> "%PACKAGE_DIR%\README.txt"
echo - 版本类型：%DESCRIPTION% >> "%PACKAGE_DIR%\README.txt"
echo - 构建时间：%date% %time% >> "%PACKAGE_DIR%\README.txt"
echo - 目标平台：Android 5.0+ ^(API 21+^) >> "%PACKAGE_DIR%\README.txt"
echo - 安装包：app-release.apk >> "%PACKAGE_DIR%\README.txt"
echo. >> "%PACKAGE_DIR%\README.txt"
echo 安装说明： >> "%PACKAGE_DIR%\README.txt"
echo 1. 在 Android 设备上启用"允许安装未知来源应用" >> "%PACKAGE_DIR%\README.txt"
echo    - 设置 ^> 安全 ^> 允许安装未知来源应用 >> "%PACKAGE_DIR%\README.txt"
echo    - 或设置 ^> 应用 ^> 特殊应用权限 ^> 安装未知应用 >> "%PACKAGE_DIR%\README.txt"
echo. >> "%PACKAGE_DIR%\README.txt"
echo 2. 将 app-release.apk 传输到 Android 设备 >> "%PACKAGE_DIR%\README.txt"
echo    - 通过 USB 连接电脑传输 >> "%PACKAGE_DIR%\README.txt"
echo    - 或通过邮件/微信/QQ 发送到手机 >> "%PACKAGE_DIR%\README.txt"
echo    - 或通过网络传输工具 >> "%PACKAGE_DIR%\README.txt"
echo. >> "%PACKAGE_DIR%\README.txt"
echo 3. 在设备上找到 APK 文件并点击安装 >> "%PACKAGE_DIR%\README.txt"
echo    - 使用文件管理器找到 APK 文件 >> "%PACKAGE_DIR%\README.txt"
echo    - 点击安装，按提示完成安装 >> "%PACKAGE_DIR%\README.txt"
echo. >> "%PACKAGE_DIR%\README.txt"
echo 4. 安装完成后，在应用列表中找到"StepUp综测系统"启动 >> "%PACKAGE_DIR%\README.txt"
echo. >> "%PACKAGE_DIR%\README.txt"
echo 主要功能： >> "%PACKAGE_DIR%\README.txt"
echo - 综合测评条目管理 >> "%PACKAGE_DIR%\README.txt"
echo - 分类和级别管理 >> "%PACKAGE_DIR%\README.txt"
echo - 证明材料上传^(图片和文档^) >> "%PACKAGE_DIR%\README.txt"
echo - 数据统计和分析 >> "%PACKAGE_DIR%\README.txt"
echo - 文件预览功能 >> "%PACKAGE_DIR%\README.txt"
echo. >> "%PACKAGE_DIR%\README.txt"
echo 数据存储： >> "%PACKAGE_DIR%\README.txt"
echo - 数据库：应用私有目录，随应用卸载删除 >> "%PACKAGE_DIR%\README.txt"
echo - 证明材料：应用私有目录，随应用卸载删除 >> "%PACKAGE_DIR%\README.txt"
echo - 建议定期使用应用内备份功能导出数据 >> "%PACKAGE_DIR%\README.txt"
echo. >> "%PACKAGE_DIR%\README.txt"
echo 权限说明： >> "%PACKAGE_DIR%\README.txt"
echo - 存储权限：用于上传和保存证明材料 >> "%PACKAGE_DIR%\README.txt"
echo - 相机权限：用于拍照上传证明材料 >> "%PACKAGE_DIR%\README.txt"
echo - 网络权限：用于坚果云备份功能 >> "%PACKAGE_DIR%\README.txt"
echo. >> "%PACKAGE_DIR%\README.txt"
echo 技术支持： >> "%PACKAGE_DIR%\README.txt"
echo 如有问题，请联系开发团队 >> "%PACKAGE_DIR%\README.txt"
echo. >> "%PACKAGE_DIR%\README.txt"
echo ================================================================ >> "%PACKAGE_DIR%\README.txt"
echo 注意：本应用为内部使用工具，请勿随意传播 >> "%PACKAGE_DIR%\README.txt"
echo ================================================================ >> "%PACKAGE_DIR%\README.txt"
echo   ✓ 创建 README.txt

echo 创建版本信息文件...
echo { > "%PACKAGE_DIR%\version.json"
echo   "version": "%VERSION%", >> "%PACKAGE_DIR%\version.json"
echo   "description": "%DESCRIPTION%", >> "%PACKAGE_DIR%\version.json"
echo   "buildTime": "%date% %time%", >> "%PACKAGE_DIR%\version.json"
echo   "platform": "Android", >> "%PACKAGE_DIR%\version.json"
echo   "buildId": "%date:~0,4%%date:~5,2%%date:~8,2%_%time:~0,2%%time:~3,2%%time:~6,2%", >> "%PACKAGE_DIR%\version.json"
echo   "minSdkVersion": "21", >> "%PACKAGE_DIR%\version.json"
echo   "targetSdkVersion": "34", >> "%PACKAGE_DIR%\version.json"
echo   "apkFile": "app-release.apk" >> "%PACKAGE_DIR%\version.json"
echo } >> "%PACKAGE_DIR%\version.json"
echo   ✓ 创建 version.json

echo 创建压缩包...
cd /d "%VERSION_DIR%"
:: 使用 PowerShell 变量来避免引号问题
powershell -Command "$name='%PACKAGE_NAME%'; Compress-Archive -Path $name -DestinationPath \"$name.zip\" -Force"
echo   ✓ 创建 %PACKAGE_NAME%.zip

echo v%VERSION% > "%RELEASES_ROOT%\latest.txt"
echo   ✓ 更新 latest.txt

echo.
echo ========================================
echo Android 发布完成！
echo ========================================
echo 版本：v%VERSION% (%DESCRIPTION%)
echo 发行包路径：%PACKAGE_DIR%
echo 压缩包路径：%VERSION_DIR%\%PACKAGE_NAME%.zip
echo APK 文件：%PACKAGE_DIR%\app-release.apk
echo.
