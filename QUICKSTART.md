> 历史交付说明：2026-10-13 已迁移为独立项目，并提供 `PromptKit.xcodeproj`。当前路径、最低系统版本和运行方法以 [README](README.md) 与 [Xcode 指南](XCODE_LOCAL_BUILD_AND_TEST.md) 为准。

# PromptKit iOS 应用 - 快速开始指南

## 📱 项目概述

PromptKit iOS 是基于 Web 版 prompt_shortcut_tools 开发的原生 iOS 应用，提供完整的 Prompt 模板管理功能。

## ✨ 主要功能

### 1. 模板管理（Template Management）
- 创建、编辑、删除 Prompt 模板
- 搜索和筛选功能
- 标签分类管理
- 收藏功能
- 模板变量支持（替换项）
- 预设模板参考

### 2. 快捷贴贴（Quick Access）
- 快速访问收藏的模板
- 快速填写变量并生成文本
- 一键复制到剪贴板

### 3. 设置（Settings）
- 标签管理
- 数据导出
- iCloud 同步（开关）
- 语言和外观设置

## 🚀 快速开始

### 步骤 1: 准备后端服务

确保 Web 版后端服务正在运行：

```bash
cd /Users/rgwei/pj/pj_my/prompt_shortcut_tools
npm install  # 如果还未安装依赖
npm run dev  # 启动开发服务器
```

服务应该运行在 `http://127.0.0.1:3001`

### 步骤 2: 使用 Xcode 创建项目

#### 方法 A: 创建新项目（推荐）

1. **打开 Xcode**，选择 "Create a new Xcode project"

2. **选择模板**:
   - 平台: iOS
   - 应用模板: App
   - 点击 Next

3. **配置项目**:
   - Product Name: `PromptKit`
   - Team: 选择你的开发者账号（如果没有，选择 "None" 或添加 Apple ID）
   - Organization Identifier: `com.yourname`（或任意标识符）
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Storage: None
   - 取消勾选所有测试选项
   - 点击 Next

4. **选择保存位置**（建议保存在项目文件夹外，避免覆盖）

5. **添加源代码文件**:
   - 删除 Xcode 自动创建的 `ContentView.swift`
   - 在 Xcode 左侧项目导航器中，右键点击 `PromptKit` 文件夹
   - 选择 "Add Files to PromptKit..."
   - 导航到 `/Users/rgwei/pj/pj_my/prompt_shortcut_tools/PromptKit/`
   - 选择以下所有文件夹和文件（按住 Cmd 多选）:
     - PromptKitApp.swift
     - ContentView.swift
     - Models/ (整个文件夹)
     - Services/ (整个文件夹)
     - Views/ (整个文件夹)
     - Utils/ (整个文件夹)
   - 确保勾选：
     - ✅ "Copy items if needed"
     - ✅ "Create groups"
     - ✅ Target: PromptKit
   - 点击 "Add"

6. **配置网络权限**:
   - 在项目导航器中选择最顶层的项目文件（蓝色图标）
   - 选择 Target "PromptKit"
   - 选择 "Info" 标签页
   - 如果看不到列表，点击底部的 "+" 按钮
   - 添加以下键值对：
     - Key: `App Transport Security Settings` (类型选 Dictionary)
     - 展开这一行，点击旁边的 "+"
     - 添加子项: `Allow Arbitrary Loads` = `YES` (Boolean)
     - 再添加一个子项: `NSAllowsLocalNetworking` = `YES` (Boolean)

   **或者直接编辑 Info.plist 文件**（在项目导航器中找到 Info.plist）:
   ```xml
   <key>NSAppTransportSecurity</key>
   <dict>
       <key>NSAllowsArbitraryLoads</key>
       <true/>
       <key>NSAllowsLocalNetworking</key>
       <true/>
   </dict>
   ```

### 步骤 3: 运行应用

1. **选择目标设备**:
   - 在 Xcode 顶部工具栏，点击设备选择器
   - 推荐选择: **iPhone 14 Pro** 或 **iPhone 15 Pro** 模拟器

2. **构建并运行**:
   - 点击左上角的播放按钮 ▶️
   - 或按快捷键 `Cmd + R`
   - 首次运行会编译所有代码（可能需要 1-2 分钟）

3. **测试功能**:
   - 应用启动后会自动从后端加载数据
   - 尝试创建一个新模板
   - 添加标签
   - 使用快捷贴贴功能

## 📂 项目结构

