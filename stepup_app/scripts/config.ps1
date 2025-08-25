# StepUp版本管理配置文件
# 该文件定义了版本管理的各种配置选项

# 项目信息
$Global:ProjectConfig = @{
    Name = "StepUp综合测评系统"
    ProjectRoot = "c:\Users\Lenovo\Documents\GitHub\StepUp\stepup_app"
    BuildRoot = "c:\Users\Lenovo\Documents\GitHub\StepUp\stepup_app\build"
    ReleasesRoot = "c:\Users\Lenovo\Documents\GitHub\StepUp\stepup_app\build\releases"
    ArchiveRoot = "c:\Users\Lenovo\Documents\GitHub\StepUp\stepup_app\build\archive"
    ScriptsRoot = "c:\Users\Lenovo\Documents\GitHub\StepUp\stepup_app\scripts"
}

# 版本类型定义
$Global:VersionTypes = @{
    "major" = @{
        Description = "正式版"
        Color = "Green"
        Icon = "🚀"
    }
    "minor" = @{
        Description = "功能版"
        Color = "Blue"
        Icon = "⭐"
    }
    "patch" = @{
        Description = "修复版"
        Color = "Yellow"
        Icon = "🔧"
    }
    "beta" = @{
        Description = "测试版"
        Color = "Orange"
        Icon = "🧪"
    }
    "alpha" = @{
        Description = "内测版"
        Color = "Purple"
        Icon = "🔬"
    }
}

# 构建配置
$Global:BuildConfig = @{
    Platform = "windows"
    Architecture = "x64"
    BuildMode = "release"
    CleanBeforeBuild = $true
    SkipTests = $false
    GenerateDebugInfo = $false
}

# 打包配置
$Global:PackageConfig = @{
    IncludeReadme = $true
    IncludeVersionInfo = $true
    IncludeLicense = $false
    CreateZip = $true
    CompressionLevel = "Optimal"
}

# 归档配置
$Global:ArchiveConfig = @{
    KeepVersionCount = 5  # 保留最新几个版本
    AutoArchiveOldVersions = $true
    ArchiveFormat = "timestamp"  # timestamp 或 counter
}

# 通知配置
$Global:NotificationConfig = @{
    ShowBuildProgress = $true
    ShowFileDetails = $true
    ShowSizeInfo = $true
    UseColorOutput = $true
}

# 模板配置
$Global:Templates = @{
    ReadmeTemplate = @"
{ProjectName} v{Version} {Description}
{Separator}

这是一个用于管理大学生综合测评条目的桌面应用程序。

版本信息：
=========
- 版本号：v{Version}
- 版本类型：{Description}
- 构建时间：{BuildTime}
- 目标平台：{Platform}

安装和运行：
===========
1. 本应用为便携式版本，无需安装
2. 直接双击 stepup_app.exe 启动应用
3. 首次运行会自动创建数据库文件和证明材料目录

主要功能：
=========
- ✅ 综合测评条目管理
- ✅ 分类和级别管理
- ✅ 证明材料上传（图片和文档）
- ✅ 数据统计和分析
- ✅ 文件预览功能
- ✅ 外部应用打开文件

系统要求：
=========
- Windows 10 或更高版本
- 64位操作系统
- 约30MB可用磁盘空间

技术支持：
=========
如有问题，请联系开发团队

发布信息：
=========
- 版本：v{Version} {Description}
- 发布日期：{BuildDate}
- 构建ID：{BuildId}
"@

    VersionInfoTemplate = @"
{
    "version": "{Version}",
    "description": "{Description}",
    "buildTime": "{BuildTime}",
    "buildDate": "{BuildDate}",
    "platform": "{Platform}",
    "architecture": "{Architecture}",
    "buildId": "{BuildId}",
    "projectName": "{ProjectName}",
    "features": [
        "综合测评条目管理",
        "分类和级别管理", 
        "证明材料上传",
        "数据统计分析",
        "文件预览功能"
    ]
}
"@
}

# 导出配置
Export-ModuleMember -Variable ProjectConfig, VersionTypes, BuildConfig, PackageConfig, ArchiveConfig, NotificationConfig, Templates