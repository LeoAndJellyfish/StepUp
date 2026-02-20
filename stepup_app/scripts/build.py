#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
StepUp 构建脚本
用法: python build.py [版本号] [--platforms=windows,android,macos,linux,web]
示例: python build.py 1.2.5
       python build.py 1.2.5 --platforms=macos
       python build.py 1.2.5 --platforms=windows,android,macos
"""

import sys
import os
import re
import subprocess
import platform as sys_platform
from pathlib import Path
import argparse


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


def get_mirror_env():
    """获取包含镜像设置的环境变量"""
    env = os.environ.copy()

    # Flutter 国内镜像
    env["FLUTTER_STORAGE_BASE_URL"] = "https://storage.flutter-io.cn"
    env["PUB_HOSTED_URL"] = "https://pub.flutter-io.cn"

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


def get_platforms_to_build():
    """根据当前系统确定默认构建平台"""
    system = sys_platform.system()
    if system == "Windows":
        return ["windows", "android"]
    elif system == "Darwin":  # macOS
        return ["macos", "ios", "android"]
    elif system == "Linux":
        return ["linux", "android"]
    else:
        return ["android"]


def parse_arguments():
    """解析命令行参数"""
    parser = argparse.ArgumentParser(
        description="StepUp 构建脚本",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
示例:
  python build.py 1.2.5
  python build.py 1.2.5 --platforms=macos
  python build.py 1.2.5 --platforms=windows,android,macos
  python build.py 1.2.5 --all-platforms
        """
    )
    parser.add_argument("version", help="版本号 (格式: x.x.x)")
    parser.add_argument(
        "--platforms",
        help="要构建的平台，逗号分隔 (windows,android,macos,linux,web,ios)",
        default=None
    )
    parser.add_argument(
        "--all-platforms",
        help="构建所有支持的平台",
        action="store_true"
    )
    return parser.parse_args()


def build_windows(project_root, env):
    """构建 Windows 应用"""
    print_step(4, 6, "构建 Windows 应用")
    if not run_command("flutter build windows --release", env=env):
        return False
    print("      Windows 构建完成")
    return True


def build_android(project_root, env):
    """构建 Android 应用"""
    print_step(5, 6, "构建 Android 应用")
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
        return False
    print("      Android 构建完成")
    return True


def build_macos(project_root, env):
    """构建 macOS 应用"""
    print_step(6, 6, "构建 macOS 应用")

    # 检查是否在 macOS 上运行
    if sys_platform.system() != "Darwin":
        print("      [跳过] macOS 构建需要在 macOS 系统上运行")
        return True  # 返回 True 表示不是错误，只是跳过

    if not run_command("flutter build macos --release", env=env):
        return False
    print("      macOS 构建完成")
    return True


def build_linux(project_root, env):
    """构建 Linux 应用"""
    print_step(6, 6, "构建 Linux 应用")

    # 检查是否在 Linux 上运行
    if sys_platform.system() != "Linux":
        print("      [跳过] Linux 构建需要在 Linux 系统上运行")
        return True

    if not run_command("flutter build linux --release", env=env):
        return False
    print("      Linux 构建完成")
    return True


def build_web(project_root, env):
    """构建 Web 应用"""
    print_step(6, 6, "构建 Web 应用")
    if not run_command("flutter build web --release", env=env):
        return False
    print("      Web 构建完成")
    return True


def main():
    print_header("StepUp 构建脚本")

    # 解析参数
    args = parse_arguments()
    version = args.version

    # 验证版本号
    if not validate_version(version):
        print("[错误] 版本号格式不正确，请使用 x.x.x 格式，例如: 1.2.5")
        input("\n按回车键退出...")
        sys.exit(1)

    # 设置路径
    script_dir = Path(__file__).parent.resolve()
    project_root = script_dir.parent
    os.chdir(project_root)

    # 确定要构建的平台
    if args.all_platforms:
        platforms = ["windows", "android", "macos", "linux", "web"]
    elif args.platforms:
        platforms = [p.strip().lower() for p in args.platforms.split(",")]
    else:
        platforms = get_platforms_to_build()

    print(f"[信息] 版本号: {version}")
    print(f"[信息] 项目路径: {project_root}")
    print(f"[信息] 构建平台: {', '.join(platforms)}")
    print(f"[信息] 当前系统: {sys_platform.system()}")
    print()

    # 步骤 1: 更新版本号
    print_step(1, 3, "更新 pubspec.yaml 版本号")
    if not update_pubspec_version(project_root, version):
        input("\n按回车键退出...")
        sys.exit(1)
    print("      版本号已更新")
    print()

    # 步骤 2: 清理构建缓存
    print_step(2, 3, "清理构建缓存")
    if not run_command("flutter clean"):
        input("\n按回车键退出...")
        sys.exit(1)
    print("      清理完成")
    print()

    # 步骤 3: 获取依赖
    print_step(3, 3, "获取依赖")
    env = get_mirror_env()
    if not run_command("flutter pub get", env=env):
        input("\n按回车键退出...")
        sys.exit(1)
    print("      依赖获取完成")
    print()

    # 构建各平台
    build_results = {}
    
    if "windows" in platforms:
        build_results["windows"] = build_windows(project_root, env)
        print()
    
    if "android" in platforms:
        build_results["android"] = build_android(project_root, env)
        print()
    
    if "macos" in platforms:
        build_results["macos"] = build_macos(project_root, env)
        print()
    
    if "linux" in platforms:
        build_results["linux"] = build_linux(project_root, env)
        print()
    
    if "web" in platforms:
        build_results["web"] = build_web(project_root, env)
        print()

    # 检查是否有构建失败
    failed_platforms = [p for p, success in build_results.items() if not success]
    if failed_platforms:
        print(f"[错误] 以下平台构建失败: {', '.join(failed_platforms)}")
        input("\n按回车键退出...")
        sys.exit(1)

    # 完成
    print_header("构建完成！")
    print(f"版本号: {version}")
    print()
    print("构建输出:")
    if "windows" in platforms:
        print("  Windows: build\\windows\\x64\\runner\\Release\\")
    if "android" in platforms:
        print("  Android: build\\app\\outputs\\flutter-apk\\app-release.apk")
    if "macos" in platforms:
        print("  macOS:   build\\macos\\Build\\Products\\Release\\")
    if "linux" in platforms:
        print("  Linux:   build\\linux\\x64\\release\\bundle\\")
    if "web" in platforms:
        print("  Web:     build\\web\\")
    print()


if __name__ == "__main__":
    main()
