# PromptKit iOS App

基于 prompt_shortcut_tools 的 iOS 应用。2026-10-13 已迁移为独立本地仓库。

## 本地运行

直接用 Xcode 27 打开 `PromptKit.xcodeproj`，选择 `PromptKit` Scheme 和 iPhone 模拟器，按 `⌘B` 构建、`⌘R` 运行、`⌘U` 执行测试。最低 iOS 16，Swift 5 语言模式。

后端仍位于 `/Users/rgwei/pj/pj_my/prompt_shortcut_tools`，需单独启动；本项目只包含 iPhone App。详见 [Xcode 本地构建与测试指南](XCODE_LOCAL_BUILD_AND_TEST.md)。

`PromptKitTests` 使用 XCTest 验证后端 JSON 解码；`PromptKitUITests` 验证三个主标签页的切换。当前覆盖范围有限，未覆盖后端增删改查、同步、导出。

## 功能特性

### 1. 模板管理
- ✅ 创建、编辑、删除 Prompt 模板
- ✅ 搜索和筛选模板
- ✅ 模板标签分类
- ✅ 收藏功能
- ✅ 模板变量支持（可替换项）
- ✅ 预设模板参考

### 2. 快捷贴贴
- ✅ 快速访问收藏的模板
- ✅ 快速填写模板变量
- ✅ 一键复制生成结果
- ✅ 搜索快捷模板

### 3. 设置
- ✅ 标签管理（创建、删除标签）
- 数据导出入口（功能待实现）
- iCloud 同步开关（同步功能待实现）
- ✅ 语言和外观设置
- ✅ 关于、隐私政策、服务条款

## 技术架构

### 项目结构
```
PromptKit/
├── PromptKitApp.swift          # 应用入口
├── ContentView.swift            # 主 TabView
├── Models/                      # 数据模型
│   ├── Prompt.swift
│   └── Tag.swift
├── Services/                    # 服务层
│   ├── APIService.swift        # API 通信
│   └── DataStore.swift         # 数据管理
├── Views/                       # 视图层
│   ├── TemplateListView.swift  # 模板列表
│   ├── EditPromptView.swift    # 编辑模板
│   ├── PromptDetailView.swift  # 模板详情
│   ├── QuickAccessView.swift   # 快捷贴贴
│   ├── SettingsView.swift      # 设置
│   ├── TagPickerView.swift     # 标签选择
│   ├── VariableInputView.swift # 变量输入
│   └── TemplateReferenceView.swift # 预设模板
└── Utils/                       # 工具类
    └── ColorExtension.swift     # 颜色扩展
```

### 技术栈
- **框架**: SwiftUI
- **最低支持**: iOS 16.0+
- **架构**: MVVM
- **网络**: URLSession + async/await
- **数据存储**: 通过 API 与后端通信

### 设计系统
采用深色主题，颜色分层设计：
- **Surface Levels**:
  - surface1: `#05070C` (最深)
  - surface2: `#0A0D12`
  - surface3: `#0F131C`
  - surface4: `#161D2B`
  - surface5: `#1E2636`
- **Accent Colors**:
  - Primary: `#38BDF8` (青色)
  - Secondary: `#6EE7B7` (绿色)
- **Text Colors**:
  - Primary: 白色
  - Secondary: 白色 70% 透明度
  - Tertiary: 白色 50% 透明度

## 配置说明

### API 配置
在 `Services/APIService.swift` 中修改 `baseURL`：

```swift
private let baseURL = "http://127.0.0.1:3001/api"
```

修改为你的服务器地址。

### 启动后端服务
```bash
cd /path/to/prompt_shortcut_tools
npm run dev
```

## 使用 Xcode 打开项目

1. 打开仓库根目录的 `PromptKit.xcodeproj`，无需重新创建工程或导入源码。
2. 选择 `PromptKit` Scheme 和具体 iPhone 模拟器，按 `⌘R`。
3. 真机运行时在 Signing & Capabilities 中选择自己的 Team，并调整 Bundle Identifier。
4. API 默认连接 `http://127.0.0.1:3001/api`。模拟器可访问 Mac 的后端；真机需要修改为 Mac 的局域网地址。工程已声明本地网络用途和本地联网 ATS 设置，发布服务应使用 HTTPS。

共享 Scheme、全部源码和工程文件已纳入版本管理；个人 Xcode 设置、构建产物不提交。

## API 接口

应用使用以下 API 接口：

### Prompts
- `GET /api/prompts` - 获取所有模板
- `GET /api/prompts/:id` - 获取单个模板
- `POST /api/prompts` - 创建模板
- `PUT /api/prompts/:id` - 更新模板
- `DELETE /api/prompts/:id` - 删除模板
- `PUT /api/prompts` - 切换收藏状态

### Tags
- `GET /api/tags` - 获取所有标签
- `POST /api/tags` - 创建标签
- `DELETE /api/tags/:id` - 删除标签

## 待实现功能

- [ ] 导入模板功能
- [ ] 批量选择和删除
- [ ] iCloud 同步实现
- [ ] 数据导出功能实现
- [ ] Pro 版本升级
- [ ] 反馈和评分功能
- [ ] QQ 交流群跳转
- [ ] 模板分享功能
- [ ] 离线模式支持

## 开发说明

### 添加新功能
1. 在 `Models/` 中添加数据模型
2. 在 `Services/APIService.swift` 中添加 API 方法
3. 在 `Services/DataStore.swift` 中添加业务逻辑
4. 在 `Views/` 中创建对应的视图

### 修改主题颜色
在 `Utils/ColorExtension.swift` 中修改颜色定义。

### 调试
- 使用 Xcode 的调试工具
- 查看控制台日志
- 使用断点调试

## 许可证

与 Web 版本保持一致。

## 贡献

欢迎提交 Issue 和 Pull Request。
