#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
StepUp 打包脚本
用法: python package.py [版本号]
示例: python package.py 1.2.5
"""

import sys
import os
import re
import shutil
import subprocess
import zipfile
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
    """打包 Windows 版本"""
    print_section("打包 Windows 版本")

    win_source = project_root / "build" / "windows" / "x64" / "runner" / "Release"
    package_name = f"StepUp_v{version}_windows"
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
    installer_name = f"StepUp_Setup_v{version}.exe"

    if installer_source.exists():
        shutil.copy2(installer_source, version_dir / installer_name)
        print(f"      安装程序已复制: {installer_name}")
    print()
    return True


def main():
    print_header("StepUp 打包脚本")

    # 检查参数
    if len(sys.argv) < 2:
        print("用法: python package.py [版本号]")
        print("示例: python package.py 1.2.5")
        input("\n按回车键退出...")
        sys.exit(1)

    version = sys.argv[1]

    # 验证版本号
    if not validate_version(version):
        print("[错误] 版本号格式不正确，请使用 x.x.x 格式，例如: 1.2.5")
        input("\n按回车键退出...")
        sys.exit(1)

    # 设置路径
    script_dir = Path(__file__).parent.resolve()
    project_root = script_dir.parent
    os.chdir(project_root)

    version_dir = project_root / "releases" / f"v{version}"
    version_dir.mkdir(parents=True, exist_ok=True)

    print(f"[信息] 版本号: {version}")
    print(f"[信息] 输出目录: {version_dir}")
    print()

    # 打包 Windows
    if not package_windows(project_root, version_dir, version):
        input("\n按回车键退出...")
        sys.exit(1)

    # 打包 Android
    if not package_android(project_root, version_dir, version):
        input("\n按回车键退出...")
        sys.exit(1)

    # 打包安装程序
    if not package_installer(project_root, version_dir, version):
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
