> 历史交付说明：2026-10-13 已迁移为独立项目，并提供 `PromptKit.xcodeproj`。当前路径、最低系统版本和运行方法以 [README](README.md) 与 [Xcode 指南](XCODE_LOCAL_BUILD_AND_TEST.md) 为准。

# 🔧 快速修复：'Cannot find DataStore in scope' 错误

## 问题原因
文件存在于磁盘，但 Xcode 没有正确识别它。这是文件未添加到项目编译目标导致的。

## ✅ 快速解决方案（5 分钟）

### 步骤 1：检查文件是否在项目中

1. 在 Xcode 左侧 **Project Navigator** 中查找 `DataStore.swift`
2. 如果找不到或显示为**灰色**，继续下一步

### 步骤 2：重新添加 Services 文件夹

1. **在 Xcode 中**：
   - 如果 `Services` 文件夹存在但文件缺失，右键点击 `Services` → Delete → "Remove References"

2. **添加文件**：
   - 右键点击项目根目录 `PromptKit`
   - 选择 **"Add Files to PromptKit..."**
   - 导航到：`/Users/rgwei/pj/pj_my/prompt_shortcut_tools/PromptKit/Services/`
   - 选择整个 `Services` 文件夹
   - **关键设置**：
     ```
     ✅ Copy items if needed
     ✅ Create groups (黄色文件夹图标)
     ✅ Add to targets: PromptKit
     ```
   - 点击 **"Add"**

3. **验证**：
   - `Services` 文件夹应该显示为**黄色图标**
   - `DataStore.swift` 和 `APIService.swift` 应该显示为**黑色**（不是灰色）

### 步骤 3：检查 Target Membership

1. 选中 `DataStore.swift` 文件
2. 打开右侧的 **File Inspector**（快捷键：⌥⌘1）
3. 在 "Target Membership" 部分找到 `PromptKit`
4. 确保它被**勾选** ✅

### 步骤 4：清理并重新构建

```
Product → Clean Build Folder (⇧⌘K)
Product → Build (⌘B)
```

---

## 🎯 完整添加所有文件的方法（推荐）

如果上面的方法不行，使用这个**彻底的解决方案**：

### 步骤 1：移除所有源文件引用

在 Xcode 中：
1. 选中除了 Xcode 自动生成的 `Assets.xcassets` 和 `Preview Content` 外的所有文件
2. 右键 → **Delete** → 选择 **"Remove References"**（不要选 "Move to Trash"）

### 步骤 2：重新添加所有文件

1. 右键点击项目根目录 `PromptKit`
2. 选择 **"Add Files to PromptKit..."**
3. 导航到：`/Users/rgwei/pj/pj_my/prompt_shortcut_tools/PromptKit/`
4. **一次性选择所有这些项**（按住 ⌘ 多选）：
   ```
   ✅ PromptKitApp.swift
   ✅ ContentView.swift
   ✅ Models (整个文件夹)
   ✅ Services (整个文件夹)
   ✅ Views (整个文件夹)
   ✅ Utils (整个文件夹)
   ```

5. **重要配置**：
   ```
   ✅ Copy items if needed
   ✅ Create groups (不是 "Create folder references")
   ✅ Add to targets: PromptKit
   ```

6. 点击 **"Add"**

### 步骤 3：验证文件结构

你的 Project Navigator 应该看起来像这样：

```
PromptKit
├── PromptKitApp.swift        ← 黑色文本
├── ContentView.swift          ← 黑色文本
├── 📁 Models                  ← 黄色文件夹
│   ├── Prompt.swift          ← 黑色文本
│   └── Tag.swift             ← 黑色文本
├── 📁 Services                ← 黄色文件夹
│   ├── APIService.swift      ← 黑色文本
│   └── DataStore.swift       ← 黑色文本
├── 📁 Views                   ← 黄色文件夹
│   ├── TemplateListView.swift
│   ├── EditPromptView.swift
│   ├── (其他 View 文件...)
├── 📁 Utils                   ← 黄色文件夹
│   └── ColorExtension.swift
├── Assets.xcassets
└── Preview Content
```

**关键检查点**：
- ✅ 文件夹图标是**黄色**（不是蓝色）
- ✅ 文件名是**黑色**（不是灰色）
- ✅ 所有文件都在项目中

### 步骤 4：构建项目

```
⇧⌘K (Clean Build Folder)
⌘B (Build)
```

---

## 🚨 如果还有错误

### 错误：找不到其他类型

如果看到类似的错误：
- `Cannot find 'Prompt' in scope` → 检查 `Models/Prompt.swift`
- `Cannot find 'TemplateListView' in scope` → 检查 `Views/` 文件夹
- `Cannot find 'Color' extension` → 检查 `Utils/ColorExtension.swift`

**解决方法**：确保对应的文件已添加到项目，Target Membership 已勾选。

### 错误：Module compiled with Swift X expected Swift Y

这说明 Swift 版本不匹配：
1. 选择项目 → Build Settings
2. 搜索 "Swift Language Version"
3. 设置为 **Swift 5** 或更高

---

## 💡 验证成功的方法

### 方法 1：代码跳转测试
1. 打开 `ContentView.swift`
2. 找到 `@EnvironmentObject var dataStore: DataStore`
3. 按住 **⌘** 键，点击 `DataStore`
4. 如果能跳转到 `DataStore.swift` 文件，说明添加成功 ✅

### 方法 2：自动补全测试
1. 在任意文件中输入 `Data`
2. Xcode 应该自动提示 `DataStore`
3. 如果有提示，说明添加成功 ✅

### 方法 3：编译测试
```
⌘B (Build)
```
如果构建成功，没有错误，说明所有文件都正确添加 ✅

---

## 🎬 图文操作步骤

### 正确的文件夹图标对比：

**✅ 正确（Groups - 黄色文件夹）**
```
📁 Services (黄色)
  └── DataStore.swift (黑色)
```

**❌ 错误（Folder References - 蓝色文件夹）**
```
📂 Services (蓝色)
  └── DataStore.swift (可能不可点击)
```

如果看到蓝色文件夹：
1. 删除这个引用
2. 重新用 "Create groups" 方式添加

---

## 🔍 终极检查清单

在继续之前，确认：

- [ ] 所有 .swift 文件在 Project Navigator 中显示为**黑色**
- [ ] 文件夹显示为**黄色**图标
- [ ] 每个文件的 Target Membership 都勾选了 `PromptKit`
- [ ] 没有文件显示为灰色或红色
- [ ] 执行了 Clean Build Folder
- [ ] 尝试重新构建

---

## 📞 还是不行？

请执行以下命令并告诉我输出：

```bash
# 检查文件是否存在
ls -la /Users/rgwei/pj/pj_my/prompt_shortcut_tools/PromptKit/Services/

# 检查文件内容
head -5 /Users/rgwei/pj/pj_my/prompt_shortcut_tools/PromptKit/Services/DataStore.swift
```

或者尝试：
1. 完全关闭 Xcode
2. 删除 DerivedData：`rm -rf ~/Library/Developer/Xcode/DerivedData`
3. 重新打开项目
4. 按照上面的步骤重新添加文件

---

**记住：关键是确保文件以 "Create groups" 方式添加，且 Target Membership 被勾选！**
