#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
StepUp 打包脚本
用法: python package.py [版本号] [--platforms=windows,android,macos,linux,web]
示例: python package.py 1.2.5
       python package.py 1.2.5 --platforms=macos
       python package.py 1.2.5 --platforms=windows,android,macos
"""

import sys
import os
import re
import shutil
import subprocess
import zipfile
import platform as sys_platform
import argparse
from pathlib import Path


def print_header(title):
    print("=" * 50)
    print(f"  {title}")
    print("=" * 50)
    print()


def print_section(title):
    print("=" * 50)
    print(f"  {title}")
    print("=" * 50)
    print()


def validate_version(version):
    """验证版本号格式"""
    pattern = r"^\d+\.\d+\.\d+$"
    return re.match(pattern, version) is not None


def update_setup_iss_version(project_root, version):
    """更新 setup.iss 版本号"""
    setup_iss_path = project_root / "installer" / "setup.iss"
    if not setup_iss_path.exists():
        return False

    content = setup_iss_path.read_text(encoding="utf-8")
    content = re.sub(
        r'(#define MyAppVersion ")([^"]+)(")',
        f'#define MyAppVersion "{version}"',
        content
    )
    setup_iss_path.write_text(content, encoding="utf-8")
    return True


def create_zip_archive(source_dir, output_path):
    """创建 ZIP 压缩包"""
    with zipfile.ZipFile(output_path, 'w', zipfile.ZIP_DEFLATED) as zipf:
        for root, dirs, files in os.walk(source_dir):
            for file in files:
                file_path = Path(root) / file
                arcname = file_path.relative_to(source_dir.parent)
                zipf.write(file_path, arcname)


def package_windows(project_root, version_dir, version):
    """打包 Windows 便携版"""
    print_section("打包 Windows 便携版")

    win_source = project_root / "build" / "windows" / "x64" / "runner" / "Release"
    package_name = f"StepUp_v{version}_windows_portable"
    package_dir = version_dir / package_name

    if not (win_source / "stepup_app.exe").exists():
        print("[错误] 未找到 Windows 构建文件！")
        print(f"       请先运行: python build.py {version}")
        return False

    # 复制文件
    print("[1/2] 复制文件...")
    if package_dir.exists():
        shutil.rmtree(package_dir)
    shutil.copytree(win_source, package_dir)
    print("      文件复制完成")

    # 创建压缩包
    print("[2/2] 创建压缩包...")
    zip_path = version_dir / f"{package_name}.zip"
    create_zip_archive(package_dir, zip_path)
    print(f"      压缩包创建完成: {package_name}.zip")

    # 清理临时目录
    shutil.rmtree(package_dir)
    print()
    return True


def package_macos(project_root, version_dir, version):
    """打包 macOS 版本"""
    print_section("打包 macOS 版本")

    # 检查是否在 macOS 上运行
    if sys_platform.system() != "Darwin":
        print("[跳过] macOS 打包需要在 macOS 系统上运行")
        return True

    macos_source = project_root / "build" / "macos" / "Build" / "Products" / "Release"
    app_name = "StepUp.app"
    package_name = f"StepUp_v{version}_macos"
    package_dir = version_dir / package_name

    if not (macos_source / app_name).exists():
        print("[错误] 未找到 macOS 构建文件！")
        print(f"       请先运行: python build.py {version}")
        return False

    # 复制文件
    print("[1/3] 复制文件...")
    if package_dir.exists():
        shutil.rmtree(package_dir)
    package_dir.mkdir(parents=True, exist_ok=True)
    shutil.copytree(macos_source / app_name, package_dir / app_name)
    print("      文件复制完成")

    # 创建 Applications 快捷方式（符号链接）
    print("[2/3] 创建 Applications 快捷方式...")
    try:
        os.symlink("/Applications", package_dir / "Applications", target_is_directory=True)
        print("      快捷方式创建完成")
    except OSError:
        print("      [警告] 无法创建 Applications 快捷方式")

    # 创建 DMG 或 ZIP 压缩包
    print("[3/3] 创建压缩包...")
    
    # 尝试创建 DMG（如果可用）
    dmg_path = version_dir / f"{package_name}.dmg"
    zip_path = version_dir / f"{package_name}.zip"
    
    # 检查是否有 create-dmg 工具
    result = subprocess.run(
        ["which", "create-dmg"],
        capture_output=True,
        text=True
    )
    
    if result.returncode == 0:
        # 使用 create-dmg 创建 DMG
        print("      使用 create-dmg 创建 DMG...")
        dmg_result = subprocess.run(
            [
                "create-dmg",
                "--volname", f"StepUp v{version}",
                "--window-pos", "200", "120",
                "--window-size", "600", "400",
                "--icon-size", "100",
                "--app-drop-link", "450", "185",
                "--icon", app_name, "150", "185",
                str(dmg_path),
                str(package_dir)
            ],
            capture_output=True,
            text=True
        )
        if dmg_result.returncode == 0:
            print(f"      DMG 创建完成: {package_name}.dmg")
        else:
            print(f"      DMG 创建失败，回退到 ZIP: {dmg_result.stderr}")
            create_zip_archive(package_dir, zip_path)
            print(f"      ZIP 创建完成: {package_name}.zip")
    else:
        # 创建 ZIP 压缩包
        print("      创建 ZIP 压缩包...")
        create_zip_archive(package_dir, zip_path)
        print(f"      ZIP 创建完成: {package_name}.zip")

    # 清理临时目录
    shutil.rmtree(package_dir)
    print()
    return True


def package_linux(project_root, version_dir, version):
    """打包 Linux 版本"""
    print_section("打包 Linux 版本")

    # 检查是否在 Linux 上运行
    if sys_platform.system() != "Linux":
        print("[跳过] Linux 打包需要在 Linux 系统上运行")
        return True

    linux_source = project_root / "build" / "linux" / "x64" / "release" / "bundle"
    package_name = f"StepUp_v{version}_linux"
    package_dir = version_dir / package_name

    if not (linux_source / "stepup_app").exists():
        print("[错误] 未找到 Linux 构建文件！")
        print(f"       请先运行: python build.py {version}")
        return False

    # 复制文件
    print("[1/2] 复制文件...")
    if package_dir.exists():
        shutil.rmtree(package_dir)
    shutil.copytree(linux_source, package_dir)
    print("      文件复制完成")

    # 创建压缩包
    print("[2/2] 创建压缩包...")
    zip_path = version_dir / f"{package_name}.zip"
    create_zip_archive(package_dir, zip_path)
    print(f"      压缩包创建完成: {package_name}.zip")

    # 清理临时目录
    shutil.rmtree(package_dir)
    print()
    return True


def package_web(project_root, version_dir, version):
    """打包 Web 版本"""
    print_section("打包 Web 版本")

    web_source = project_root / "build" / "web"
    package_name = f"StepUp_v{version}_web"

    if not web_source.exists():
        print("[错误] 未找到 Web 构建文件！")
        print(f"       请先运行: python build.py {version}")
        return False

    # 创建压缩包
    print("[1/1] 创建压缩包...")
    zip_path = version_dir / f"{package_name}.zip"
    create_zip_archive(web_source, zip_path)
    print(f"      压缩包创建完成: {package_name}.zip")
    print()
    return True


def package_android(project_root, version_dir, version):
    """打包 Android 版本"""
    print_section("打包 Android 版本")

    apk_source = project_root / "build" / "app" / "outputs" / "flutter-apk" / "app-release.apk"
    apk_name = f"StepUp_v{version}_android.apk"

    if not apk_source.exists():
        print("[错误] 未找到 Android APK 文件！")
        print(f"       请先运行: python build.py {version}")
        return False

    print("[1/1] 复制 APK 文件...")
    shutil.copy2(apk_source, version_dir / apk_name)
    print(f"      APK 复制完成: {apk_name}")
    print()
    return True


def package_installer(project_root, version_dir, version):
    """打包 Windows 安装程序"""
    print_section("打包 Windows 安装程序")

    iscc_path = Path(r"C:\Program Files (x86)\Inno Setup 6\ISCC.exe")
    if not iscc_path.exists():
        print("[警告] 未找到 Inno Setup，跳过安装程序打包")
        return True

    # 更新版本号
    print("[1/2] 更新安装脚本版本号...")
    if not update_setup_iss_version(project_root, version):
        print("[警告] 更新安装脚本版本号失败")
    else:
        print("      版本号已更新")

    # 编译安装程序
    print("[2/2] 编译安装程序...")
    installer_dir = project_root / "installer"
    result = subprocess.run(
        [str(iscc_path), "setup.iss"],
        cwd=installer_dir,
        capture_output=True,
        text=True,
        encoding='utf-8',
        errors='ignore'
    )
    if result.returncode != 0:
        print("[错误] 安装程序编译失败！")
        return False
    print("      安装程序编译完成")

    # 复制安装程序
    installer_source = project_root / "build" / "installer" / f"StepUp_Setup_v{version}.exe"
    installer_name = f"StepUp_v{version}_windows_installer.exe"

    if installer_source.exists():
        shutil.copy2(installer_source, version_dir / installer_name)
        print(f"      安装程序已复制: {installer_name}")
    print()
    return True


def get_platforms_to_package():
    """根据当前系统确定默认打包平台"""
    system = sys_platform.system()
    if system == "Windows":
        return ["windows", "android", "installer"]
    elif system == "Darwin":  # macOS
        return ["macos", "android"]
    elif system == "Linux":
        return ["linux", "android"]
    else:
        return ["android"]


def parse_arguments():
    """解析命令行参数"""
    parser = argparse.ArgumentParser(
        description="StepUp 打包脚本",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
示例:
  python package.py 1.2.5
  python package.py 1.2.5 --platforms=macos
  python package.py 1.2.5 --platforms=windows,android,macos
  python package.py 1.2.5 --all-platforms
        """
    )
    parser.add_argument("version", help="版本号 (格式: x.x.x)")
    parser.add_argument(
        "--platforms",
        help="要打包的平台，逗号分隔 (windows,android,macos,linux,web,installer)",
        default=None
    )
    parser.add_argument(
        "--all-platforms",
        help="打包所有支持的平台",
        action="store_true"
    )
    return parser.parse_args()


