# StepUp 综合测评系统

一个功能强大的Flutter应用，专门为大学生设计，用于清晰有序地管理综合测评条目。

## 📱 应用简介

StepUp是一款专为中央财经大学（CUFE）学生设计的综合测评管理系统，帮助您轻松记录、管理和统计各类综测活动。通过直观的界面和强大的功能，让综测管理变得简单高效。

## ✨ 主要功能

### 📋 综测条目管理
- **智能添加**：支持活动名称、日期、类型、时长、备注等完整信息录入
- **分类管理**：按活动类型自动分类，支持自定义分类
- **快速搜索**：按名称、日期、类型等多维度搜索和过滤
- **批量操作**：支持条目的批量编辑和删除

### 📊 数据统计与可视化
- **时长统计**：自动计算各类别活动总时长
- **趋势分析**：时间趋势图表展示活动参与情况
- **分类占比**：直观展示各类型活动分布比例

### 📎 文件管理
- **证明材料上传**：支持图片、文档等证明文件上传
- **文件预览**：内置文件查看器，方便快速查阅
- **安全存储**：文件加密存储，确保数据安全

### 🔄 数据导出
- **报表生成**：支持多种格式的数据导出
- **版本管理**：完善的数据备份和恢复机制

## 🚀 AI评分功能（规划中）

### 🤖 智能评分系统
- **自动评分引擎**：AI根据评分标准自动计算分数
- **文档解析**：支持PDF、Word等格式的评分标准自动识别
- **智能分类计分**：针对不同维度采用不同的评分策略
- **问卷生成**：AI自动生成针对性问卷辅助主观评价

## 🛠️ 技术栈

- **前端框架**：Flutter 3.9.0+
- **数据库**：SQLite（sqflite）
- **状态管理**：Provider
- **路由管理**：Go Router
- **UI组件**：Material Design + Cupertino
- **图表库**：FL Chart

## 📦 项目结构

```
stepup_app/
├── lib/
│   ├── main.dart              # 应用入口
│   ├── models/               # 数据模型
│   ├── pages/                # 页面组件
│   ├── router/               # 路由配置
│   ├── services/             # 业务服务
│   ├── theme/                # 主题配置
│   └── widgets/              # 通用组件
├── android/                  # Android平台配置
├── ios/                      # iOS平台配置
├── windows/                  # Windows平台配置
├── macos/                    # macOS平台配置
├── linux/                    # Linux平台配置
└── web/                      # Web平台配置
```

## 🎯 开发状态

### ✅ 已完成功能
- 基础框架搭建
- 数据库设计与实现
- 综测条目增删改查
- 文件管理功能
- 数据统计可视化
- 多平台适配

### 🔄 开发中功能
- AI评分系统（规划阶段）
- 云端同步功能
- 高级数据导出

## 📥 安装与运行

### 系统要求
- Flutter SDK 3.9.0+
- Dart SDK
- 各平台对应的开发环境

### 运行步骤
1. 克隆项目到本地
2. 进入 `stepup_app` 目录
3. 运行 `flutter pub get` 安装依赖
4. 运行 `flutter run` 启动应用

### Windows用户注意
本软件需要Microsoft Visual C++ Redistributable支持，如无法打开软件，请自行在微软官方网页下载安装：
https://learn.microsoft.com/zh-cn/cpp/windows/latest-supported-vc-redist?view=msvc-170#latest-microsoft-visual-c-redistributable-version

## 📱 支持平台

- ✅ Android
- ✅ iOS  
- ✅ Windows
- ✅ macOS
- ✅ Linux
- ✅ Web

## 🤝 贡献指南

欢迎提交Issue和Pull Request来帮助改进StepUp！

## 📄 许可证

本项目采用 Apache License 2.0 许可证，详见 LICENSE 文件。

## 📞 联系我们

如有问题或建议，请通过GitHub Issues联系我们。

---

**StepUp - 让综测管理更简单！** 🎓
