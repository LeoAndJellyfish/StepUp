# StepUp综测系统 - 版本管理架构

## 📁 新的目录结构

```
stepup_app/
├── releases/                        # 🎯 发行版根目录（独立于 build）
│   ├── windows/                    # Windows 平台发行版
│   │   ├── v1.0.0/                # 版本目录
│   │   │   ├── StepUp_v1.0.0_正式版/
│   │   │   │   ├── stepup_app.exe
│   │   │   │   ├── README.txt
│   │   │   │   ├── version.json
│   │   │   │   └── data/
│   │   │   └── StepUp_v1.0.0_正式版.zip
│   │   ├── v1.0.1/                # 修复版
│   │   └── latest.txt             # 指向最新版本
│   ├── android/                    # Android 平台发行版
│   │   ├── v1.0.0/                # 版本目录
│   │   │   ├── StepUp_v1.0.0_正式版/
│   │   │   │   ├── app-release.apk
│   │   │   │   ├── README.txt
│   │   │   │   └── version.json
│   │   │   └── StepUp_v1.0.0_正式版.zip
│   │   ├── v1.0.1/                # 修复版
│   │   └── latest.txt             # 指向最新版本
│   ├── archive/                   # 历史版本归档
│   └── latest.txt                 # 全局最新版本索引
├── build/                          # Flutter 构建输出（可被 flutter clean 清理）
│   ├── windows/                   # Windows 构建输出
│   │   └── x64/runner/Release/
│   └── app/outputs/flutter-apk/   # Android 构建输出
├── scripts/                        # 🛠️ 版本管理工具
│   ├── package-release.bat        # 打包 Windows 发行版
│   ├── package-android.bat        # 打包 Android 发行版
│   ├── list-versions.bat          # 查看版本列表
│   ├── build-release.ps1          # PowerShell 构建脚本
│   ├── build-android.ps1          # Android 构建脚本
│   ├── manage-versions.ps1        # PowerShell 管理脚本
│   └── config.ps1                # 配置文件
└── .gitignore                     # 忽略 releases/ 目录（可选）
```

> ⚠️ **重要提示**：`releases/` 目录位于项目根目录，独立于 `build/` 目录。
> 这样 `flutter clean` 不会清理已打包的发行版。

## 🚀 版本管理工具

### 1. 打包 Windows 发行版
```bash
# 基本用法
.\scripts\package-release.bat 1.0.3 "新功能版"

# 版本类型示例
.\scripts\package-release.bat 1.0.3 "正式版"
.\scripts\package-release.bat 1.0.4 "修复版"
.\scripts\package-release.bat 1.1.0 "功能版"
.\scripts\package-release.bat 2.0.0 "重大更新版"
```

### 2. 打包 Android 发行版
```bash
# 基本用法
.\scripts\package-android.bat 1.0.3 "新功能版"

# 版本类型示例
.\scripts\package-android.bat 1.0.3 "正式版"
.\scripts\package-android.bat 1.0.4 "修复版"
.\scripts\package-android.bat 1.1.0 "功能版"
```

### 3. 查看版本列表
```bash
# 查看所有平台版本
.\scripts\list-versions.bat

# 查看 Windows 版本
.\scripts\list-versions.bat windows

# 查看 Android 版本
.\scripts\list-versions.bat android
```

### 3. 版本命名规范
- **正式版**: 稳定的功能发布
- **修复版**: Bug修复和小改进
- **功能版**: 新功能添加
- **优化版**: 性能或体验优化
- **测试版**: Beta测试版本

## 📦 发行包内容

### Windows 版本包含：
- `stepup_app.exe` - 主程序
- `README.txt` - 版本说明和使用指南
- `version.json` - 版本元数据
- `data/` - 应用资源和数据
- `*.dll` - 依赖库文件

### Android 版本包含：
- `app-release.apk` - Android 安装包
- `README.txt` - 版本说明和安装指南
- `version.json` - 版本元数据

## 🔄 版本管理流程

### Windows 平台