def main():
    print_header("StepUp 打包脚本")

    # 解析参数
    args = parse_arguments()
    version = args.version

    # 验证版本号
    if not validate_version(version):
        print("[错误] 版本号格式不正确，请使用 x.x.x 格式，例如: 1.2.5")
        input("\n按回车键退出...")
        sys.exit(1)

    # 确定要打包的平台
    if args.all_platforms:
        platforms = ["windows", "android", "macos", "linux", "web", "installer"]
    elif args.platforms:
        platforms = [p.strip().lower() for p in args.platforms.split(",")]
    else:
        platforms = get_platforms_to_package()

    # 设置路径
    script_dir = Path(__file__).parent.resolve()
    project_root = script_dir.parent
    os.chdir(project_root)

    version_dir = project_root / "releases" / f"v{version}"
    version_dir.mkdir(parents=True, exist_ok=True)

    print(f"[信息] 版本号: {version}")
    print(f"[信息] 输出目录: {version_dir}")
    print(f"[信息] 打包平台: {', '.join(platforms)}")
    print(f"[信息] 当前系统: {sys_platform.system()}")
    print()

    # 打包各平台
    package_results = {}

    if "windows" in platforms:
        package_results["windows"] = package_windows(project_root, version_dir, version)
        if not package_results["windows"]:
            input("\n按回车键退出...")
            sys.exit(1)

    if "android" in platforms:
        package_results["android"] = package_android(project_root, version_dir, version)
        if not package_results["android"]:
            input("\n按回车键退出...")
            sys.exit(1)

    if "macos" in platforms:
        package_results["macos"] = package_macos(project_root, version_dir, version)
        if not package_results["macos"]:
            input("\n按回车键退出...")
            sys.exit(1)

    if "linux" in platforms:
        package_results["linux"] = package_linux(project_root, version_dir, version)
        if not package_results["linux"]:
            input("\n按回车键退出...")
            sys.exit(1)

    if "web" in platforms:
        package_results["web"] = package_web(project_root, version_dir, version)
        if not package_results["web"]:
            input("\n按回车键退出...")
            sys.exit(1)

    if "installer" in platforms:
        package_results["installer"] = package_installer(project_root, version_dir, version)
        if not package_results["installer"]:
            input("\n按回车键退出...")
            sys.exit(1)

    # 完成
    print_header("打包完成！")
    print(f"版本号: {version}")
    print(f"输出目录: {version_dir}")
    print()
    print("生成的文件:")
    for file in version_dir.iterdir():
        if file.is_file():
            size = file.stat().st_size / (1024 * 1024)
            print(f"  {file.name} ({size:.1f} MB)")
    print()

    input("按回车键退出...")


if __name__ == "__main__":
    main()
