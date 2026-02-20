#!/usr/bin/env python3
"""
自动从 pubspec.yaml 同步版本号到网页
用法: python update_version.py
"""

import re


def get_version_from_pubspec(pubspec_path='../stepup_app/pubspec.yaml'):
    """从 pubspec.yaml 读取版本号"""
    try:
        with open(pubspec_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # 匹配 version: x.x.x 格式
        match = re.search(r'^version:\s*([\d.]+)', content, re.MULTILINE)
        if match:
            return match.group(1)
        else:
            print("错误: 无法在 pubspec.yaml 中找到版本号")
            return None
    except FileNotFoundError:
        print(f"错误: 找不到文件 {pubspec_path}")
        return None
    except Exception as e:
        print(f"错误: 读取 pubspec.yaml 时出错: {e}")
        return None


def update_script_js(version, script_path='script.js'):
    """更新 script.js 中的版本号"""
    try:
        with open(script_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # 替换 APP_VERSION 常量
        new_content = re.sub(
            r"const APP_VERSION = '[\d.]+';",
            f"const APP_VERSION = '{version}';",
            content
        )
        
        with open(script_path, 'w', encoding='utf-8') as f:
            f.write(new_content)
        
        print(f"[OK] 已更新 {script_path}: {version}")
        return True
    except Exception as e:
        print(f"错误: 更新 {script_path} 时出错: {e}")
        return False


def main():
    """主函数"""
    print("=" * 50)
    print("StepUp 版本号同步工具")
    print("=" * 50)
    
    # 获取 pubspec.yaml 中的版本号
    version = get_version_from_pubspec()
    if not version:
        return 1
    
    print(f"\n从 pubspec.yaml 读取到版本号: {version}\n")
    
    # 更新 script.js
    if update_script_js(version):
        print("\n[OK] 版本号同步完成!")
        print("  请记得将更改提交到版本控制。")
        return 0
    else:
        print("\n[FAIL] 版本号同步失败!")
        return 1


if __name__ == '__main__':
    exit(main())
