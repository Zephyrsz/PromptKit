# PromptMaster Web 数据导入验证

日期：2026-10-22。范围：iOS App、本地 Web SQLite 快照与标签筛选 UI。

## 数据与导入

- 来源：`../prompt_shortcut_tools/prisma/prompts.db`，全程只读。
- 内置快照：`Resources/WebPrompts.sqlite`；Prompt 和 Tag 两张业务表逐字段与来源一致。
- 内容：19 条，12 条笔记、7 个模板；13 个源标签全部保留，包括未使用的标签。
- 补齐引用：IT、健康、工具、生活、知识、编程、趣味，新安装共 20 个标签。
- 源文件 SHA-256：`d59317cc48019560b58ad794fc5742fd9d78c2db4dbcc64be112b2bcb96038f1`。
- 内置快照 SHA-256：`934637c318de423b3723d78a33716db014e03816488b2d6f5544a22c5557f59a`。

自动测试覆盖字段与时间保留、模板变量、标签颜色映射、v1 数据保留、主键冲突、重复导入、本地编辑与删除、注入目标写入失败后的完整回滚和重试。新安装模拟器已核对 19 条内容及 20 个标签。已有安装可能包含额外的本地记录。

## 构建与测试

环境：Xcode 27.0，iOS 27 模拟器，Swift 5 语言模式，最低部署版本 iOS 16。

原工程路径的 `xcodebuild` 在编译前卡于 `NSFileCoordinator` 递归项目读取，采样见 `.build/design-review/xcode-initialization.sample.txt`。未删除工程设置或用户数据；构建改用 `/tmp/PromptMaster-Validation-20261022` 中逐文件一致的源码副本，DerivedData 保存在本仓库 `.build/validation`。App 源码、资源、工程配置和测试文件已与副本核对一致。

| 验证 | 结果 | 本地证据 |
|---|---|---|
| 375pt iPhone SE（第 3 代），16 项单元测试及 8 项 UI 测试 | 全部通过，0 失败 | `.build/design-review/web-library-final-small.log` |
| 最后调整导航字号后，导航及最大辅助字号 2 项 UI 测试 | 全部通过，0 失败 | `.build/design-review/web-library-chrome-verified.log` |
| 新安装 390pt iPhone 17e | 19 条内容、20 个标签；界面截图检查 | `.build/design-review/web-library-home-final.png` |
| 最大辅助字号最终截图 | 标签换行；底部四项完整对齐 | `.build/design-review/web-library-chrome-images/85EDF8CA-4BBD-41B4-BFA4-BCDFE4516EF3.png` |

测试报告：

- 全套：`.build/validation/Logs/Test/Test-PromptKit-2026.10.22_23-11-23-+0800.xcresult`。
- 最终相关回归：`.build/validation/Logs/Test/Test-PromptKit-2026.10.22_23-18-00-+0800.xcresult`。

UI 测试覆盖标签 OR 多选与清除、搜索/类型/收藏组合、笔记与模板分区、导入的 SQL 模板填写预览、创建/编辑/收藏/复制、重启持久化和大字号标签交互。字体采用 iOS 原生系统字阶，品牌字标保留居中 Georgia 斜体，底部顺序为 `home / 个人收藏 / 设置 / ＋`。

## 边界

这是用于本地逻辑验证的内置快照导入，不是实时同步。更新快照可增加新的来源行，已有来源行不会覆盖 App 内的修改。真实 iPhone、iOS 16 运行时和完整横屏布局尚未验证；横屏模拟器截图存在裁切异常，因此不据此声明横屏视觉验收通过。UI 测试会留下测试记录，应使用专用模拟器。