1. **开发完成** → 确认版本号和描述
2. **构建应用** → `flutter build windows --release`
3. **打包发行** → `package-release.bat [版本] [描述]`
4. **验证测试** → 启动应用确认功能正常
5. **发布分享** → 分享 zip 压缩包

### Android 平台

1. **开发完成** → 确认版本号和描述
2. **构建应用** → `flutter build apk --release`
3. **打包发行** → `package-android.bat [版本] [描述]`
4. **验证测试** → 安装 APK 确认功能正常
   - 使用 `flutter install` 安装到连接的设备
   - 或手动传输 APK 到设备安装
5. **发布分享** → 分享 zip 压缩包或单独 APK 文件

### 多平台同步发布

当需要同时发布 Windows 和 Android 版本时：

1. **更新版本号** → 同步更新 `pubspec.yaml` 中的版本
2. **构建 Windows** → `flutter build windows --release`
3. **构建 Android** → `flutter build apk --release`
4. **打包两个平台** → 分别运行对应的打包脚本
5. **统一版本标记** → 确保两个平台版本号一致

## 📋 版本信息结构

### Windows 版本 `version.json`
```json
{
  "version": "1.0.2",
  "description": "文件存储优化版",
  "buildTime": "2025-08-25 16:30:00",
  "platform": "Windows x64",
  "buildId": "20250825163000"
}
```

### Android 版本 `version.json`
```json
{
  "version": "1.0.2",
  "description": "文件存储优化版",
  "buildTime": "2025-08-25 16:30:00",
  "platform": "Android",
  "buildId": "20250825163000",
  "minSdkVersion": "21",
  "targetSdkVersion": "34"
}
```

## 🗂️ 文件组织优势

### ✅ 优化后的优势：
1. **版本隔离**：每个版本独立目录，避免混乱
2. **清晰结构**：按平台和版本号组织，易于查找
3. **自动化工具**：脚本化管理，减少人工错误
4. **版本追踪**：latest.txt 指向最新版本
5. **历史管理**：archive 目录保存旧版本
6. **标准命名**：统一的文件命名规范
7. **多平台支持**：Windows 和 Android 分开管理

### ❌ 旧架构问题：
- 所有版本混在一个文件夹
- 难以区分不同版本
- 容易误删或覆盖
- 缺乏版本追踪机制
- 不支持多平台构建

## 🛠️ 维护建议

1. **定期清理**：将旧版本移动到 archive 目录
2. **备份重要版本**：保留重要里程碑版本
3. **文档更新**：每次发布更新 README
4. **测试验证**：发布前充分测试
   - Windows：在干净环境中测试运行
   - Android：在真机和模拟器上测试
5. **版本记录**：记录每个版本的主要变更
6. **平台同步**：保持 Windows 和 Android 版本号一致
7. **签名管理**：Android 发布版需要正确配置签名

## � Android 发布注意事项

### 签名配置
发布 Android 应用前需要配置签名：

1. **创建密钥库**（首次）：
```bash
keytool -genkey -v -keystore stepup-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias stepup
```

2. **配置 `android/key.properties`**：
```properties
storePassword=你的密钥库密码
keyPassword=你的密钥密码
keyAlias=stepup
storeFile=../stepup-release-key.jks
```

3. **更新 `android/app/build.gradle`**：
```gradle
android {
    ...
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
        }
    }
}
```

### 版本号管理
Android 版本号在以下位置需要同步更新：
- `pubspec.yaml` 中的 `version` 字段（如 `1.0.0+1`）
- `+` 后面的数字是 Android 的 `versionCode`，每次发布必须递增

### 安装包大小优化
- 使用 `flutter build apk --split-per-abi` 生成按架构分包的 APK
- 或使用 `flutter build appbundle` 生成 AAB 格式用于 Google Play

## �📈 未来扩展

计划扩展功能：
- ✅ 多平台构建支持（Windows + Android）
- 自动版本号递增
- 变更日志生成
- 自动测试集成
- CI/CD 集成
- iOS 平台支持
- macOS 平台支持
- Linux 平台支持
- Web 平台支持

---

*版本管理架构 v2.0 - 2025年2月10日*