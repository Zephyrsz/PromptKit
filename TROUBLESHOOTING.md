> 历史交付说明：2026-10-13 已迁移为独立项目，并提供 `PromptKit.xcodeproj`。当前路径、最低系统版本和运行方法以 [README](README.md) 与 [Xcode 指南](XCODE_LOCAL_BUILD_AND_TEST.md) 为准。

# ❌ 编译错误修复指南

## 错误：'Cannot find 'DataStore' in scope'

### 🔍 问题原因

这个错误表示 Xcode 无法找到 `DataStore` 类，通常是因为：
1. 文件未正确添加到项目
2. Target Membership 未勾选
3. 文件不在正确的编译顺序中

### ✅ 解决方案

#### 方法 1：检查文件是否正确添加（推荐）

1. **查看 Project Navigator**（左侧文件列表）
   - 确保所有文件都显示为**黑色**（不是灰色）
   - 确保文件夹结构完整：
     ```
     PromptKit
     ├── Models
     │   ├── Prompt.swift
     │   └── Tag.swift
     ├── Services
     │   ├── APIService.swift
     │   └── DataStore.swift  ← 确保这个文件在这里
     ├── Views
     │   └── (所有 View 文件)
     ├── Utils
     │   └── ColorExtension.swift
     ├── ContentView.swift
     └── PromptKitApp.swift
     ```

2. **检查 Target Membership**
   - 选中 `DataStore.swift` 文件
   - 打开右侧的 File Inspector（⌥⌘1）
   - 在 "Target Membership" 部分
   - 确保 **PromptKit 被勾选** ✅

3. **如果文件显示为灰色或不存在**
   - 右键点击 `Services` 文件夹
   - 选择 "Add Files to PromptKit..."
   - 导航到：`/Users/rgwei/pj/pj_my/prompt_shortcut_tools/PromptKit/Services/`
   - 选择 `DataStore.swift`
   - 确保勾选：
     - ✅ "Copy items if needed"
     - ✅ "Create groups"
     - ✅ Target: PromptKit

#### 方法 2：重新添加所有文件（彻底解决）

如果问题持续，建议重新添加所有文件：

1. **在 Xcode 中删除所有源文件**
   - 选中所有 Swift 文件（除了自动生成的）
   - 右键 → Delete → "Remove References"（不要选 "Move to Trash"）

2. **重新添加文件**
   - 右键点击项目根目录
   - "Add Files to PromptKit..."
   - 导航到 `/Users/rgwei/pj/pj_my/prompt_shortcut_tools/PromptKit/`
   - 选择所有文件夹（Models, Services, Views, Utils）和文件
   - **重要**：确保勾选：
     ```
     ✅ Copy items if needed
     ✅ Create groups (不要选 "Create folder references")
     ✅ Add to targets: PromptKit
     ```
   - 点击 "Add"

3. **验证文件结构**
   - 所有文件应该显示为**黑色**
   - 文件夹应该显示为**黄色图标**（groups）
   - 不应该有蓝色文件夹图标（folder references）

#### 方法 3：清理并重新构建

1. **清理项目**
   ```
   Product → Clean Build Folder (⇧⌘K)
   ```

2. **删除 DerivedData**
   ```
   Xcode → Preferences → Locations
   点击 DerivedData 路径旁的箭头
   删除你的项目文件夹
   ```

3. **重新构建**
   ```
   Product → Build (⌘B)
   ```

### 🔧 完整的文件添加检查清单

打开 Xcode，确保以下所有文件都存在且为黑色：

```
☐ PromptKitApp.swift
☐ ContentView.swift
☐ Models/Prompt.swift
☐ Models/Tag.swift
☐ Services/APIService.swift
☐ Services/DataStore.swift        ← 特别检查这个
☐ Views/TemplateListView.swift
☐ Views/EditPromptView.swift
☐ Views/PromptDetailView.swift
☐ Views/QuickAccessView.swift
☐ Views/SettingsView.swift
☐ Views/TagPickerView.swift
☐ Views/VariableInputView.swift
☐ Views/TemplateReferenceView.swift
☐ Utils/ColorExtension.swift
```

### 🎯 快速验证脚本

在 Xcode 中，尝试这个测试：

1. 打开 `ContentView.swift`
2. 在顶部添加：
   ```swift
   import Foundation
   ```
3. 按住 `⌘` 键，点击 `DataStore`
4. 如果能跳转到 `DataStore.swift`，说明文件正确添加
5. 如果不能跳转，说明文件未正确添加到项目

### 🐛 其他常见错误

如果修复后还有其他类似错误：

#### "Cannot find 'Prompt' in scope"
→ 添加 `Models/Prompt.swift`

#### "Cannot find 'Tag' in scope"
→ 添加 `Models/Tag.swift`

#### "Cannot find 'Color' extension methods"
→ 添加 `Utils/ColorExtension.swift`

#### "Cannot find type 'TemplateListView'"
→ 添加 `Views/TemplateListView.swift`

### 💡 预防措施

为了避免这个问题，添加文件时始终：

1. ✅ 使用 "Add Files to..." 而不是直接拖拽
2. ✅ 勾选 "Copy items if needed"
3. ✅ 选择 "Create groups" 而不是 "Create folder references"
4. ✅ 确保 Target 被勾选
5. ✅ 验证文件显示为黑色

### 📞 如果问题仍然存在

请检查：

1. **文件是否存在于磁盘上**
   ```bash
   ls -la /Users/rgwei/pj/pj_my/prompt_shortcut_tools/PromptKit/Services/
   ```
   应该能看到 `DataStore.swift`

2. **文件内容是否正确**
   ```bash
   head -20 /Users/rgwei/pj/pj_my/prompt_shortcut_tools/PromptKit/Services/DataStore.swift
   ```
   应该能看到 `class DataStore: ObservableObject`

3. **Xcode 版本**
   - 确保使用 Xcode 14.0 或更高版本
   - 确保选择了正确的 SDK

### 🎬 视频指导

如果文字说明不够清楚，按照这个顺序：

1. **删除所有文件**（保留项目结构）
2. **关闭 Xcode**
3. **重新打开 Xcode**
4. **File → Add Files to "PromptKit"**
5. **选择整个 PromptKit 文件夹（除了 .xcodeproj）**
6. **勾选 "Copy items if needed" + "Create groups"**
7. **点击 Add**
8. **Build (⌘B)**

### ✅ 成功标志

当问题解决后，你应该能：
- 编译通过（无错误）
- ⌘+点击 `DataStore` 能跳转到源文件
- 在 Project Navigator 中看到所有文件为黑色
- 运行应用成功

---

**需要更多帮助？**
- 检查 QUICKSTART.md 第 "添加源代码文件" 部分
- 确保按照步骤仔细操作
- 所有文件都在正确的位置
