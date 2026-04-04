#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
StepUp 版本发布脚本
用法：python push.py [版本号]
示例：python push.py 1.4.3

功能:
1. 验证版本号格式
2. 更新 pubspec.yaml 版本号
3. 更新 website/script.js 版本号
4. 更新 README.md 版本号徽章
5. 创建 git commit
6. 创建 git tag
7. 推送到远程仓库
"""

import sys
import re
import subprocess
from pathlib import Path


def print_header(title):
    print("=" * 50)
    print(f"  {title}")
    print("=" * 50)
    print()


def print_step(step, total, message):
    print(f"[{step}/{total}] {message}...")


def validate_version(version):
    """验证版本号格式"""
    pattern = r"^\d+\.\d+\.\d+$"
    return re.match(pattern, version) is not None


def run_command(cmd, cwd=None):
    """运行命令并返回结果"""
    result = subprocess.run(
        cmd, shell=True, cwd=cwd,
        capture_output=True, text=True,
        encoding='utf-8', errors='ignore'
    )
    return result


def update_pubspec_version(project_root, version):
    """更新 pubspec.yaml 版本号"""
    pubspec_path = project_root / "pubspec.yaml"
    if not pubspec_path.exists():
        print("[错误] 未找到 pubspec.yaml 文件")
        return False

    content = pubspec_path.read_text(encoding="utf-8")
    new_content = re.sub(r"^version: .*$", f"version: {version}", content, flags=re.MULTILINE)
    
    if new_content == content:
        print("[警告] 版本号未发生变化")
        return True
    
    pubspec_path.write_text(new_content, encoding="utf-8")
    return True


def update_website_version(project_root, version):
    """更新 website/script.js 版本号"""
    script_path = project_root.parent / "website" / "script.js"
    if not script_path.exists():
        print("[警告] 未找到 website/script.js 文件，跳过网站版本更新")
        return True

    content = script_path.read_text(encoding="utf-8")
    new_content = re.sub(
        r"const APP_VERSION = '[\d.]+';",
        f"const APP_VERSION = '{version}';",
        content
    )
    
    if new_content == content:
        print("[警告] 网站版本号未发生变化")
        return True
    
    script_path.write_text(new_content, encoding="utf-8")
    return True


def update_readme_version(project_root, version):
    """更新 README.md 版本号徽章"""
    readme_path = project_root.parent / "README.md"
    if not readme_path.exists():
        print("[警告] 未找到 README.md 文件，跳过版本更新")
        return True

    content = readme_path.read_text(encoding="utf-8")
    new_content = re.sub(
        r"(badge/version-)\d+\.\d+\.\d+(-green)",
        f"\\g<1>{version}\\g<2>",
        content
    )
    
    if new_content == content:
        print("[警告] README 版本号未发生变化")
        return True
    
    readme_path.write_text(new_content, encoding="utf-8")
    return True


def check_git_status(project_root):
    """检查 git 状态"""
    result = run_command("git status --porcelain", cwd=project_root)
    if result.returncode != 0:
        print("[错误] 无法获取 git 状态")
        return False, []
    
    changes = result.stdout.strip()
    if changes:
        changed_files = [line.strip() for line in changes.split('\n') if line.strip()]
        return True, changed_files
    return True, []


def check_tag_exists(project_root, tag):
    """检查标签是否已存在"""
    result = run_command(f"git tag -l {tag}", cwd=project_root)
    if result.returncode != 0:
        return False
    return tag in result.stdout.strip()


def main():
    print_header("StepUp 版本发布脚本")

    if len(sys.argv) != 2:
        print("用法: python push.py <版本号>")
        print("示例: python push.py 1.4.3")
        sys.exit(1)

    version = sys.argv[1]

    if not validate_version(version):
        print("[错误] 版本号格式不正确，请使用 x.x.x 格式，例如：1.4.3")
        sys.exit(1)

    script_dir = Path(__file__).parent.resolve()
    project_root = script_dir.parent

    print(f"[信息] 版本号：{version}")
    print(f"[信息] 项目路径：{project_root}")
    print()

    tag = f"v{version}"
    
    if check_tag_exists(project_root, tag):
        print(f"[错误] 标签 {tag} 已存在！")
        print("       如需重新发布，请先删除旧标签：")
        print(f"       git tag -d {tag}")
        print(f"       git push origin --delete {tag}")
        sys.exit(1)

    ok, changed_files = check_git_status(project_root)
    if not ok:
        sys.exit(1)
    
    if changed_files:
        print("[警告] 工作目录有未提交的更改：")
        for f in changed_files[:5]:
            print(f"       {f}")
        if len(changed_files) > 5:
            print(f"       ... 还有 {len(changed_files) - 5} 个文件")
        print()
        response = input("是否继续？")
        if response != 'y':
            print("[取消] 操作已取消")
            sys.exit(1)

    print_step(1, 6, "更新 pubspec.yaml 版本号")
    if not update_pubspec_version(project_root, version):
        sys.exit(1)
    print("      完成")

    print_step(2, 6, "更新 website/script.js 版本号")
    if not update_website_version(project_root, version):
        sys.exit(1)
    print("      完成")

    print_step(3, 6, "更新 README.md 版本号徽章")
    if not update_readme_version(project_root, version):
        sys.exit(1)
    print("      完成")

    print_step(4, 6, "创建 git commit")
    run_command('git add pubspec.yaml', cwd=project_root)
    
    script_path = project_root.parent / "website" / "script.js"
    if script_path.exists():
        run_command('git add ../website/script.js', cwd=project_root)
    
    readme_path = project_root.parent / "README.md"
    if readme_path.exists():
        run_command('git add ../README.md', cwd=project_root)
    
    result = run_command(f'git commit -m "chore: release {tag}"', cwd=project_root)
    if result.returncode != 0:
        if "nothing to commit" in result.stdout or "nothing to commit" in result.stderr:
            print("      没有需要提交的更改")
        else:
            print(f"[错误] 提交失败: {result.stderr}")
            sys.exit(1)
    else:
        print("      完成")

    print_step(5, 6, f"创建标签 {tag}")
    result = run_command(f'git tag -a {tag} -m "Release {tag}"', cwd=project_root)
    if result.returncode != 0:
        print(f"[错误] 创建标签失败: {result.stderr}")
        sys.exit(1)
    print("      完成")

    print_step(6, 6, "推送到远程仓库")
    print("      推送 commit...")
    result = run_command('git push', cwd=project_root)
    if result.returncode != 0:
        print(f"[错误] 推送失败: {result.stderr}")
        sys.exit(1)
    
    print(f"      推送标签 {tag}...")
    result = run_command(f'git push origin {tag}', cwd=project_root)
    if result.returncode != 0:
        print(f"[错误] 推送标签失败: {result.stderr}")
        sys.exit(1)
    print("      完成")

    print_header("发布成功！")
    print(f"版本号：{version}")
    print(f"标签：{tag}")
    print()
    print("GitHub Actions 将自动构建并发布 Release。")
    print("请访问 GitHub 仓库查看构建进度。")
    print()


if __name__ == "__main__":
    main()
