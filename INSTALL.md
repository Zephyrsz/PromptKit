> 历史交付说明：2026-10-13 已迁移为独立项目，并提供 `PromptKit.xcodeproj`。当前路径、最低系统版本和运行方法以 [README](README.md) 与 [Xcode 指南](XCODE_LOCAL_BUILD_AND_TEST.md) 为准。

# PromptKit iOS 应用安装指南

## 方式一：使用 Xcode 创建项目（推荐）

### 1. 创建新项目
1. 打开 Xcode
2. File -> New -> Project
3. 选择 **iOS** -> **App**
4. 配置项目：
   - **Product Name**: PromptKit
   - **Team**: 选择你的开发者账号（或选择 None）
   - **Organization Identifier**: com.yourname（或其他标识符）
   - **Interface**: SwiftUI
   - **Language**: Swift
   - **Storage**: None
   - 取消勾选 "Include Tests"
5. 选择保存位置并创建

### 2. 添加源代码文件
1. 删除 Xcode 自动生成的 `ContentView.swift`
2. 在 Finder 中打开 `PromptKit` 文件夹
3. 将以下文件夹拖拽到 Xcode 项目中：
   - Models/
   - Services/
   - Views/
   - Utils/
4. 将以下单独文件添加到项目根目录：
   - PromptKitApp.swift
   - ContentView.swift
5. 在弹出的对话框中确保：
   - ✅ "Copy items if needed" 被勾选
   - ✅ "Create groups" 被选中
   - ✅ Target "PromptKit" 被勾选

### 3. 配置网络权限
1. 选择项目 navigator 中的项目文件（蓝色图标）
2. 选择 Target -> PromptKit
3. 选择 "Info" 标签
4. 右键点击列表，选择 "Add Row"
5. 添加以下配置：
   - Key: `App Transport Security Settings` (类型: Dictionary)
   - 展开后添加子项：
     - Key: `Allow Arbitrary Loads` -> Value: `YES` (Boolean)

或者直接编辑 Info.plist：
```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
    <key>NSAllowsLocalNetworking</key>
    <true/>
</dict>
```

### 4. 启动后端服务
在终端中运行：
```bash
cd /Users/rgwei/pj/pj_my/prompt_shortcut_tools
npm run dev
```

确保服务运行在 `http://127.0.0.1:3001`

### 5. 运行应用
1. 在 Xcode 顶部选择目标设备（推荐 iPhone 14 Pro 模拟器）
2. 点击运行按钮 ▶️ 或按 `Cmd + R`
3. 等待编译完成，应用会自动启动

## 方式二：使用现有 Xcode 项目文件

如果项目已经包含 `.xcodeproj` 文件：

1. 双击 `PromptKit.xcodeproj` 文件
2. Xcode 自动打开项目
3. 选择目标设备
4. 点击运行 ▶️

## 配置说明

### 修改 API 地址
如果后端运行在不同的地址，修改 `Services/APIService.swift`：

```swift
private let baseURL = "http://your-server-address:port/api"
```

### 支持的 iOS 版本
- 最低支持：iOS 15.0
- 推荐：iOS 16.0+

### 测试设备
推荐使用以下设备测试：
- iPhone 14 Pro（模拟器）
- iPhone 13（模拟器）
- iPad Pro 12.9"（模拟器）

## 常见问题

### Q: 编译错误 "Cannot find type 'XXX' in scope"
**A**: 确保所有文件都已正确添加到项目中。检查 Project Navigator 左侧文件列表。

### Q: 网络请求失败
**A**: 检查：
1. 后端服务是否正在运行
2. Info.plist 中网络权限是否已配置
3. API 地址是否正确

### Q: 模拟器运行缓慢
**A**:
1. 选择较新的模拟器设备（iPhone 14 系列）
2. 减少同时运行的应用
3. 重启 Xcode 和模拟器

### Q: 真机调试
**A**: 需要：
1. 加入 Apple Developer Program（$99/年）
2. 在 Xcode 中登录 Apple ID
3. 选择开发团队
4. 连接设备并信任证书

## 目录结构

```
PromptKit/
├── PromptKitApp.swift          # 应用入口
├── ContentView.swift            # 主视图（TabView）
├── Models/
│   ├── Prompt.swift            # Prompt 数据模型
│   └── Tag.swift               # Tag 数据模型
├── Services/
│   ├── APIService.swift        # API 通信服务
│   └── DataStore.swift         # 数据管理（ObservableObject）
├── Views/
│   ├── TemplateListView.swift  # 模板列表页
│   ├── EditPromptView.swift    # 创建/编辑模板页
│   ├── PromptDetailView.swift  # 模板详情页
│   ├── QuickAccessView.swift   # 快捷贴贴页
│   ├── SettingsView.swift      # 设置页
│   ├── TagPickerView.swift     # 标签选择器
│   ├── VariableInputView.swift # 变量输入页
│   └── TemplateReferenceView.swift # 预设模板参考
└── Utils/
    └── ColorExtension.swift     # 颜色扩展和主题定义
```

## 下一步

1. 启动应用后，可以：
   - 创建新的 Prompt 模板
   - 添加标签分类
   - 使用快捷贴贴功能
   - 探索设置选项

2. 开发建议：
   - 使用 Xcode 的 Live Preview 功能快速预览界面
   - 查看控制台日志排查问题
   - 使用断点调试网络请求

## 支持

如有问题，请查看：
- README.md - 项目整体说明
- 源代码注释
- 后端 API 文档
