#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
StepUp 一键构建打包脚本
用法: python build_and_package.py [版本号] [--platforms=windows,android,macos,linux,web]
示例: python build_and_package.py 1.2.5
       python build_and_package.py 1.2.5 --platforms=macos
       python build_and_package.py 1.2.5 --platforms=windows,android,macos
       python build_and_package.py 1.2.5 --all-platforms
"""

import sys
import re
import subprocess
import argparse
from pathlib import Path


def print_header(title):
    print("=" * 50)
    print(f"  {title}")
    print("=" * 50)
    print()


def validate_version(version):
    """验证版本号格式"""
    pattern = r"^\d+\.\d+\.\d+$"
    return re.match(pattern, version) is not None


def run_script(script_name, version, platforms=None, all_platforms=False):
    """运行子脚本"""
    script_dir = Path(__file__).parent.resolve()
    script_path = script_dir / script_name

    cmd = [sys.executable, str(script_path), version]
    if all_platforms:
        cmd.append("--all-platforms")
    elif platforms:
        cmd.append(f"--platforms={platforms}")

    result = subprocess.run(
        cmd,
        cwd=script_dir.parent
    )
    return result.returncode == 0


def parse_arguments():
    """解析命令行参数"""
    parser = argparse.ArgumentParser(
        description="StepUp 一键构建打包脚本",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
示例:
  python build_and_package.py 1.2.5
  python build_and_package.py 1.2.5 --platforms=macos
  python build_and_package.py 1.2.5 --platforms=windows,android,macos
  python build_and_package.py 1.2.5 --all-platforms
        """
    )
    parser.add_argument("version", help="版本号 (格式: x.x.x)")
    parser.add_argument(
        "--platforms",
        help="要构建打包的平台，逗号分隔 (windows,android,macos,linux,web,ios)",
        default=None
    )
    parser.add_argument(
        "--all-platforms",
        help="构建打包所有支持的平台",
        action="store_true"
    )
    return parser.parse_args()


def main():
    print_header("StepUp 一键构建打包脚本")

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

    print_header("开始一键构建打包")
    print(f"版本号: {version}")
    if args.platforms:
        print(f"指定平台: {args.platforms}")
    elif args.all_platforms:
        print("构建所有平台")
    print()
    input("按任意键开始...")
    print()

    # 步骤 1: 构建
    print_header("步骤 1/2: 构建")
    if not run_script("build.py", version, args.platforms, args.all_platforms):
        print()
        print("[错误] 构建失败！")
        input("\n按回车键退出...")
        sys.exit(1)

    # 步骤 2: 打包
    print_header("步骤 2/2: 打包")
    if not run_script("package.py", version, args.platforms, args.all_platforms):
        print()
        print("[错误] 打包失败！")
        input("\n按回车键退出...")
        sys.exit(1)

    # 完成
    print_header("一键构建打包完成！")
    print(f"版本号: {version}")
    print(f"输出目录: {project_root / 'releases' / f'v{version}'}")
    print()
    input("按回车键退出...")


if __name__ == "__main__":
    main()
