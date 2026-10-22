# PromptKit iOS App

从 `prompt_shortcut_tools` Web 项目重构的 iPhone 提示词工具。SwiftUI，最低 iOS 16，Swift 5 语言模式。

## 本地运行

用 Xcode 打开 `PromptKit.xcodeproj`，选择 `PromptKit` Scheme 和 iPhone 模拟器，按 `⌘R` 运行，`⌘U` 执行测试。真机需在 Signing & Capabilities 中选择自己的开发团队。

**2026-10-22 起，日常使用完全基于 iPhone 本地 SQLite，不需要启动 Web 后端。**

## 笔记与模板

- **提示词笔记**：保存完整提示词，直接复制使用。即使正文含 `${示例}` 或 `{{示例}}`，也会原样复制，不要求填空。
- **模板**：保存含填空项的原始正文。支持 Web 的 `${变量}` 和旧 iOS 的 `{{变量}}`，支持中文变量名，按正文顺序自动识别和去重。填写时实时显示结果，填齐后可“生成并复制”。修改填写内容会立即更新结果。
- 首页可按“全部／笔记／模板”筛选，支持搜索标题、描述、正文和标签。
- 创建菜单提供“新建提示词笔记”和“新建模板”，编辑时可切换类型。模板至少需要一个填空项；笔记无需填空项。
- 编辑保留收藏、描述、使用说明和创建时间；详情始终显示最新保存的内容。
- 收藏的笔记与模板都出现在“快捷贴贴”。

## 标签

在“设置 → 标签管理”创建、删除标签，也可在编辑器的“选择标签”中直接创建。创建成功后，新标签自动选中；失败时保留输入并显示原因。

名称会去除首尾空白，空名称和重复名称不允许保存。仍被笔记或模板使用的标签不能删除，应先编辑相关内容移除引用。

## 存储

数据路径：

```text
SwiftUI → DataStore → SQLiteStore → Application Support/PromptKit/PromptKit.sqlite
```

使用系统 `SQLite3`，没有新增第三方依赖，不使用 UserDefaults 存储笔记。`prompts` 和 `tags` 两张表保存正文、类型、标签、收藏、变量、描述、使用说明及时间。数组字段使用 JSON 文本；日期使用 Unix 秒；主键自增，不复用已删除记录的 ID。数据库通过 `PRAGMA user_version` 管理版本，启用 WAL。

只有数据库写入成功才刷新界面并关闭编辑器。打开数据库失败时显示错误，不删除或重建现有用户数据库。关闭 App、重新启动、断网都可以使用已保存数据。

首次启动创建空的本地资料库。**Web 后端现有数据不会自动迁移，也不会被修改。** `Services/APIService.swift` 作为历史 API 实现保留，当前 App 读写不调用它。导入 Web 数据、导入导出和跨设备同步尚未接入。

## 测试

详见 [Xcode 本地构建与测试指南](XCODE_LOCAL_BUILD_AND_TEST.md)。

单元测试使用独立临时 SQLite 文件，覆盖离线保存、重开后数据完整性、编辑元数据、收藏、删除及 ID、重复或使用中的标签、写入失败保护、变量提取与替换，以及日期编码。

UI 测试覆盖主标签页、标签创建与重启保留、笔记直接复制与编辑、收藏快捷访问和两种变量语法的实时预览。UI 测试在模拟器中创建带随机名称的测试记录；不要用日常使用的真实手机运行这些 UI 测试。

## 项目结构

```text
Models/       Prompt、Tag、PromptKind、TemplateText
Services/     DataStore、SQLiteStore、历史 APIService
Views/        列表、编辑、详情、标签、变量、快捷使用和设置
Utils/        主题颜色
PromptKitTests/       XCTest 单元测试
PromptKitUITests/     XCTest 界面测试
```

设置中的 iCloud、数据导出、Pro 等历史入口仍是待实现功能，不代表已经具备同步、备份或购买能力。
