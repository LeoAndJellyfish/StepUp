# StepUp综测系统 - 版本管理架构

## 📁 新的目录结构

```
stepup_app/
├── build/
│   ├── releases/                    # 🎯 发行版根目录
│   │   ├── v1.0.0/                 # 版本目录
│   │   │   ├── StepUp_v1.0.0_正式版/
│   │   │   │   ├── stepup_app.exe
│   │   │   │   ├── README.txt
│   │   │   │   ├── version.json
│   │   │   │   └── data/
│   │   │   └── StepUp_v1.0.0_正式版.zip
│   │   ├── v1.0.1/                 # 修复版
│   │   ├── v1.0.2/                 # 文件存储优化版
│   │   └── latest.txt              # 指向最新版本
│   ├── temp/                       # 临时构建文件
│   └── archive/                    # 历史版本归档
├── scripts/                        # 🛠️ 版本管理工具
│   ├── package-release.bat         # 打包发行版
│   ├── list-versions.bat          # 查看版本列表
│   ├── build-release.ps1          # PowerShell构建脚本
│   ├── manage-versions.ps1         # PowerShell管理脚本
│   └── config.ps1                 # 配置文件
└── windows/x64/runner/             # Flutter构建输出
    └── Release/                    # 构建产物（临时）
```

## 🚀 版本管理工具

### 1. 打包发行版
```bash
# 基本用法
.\scripts\package-release.bat 1.0.3 "新功能版"

# 版本类型示例
.\scripts\package-release.bat 1.0.3 "正式版"
.\scripts\package-release.bat 1.0.4 "修复版"
.\scripts\package-release.bat 1.1.0 "功能版"
.\scripts\package-release.bat 2.0.0 "重大更新版"
```

### 2. 查看版本列表
```bash
.\scripts\list-versions.bat
```

### 3. 版本命名规范
- **正式版**: 稳定的功能发布
- **修复版**: Bug修复和小改进
- **功能版**: 新功能添加
- **优化版**: 性能或体验优化
- **测试版**: Beta测试版本

## 📦 发行包内容

每个版本包含：
- `stepup_app.exe` - 主程序
- `README.txt` - 版本说明和使用指南
- `version.json` - 版本元数据
- `data/` - 应用资源和数据
- `*.dll` - 依赖库文件

## 🔄 版本管理流程

1. **开发完成** → 确认版本号和描述
2. **构建应用** → `flutter build windows --release`
3. **打包发行** → `package-release.bat [版本] [描述]`
4. **验证测试** → 启动应用确认功能正常
5. **发布分享** → 分享zip压缩包

## 📋 版本信息结构

`version.json` 文件包含：
```json
{
  "version": "1.0.2",
  "description": "文件存储优化版",
  "buildTime": "2025-08-25 16:30:00",
  "platform": "Windows x64",
  "buildId": "20250825163000"
}
```

## 🗂️ 文件组织优势

### ✅ 优化后的优势：
1. **版本隔离**：每个版本独立目录，避免混乱
2. **清晰结构**：按版本号组织，易于查找
3. **自动化工具**：脚本化管理，减少人工错误
4. **版本追踪**：latest.txt指向最新版本
5. **历史管理**：archive目录保存旧版本
6. **标准命名**：统一的文件命名规范

### ❌ 旧架构问题：
- 所有版本混在一个文件夹
- 难以区分不同版本
- 容易误删或覆盖
- 缺乏版本追踪机制

## 🛠️ 维护建议

1. **定期清理**：将旧版本移动到archive目录
2. **备份重要版本**：保留重要里程碑版本
3. **文档更新**：每次发布更新README
4. **测试验证**：发布前充分测试
5. **版本记录**：记录每个版本的主要变更

## 📈 未来扩展

计划扩展功能：
- 自动版本号递增
- 变更日志生成
- 自动测试集成
- 多平台构建支持
- CI/CD集成

---

*版本管理架构 v1.0 - 2025年8月25日*