```
PromptKit/
├── PromptKitApp.swift              # 应用入口点
├── ContentView.swift                # 主 TabView（三个标签页）
│
├── Models/                          # 数据模型层
│   ├── Prompt.swift                # Prompt 模型
│   └── Tag.swift                   # Tag 模型
│
├── Services/                        # 服务层
│   ├── APIService.swift            # API 网络请求服务
│   └── DataStore.swift             # 全局数据状态管理
│
├── Views/                           # 视图层
│   ├── TemplateListView.swift      # 📄 模板列表页（Tab 1）
│   ├── EditPromptView.swift        # ✏️ 创建/编辑模板页
│   ├── PromptDetailView.swift      # 📋 模板详情页
│   ├── QuickAccessView.swift       # ⚡ 快捷贴贴页（Tab 2）
│   ├── SettingsView.swift          # ⚙️ 设置页（Tab 3）
│   ├── TagPickerView.swift         # 🏷️ 标签选择器
│   ├── VariableInputView.swift     # 📝 变量输入页
│   └── TemplateReferenceView.swift # 💡 预设模板参考
│
├── Utils/                           # 工具类
│   └── ColorExtension.swift        # 颜色扩展和主题定义
│
├── README.md                        # 项目说明
├── INSTALL.md                       # 详细安装指南
└── project.json                     # 项目配置信息
```

## 🎨 设计特点

应用采用**深色主题**，使用分层的表面颜色系统：

- **Surface 层级** (从深到浅):
  - Level 1: `#05070C` - 最深背景
  - Level 2: `#0A0D12`
  - Level 3: `#0F131C` - 卡片背景
  - Level 4: `#161D2B`
  - Level 5: `#1E2636`

- **强调色**:
  - Primary: `#38BDF8` (青色/蓝色)
  - Secondary: `#6EE7B7` (绿色)

- **文字颜色**:
  - Primary: 白色 100%
  - Secondary: 白色 70%
  - Tertiary: 白色 50%

## 🔧 配置选项

### 修改 API 地址

如果后端服务运行在不同的地址，编辑 `Services/APIService.swift`:

```swift
class APIService {
    static let shared = APIService()

    // 修改这里的地址
    private let baseURL = "http://your-server:port/api"

    // ...
}
```

### 支持的 iOS 版本

- 最低支持: **iOS 15.0**
- 推荐: **iOS 16.0+**
- 完全支持: **iOS 17.0+**

## 🐛 故障排除

### 问题 1: 编译错误 "Cannot find type"

**原因**: 文件未正确添加到项目中

**解决方案**:
1. 检查 Project Navigator 左侧，确保所有 `.swift` 文件都在项目中
2. 每个文件应该显示在对应的文件夹下
3. 右键点击文件 -> "Show File Inspector"，确保 "Target Membership" 中 PromptKit 被勾选

### 问题 2: 网络请求失败

**原因**:
- 后端服务未启动
- 网络权限未配置
- API 地址不正确

**解决方案**:
1. 确认后端运行: `curl http://127.0.0.1:3001/api/prompts`
2. 检查 Info.plist 中的网络权限配置
3. 查看 Xcode 控制台的错误信息

### 问题 3: 模拟器启动慢

**解决方案**:
1. 使用较新的设备型号（iPhone 14/15 系列）
2. 关闭其他占用资源的应用
3. Xcode -> Product -> Clean Build Folder
4. 重启 Xcode

### 问题 4: 数据加载失败

**检查清单**:
- [ ] 后端服务正在运行（`npm run dev`）
- [ ] 数据库文件存在（`prisma/prompts.db`）
- [ ] 网络权限已配置
- [ ] API 地址正确
- [ ] 查看 Xcode 控制台日志

## 📱 真机测试

如需在真实 iPhone 或 iPad 上运行：

1. **免费方式**（个人开发）:
   - 在 Xcode 中登录你的 Apple ID
   - Preferences -> Accounts -> 添加 Apple ID
   - 选择 Target -> Signing & Capabilities
   - Team: 选择你的个人团队
   - 连接设备
   - 信任开发者证书（设备 -> 设置 -> 通用 -> VPN与设备管理）

2. **付费方式**（App Store 发布）:
   - 加入 Apple Developer Program（$99/年）
   - 配置证书和描述文件
   - 可以发布到 App Store

## 🎯 下一步

完成基础安装后，你可以：

1. **探索功能**:
   - 创建几个测试模板
   - 添加标签和分类
   - 使用变量替换功能
   - 测试快捷贴贴

2. **自定义**:
   - 修改主题颜色（`Utils/ColorExtension.swift`）
   - 添加新的预设模板（`TemplateReferenceView.swift`）
   - 扩展 API 功能

3. **开发**:
   - 实现数据导出功能
   - 添加 iCloud 同步
   - 实现离线模式
   - 添加 Widget 支持

## 📚 相关文档

- [README.md](README.md) - 项目详细说明
- [INSTALL.md](INSTALL.md) - 完整安装指南
- [项目 Web 版](../README.md) - Web 版本文档

## 💡 提示

- 使用 Xcode 的 **Live Preview** 功能快速预览界面更改
- 启用 **SwiftUI Inspectors** 查看视图层级
- 使用 **断点调试** 排查网络请求问题
- 查看 **Console** 输出了解运行时信息

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

## 📄 许可证

与 Web 版本保持一致
