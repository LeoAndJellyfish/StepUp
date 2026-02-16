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
import urllib.request

# GitHub 镜像配置 - 用于下载 sqlite3 等原生库
# 可用的 GitHub 镜像加速服务
GITHUB_MIRRORS = [
    "https://ghproxy.com/https://github.com",      # ghproxy
    "https://mirror.ghproxy.com/https://github.com", # mirror.ghproxy
    "https://gh.api.99988866.xyz/https://github.com", # 99988866
    "https://gh.ddlc.top/https://github.com",      # ddlc
    "https://ghps.cc/https://github.com",          # ghps
]


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


def download_with_mirror(url, output_path):
    """使用镜像下载文件"""
    # 尝试原始 URL
    urls_to_try = [url]
    
    # 添加镜像 URL
    for mirror in GITHUB_MIRRORS:
        mirror_url = url.replace("https://github.com", mirror)
        urls_to_try.append(mirror_url)
    
    for try_url in urls_to_try:
        try:
            print(f"      尝试下载: {try_url[:60]}...")
            req = urllib.request.Request(
                try_url,
                headers={
                    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.0'
                }
            )
            with urllib.request.urlopen(req, timeout=60) as response:
                output_path.parent.mkdir(parents=True, exist_ok=True)
                with open(output_path, 'wb') as f:
                    f.write(response.read())
            print(f"      下载成功: {output_path.name}")
            return True
        except Exception as e:
            print(f"      失败: {str(e)[:50]}")
            continue
    
    return False


def prepare_sqlite3_libs(project_root):
    """预下载 sqlite3 原生库到缓存目录"""
    print("      预下载 sqlite3 原生库...")
    
    # sqlite3 版本
    sqlite3_version = "3.1.5"
    
    # 需要下载的文件列表
    libs = [
        "libsqlite3.arm.android.so",
        "libsqlite3.arm64.android.so",
        "libsqlite3.x64.android.so",
    ]
    
    # Pub 缓存目录
    pub_cache = Path.home() / "AppData" / "Local" / "Pub" / "Cache" / "hosted" / "pub.flutter-io.cn" / f"sqlite3-{sqlite3_version}"
    
    if not pub_cache.exists():
        print("      未找到 sqlite3 缓存目录，跳过预下载")
        return True
    
    # 原生库输出目录
    native_dir = pub_cache / "native"
    native_dir.mkdir(exist_ok=True)
    
    success = True
    for lib in libs:
        output_path = native_dir / lib
        if output_path.exists():
            print(f"      已存在: {lib}")
            continue
        
        url = f"https://github.com/simolus3/sqlite3.dart/releases/download/sqlite3-{sqlite3_version}/{lib}"
        if not download_with_mirror(url, output_path):
            print(f"      [警告] 无法下载: {lib}")
            success = False
    
    return success


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
    print_step(1, 6, "更新 pubspec.yaml 版本号")
    if not update_pubspec_version(project_root, version):
        input("\n按回车键退出...")
        sys.exit(1)
    print("      版本号已更新")
    print()

    # 步骤 2: 清理构建缓存
    print_step(2, 6, "清理构建缓存")
    if not run_command("flutter clean"):
        input("\n按回车键退出...")
        sys.exit(1)
    print("      清理完成")
    print()

    # 步骤 3: 预下载 sqlite3 原生库
    print_step(3, 6, "预下载 sqlite3 原生库")
    prepare_sqlite3_libs(project_root)
    print()

    # 步骤 4: 获取依赖
    print_step(4, 6, "获取依赖")
    env = get_mirror_env()
    if not run_command("flutter pub get", env=env):
        input("\n按回车键退出...")
        sys.exit(1)
    print("      依赖获取完成")
    print()

    # 步骤 5: 构建 Windows
    print_step(5, 6, "构建 Windows 应用")
    env = get_mirror_env()
    if not run_command("flutter build windows --release", env=env):
        input("\n按回车键退出...")
        sys.exit(1)
    print("      Windows 构建完成")
    print()

    # 步骤 6: 构建 Android
    print_step(6, 6, "构建 Android 应用")
    env = get_mirror_env()
    
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
