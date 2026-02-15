# StepUp综测系统 - 版本管理架构

## 📁 目录结构

```
stepup_app/
├── releases/                        # 发行版根目录（独立于 build）
│   └── v{版本号}/                   # 版本目录（如 v1.2.5）
│       ├── StepUp_v{版本号}_windows.zip   # Windows 压缩包
│       ├── StepUp_v{版本号}_android.apk   # Android 安装包
│       └── StepUp_Setup_v{版本号}.exe     # Windows 安装程序
├── build/                          # Flutter 构建输出（可被 flutter clean 清理）
│   ├── windows/x64/runner/Release/ # Windows 构建输出
│   └── app/outputs/flutter-apk/    # Android 构建输出
├── installer/                      # Windows 安装程序配置
│   └── setup.iss                   # Inno Setup 脚本
└── scripts/                        # 构建打包脚本（Python）
    ├── build.py                    # 构建脚本
    ├── package.py                  # 打包脚本
    └── build_and_package.py        # 一键构建打包脚本
```

> **重要提示**：`releases/` 目录位于项目根目录，独立于 `build/` 目录，`flutter clean` 不会清理已打包的发行版。

## 🚀 快速开始

### 一键构建打包（推荐）

```bash
cd stepup_app/scripts
python build_and_package.py 1.2.5
```

只需要提供版本号，自动完成：
1. 更新 `pubspec.yaml` 版本号
2. 清理构建缓存
3. 获取依赖
4. 构建 Windows 版本
5. 构建 Android 版本
6. 打包所有平台

### 单独构建

```bash
# 只构建
python build.py 1.2.5

# 只打包（需要先构建）
python package.py 1.2.5
```

## 🛠️ 脚本说明

### build.py - 构建脚本

**用法**: `python build.py [版本号]`

**功能**:
- 更新 `pubspec.yaml` 版本号
- 执行 `flutter clean` 清理缓存
- 执行 `flutter pub get` 获取依赖
- 构建 Windows 版本 (`flutter build windows --release`)
- 构建 Android 版本 (`flutter build apk --release`)
- 使用国内镜像加速 Flutter 资源下载

**示例**:
```bash
python build.py 1.2.5
```

### package.py - 打包脚本

**用法**: `python package.py [版本号]`

**功能**:
- 打包 Windows 版本为 ZIP 压缩包
- 复制 Android APK 文件
- 编译 Windows 安装程序（需要 Inno Setup）
- 更新 `setup.iss` 版本号
- 输出到 `releases/v{版本号}/` 目录

**示例**:
```bash
python package.py 1.2.5
```

### build_and_package.py - 一键构建打包

**用法**: `python build_and_package.py [版本号]`

**功能**:
- 依次调用 `build.py` 和 `package.py`
- 完成从构建到打包的完整流程

**示例**:
```bash
python build_and_package.py 1.2.5
```

## 📦 输出文件

运行脚本后，在 `releases/v{版本号}/` 目录下会生成：

| 文件名 | 说明 |
|--------|------|
| `StepUp_v{版本号}_windows.zip` | Windows 便携版（解压即用） |
| `StepUp_v{版本号}_android.apk` | Android 安装包 |
| `StepUp_Setup_v{版本号}.exe` | Windows 安装程序（需要 Inno Setup） |

## ⚙️ 环境要求

### 必需
- Python 3.x
- Flutter SDK
- Android SDK（用于构建 Android）
- Visual Studio（用于构建 Windows）

### 可选
- Inno Setup 6（用于生成 Windows 安装程序）

## 🔧 配置说明

### 国内镜像

构建脚本已配置国内镜像加速：
- `FLUTTER_STORAGE_BASE_URL`: https://storage.flutter-io.cn
- `PUB_HOSTED_URL`: https://pub.flutter-io.cn

### 安装程序配置

`installer/setup.iss` 是 Inno Setup 脚本，打包时会自动更新版本号。

如需修改安装程序：
1. 编辑 `installer/setup.iss`
2. 重新运行 `python package.py [版本号]`

## 📝 版本号规范

使用语义化版本号格式：`主版本.次版本.修订号`

示例：
- `1.0.0` - 初始版本
- `1.2.0` - 新增功能
- `1.2.5` - 修复问题
- `2.0.0` - 重大更新

## � 发布流程

1. **更新版本号**：确定新版本号（如 `1.2.5`）
2. **运行脚本**：`python build_and_package.py 1.2.5`
3. **等待完成**：脚本自动完成构建和打包
4. **验证文件**：检查 `releases/v1.2.5/` 目录下的文件
5. **发布分享**：分享生成的 ZIP、APK 和安装程序

## 🗑️ 清理

如需清理构建缓存：
```bash
flutter clean
```

如需删除所有发行版：
```bash
# 手动删除 releases/ 目录
rmdir /s releases
```

## � 注意事项

1. **首次构建**：首次构建可能需要下载依赖，耗时较长
2. **Android 签名**：发布 Android 应用需要配置签名，参见下方说明
3. **Inno Setup**：如需生成安装程序，请先安装 Inno Setup 6
4. **磁盘空间**：确保有足够的磁盘空间（建议至少 5GB）

## 🔐 Android 签名配置

### 创建密钥库

```bash
cd android
keytool -genkey -v -keystore stepup-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias stepup
```

### 配置 key.properties

创建 `android/key.properties`：
```properties
storePassword=你的密钥库密码
keyPassword=你的密钥密码
keyAlias=stepup
storeFile=stepup-release-key.jks
```

### 配置 build.gradle

在 `android/app/build.gradle` 中添加：
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

## 📈 未来扩展

- [ ] 自动版本号递增
- [ ] 变更日志生成
- [ ] CI/CD 集成
- [ ] iOS/macOS/Linux 平台支持
- [ ] Web 平台支持

---

*版本管理架构 v4.0 - 2026年2月15日*
