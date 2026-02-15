#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
StepUp 构建脚本
用法: python build.py [版本号]
示例: python build.py 1.2.5
"""

import sys
import os
import re
import subprocess
from pathlib import Path

# 代理配置 - 用于下载 sqlite3 等原生库
# 如果你有代理，请取消下面两行的注释并修改为你的代理地址
PROXY_URL = "http://127.0.0.1:7890"  # 修改为你的代理地址和端口
# PROXY_URL = None  # 如果没有代理，使用这行


def print_header(title):
    print("=" * 50)
    print(f"  {title}")
    print("=" * 50)
    print()


def print_step(step, total, message):
    print(f"[{step}/{total}] {message}...")


def run_command(cmd, cwd=None, env=None):
    """运行命令并返回结果"""
    result = subprocess.run(
        cmd, shell=True, cwd=cwd,
        capture_output=True, text=True,
        encoding='utf-8', errors='ignore',
        env=env
    )
    if result.returncode != 0:
        print(f"[错误] 命令执行失败: {cmd}")
        if result.stderr:
            print(result.stderr)
        return False
    return True


def get_proxy_env():
    """获取包含代理设置的环境变量"""
    env = os.environ.copy()
    
    # Flutter 国内镜像
    env["FLUTTER_STORAGE_BASE_URL"] = "https://storage.flutter-io.cn"
    env["PUB_HOSTED_URL"] = "https://pub.flutter-io.cn"
    
    # HTTP/HTTPS 代理（用于下载 sqlite3 等原生库）
    if PROXY_URL:
        env["HTTP_PROXY"] = PROXY_URL
        env["HTTPS_PROXY"] = PROXY_URL
        env["http_proxy"] = PROXY_URL
        env["https_proxy"] = PROXY_URL
    
    return env


def validate_version(version):
    """验证版本号格式"""
    pattern = r"^\d+\.\d+\.\d+$"
    return re.match(pattern, version) is not None


def update_pubspec_version(project_root, version):
    """更新 pubspec.yaml 版本号"""
    pubspec_path = project_root / "pubspec.yaml"
    if not pubspec_path.exists():
        print("[错误] 未找到 pubspec.yaml 文件")
        return False

    content = pubspec_path.read_text(encoding="utf-8")
    content = re.sub(r"^version: .*$", f"version: {version}", content, flags=re.MULTILINE)
    pubspec_path.write_text(content, encoding="utf-8")
    return True


def main():
    print_header("StepUp 构建脚本")

    # 检查参数
    if len(sys.argv) < 2:
        print("用法: python build.py [版本号]")
        print("示例: python build.py 1.2.5")
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

    print(f"[信息] 版本号: {version}")
    print(f"[信息] 项目路径: {project_root}")
    print()

    # 步骤 1: 更新版本号
    print_step(1, 5, "更新 pubspec.yaml 版本号")
    if not update_pubspec_version(project_root, version):
        input("\n按回车键退出...")
        sys.exit(1)
    print("      版本号已更新")
    print()

    # 步骤 2: 清理构建缓存
    print_step(2, 5, "清理构建缓存")
    if not run_command("flutter clean"):
        input("\n按回车键退出...")
        sys.exit(1)
    print("      清理完成")
    print()

    # 步骤 3: 获取依赖
    print_step(3, 5, "获取依赖")
    env = get_proxy_env()
    if not run_command("flutter pub get", env=env):
        input("\n按回车键退出...")
        sys.exit(1)
    print("      依赖获取完成")
    print()

    # 步骤 4: 构建 Windows
    print_step(4, 5, "构建 Windows 应用")
    env = get_proxy_env()
    if not run_command("flutter build windows --release", env=env):
        input("\n按回车键退出...")
        sys.exit(1)
    print("      Windows 构建完成")
    print()

    # 步骤 5: 构建 Android
    print_step(5, 5, "构建 Android 应用")
    env = get_proxy_env()
    if PROXY_URL:
        print(f"      使用代理: {PROXY_URL}")
    
    result = subprocess.run(
        "flutter build apk --release",
        shell=True,
        env=env,
        capture_output=True,
        text=True,
        encoding='utf-8',
        errors='ignore'
    )
    if result.returncode != 0:
        print("[错误] Android 构建失败！")
        if result.stderr:
            print(result.stderr)
        input("\n按回车键退出...")
        sys.exit(1)
    print("      Android 构建完成")
    print()

    # 完成
    print_header("构建完成！")
    print(f"版本号: {version}")
    print()
    print("构建输出:")
    print("  Windows: build\\windows\\x64\\runner\\Release\\")
    print("  Android: build\\app\\outputs\\flutter-apk\\app-release.apk")
    print()


if __name__ == "__main__":
    main()
