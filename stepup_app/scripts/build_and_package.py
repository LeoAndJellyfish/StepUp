#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
StepUp 一键构建打包脚本
用法: python build_and_package.py [版本号]
示例: python build_and_package.py 1.2.5
"""

import sys
import os
import re
import subprocess
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


def run_script(script_name, version):
    """运行子脚本"""
    script_dir = Path(__file__).parent.resolve()
    script_path = script_dir / script_name

    result = subprocess.run(
        [sys.executable, str(script_path), version],
        cwd=script_dir.parent
    )
    return result.returncode == 0


def main():
    print_header("StepUp 一键构建打包脚本")

    # 检查参数
    if len(sys.argv) < 2:
        print("用法: python build_and_package.py [版本号]")
        print("示例: python build_and_package.py 1.2.5")
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

    print_header("开始一键构建打包")
    print(f"版本号: {version}")
    print()
    input("按任意键开始...")
    print()

    # 步骤 1: 构建
    print_header("步骤 1/2: 构建")
    if not run_script("build.py", version):
        print()
        print("[错误] 构建失败！")
        input("\n按回车键退出...")
        sys.exit(1)

    # 步骤 2: 打包
    print_header("步骤 2/2: 打包")
    if not run_script("package.py", version):
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
