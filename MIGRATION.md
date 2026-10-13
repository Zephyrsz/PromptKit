# PromptKit 独立项目迁移记录

日期：2026-10-13。

## 文件与仓库

- 来源：`/Users/rgwei/pj/pj_my/prompt_shortcut_tools/PromptKit`。
- 目标：`/Users/rgwei/pj/pj_my/PromptKit`。
- 迁移前逐一核对了 28 个文件；15 个业务 Swift 文件在迁移后内容完全一致。
- 源目录已移除。原仓库中两个已跟踪文档会显示为删除，迁移没有替原仓库创建提交。
- 新仓库提交全部 App 源码、工程、共享 Scheme、测试和相关文档；不提交 `.build/`、个人 Xcode 配置或凭据。
- 后端、Prisma 数据库和原仓库其他工作文件仍在原仓库中。

## Xcode 工程

`PromptKit.xcodeproj` 包含 PromptKit、PromptKitTests 和 PromptKitUITests 三个 target，共享 Scheme 为 PromptKit。App 最低支持 iOS 16，Swift 5 语言模式，Bundle Identifier 为 `com.rgwei.PromptKit`。真机运行时需要选择自己的开发团队，并按需要调整标识。

测试框架为 XCTest。工程没有接入外部 Swift Package，也不依赖工程生成器。

## 本次实际验证

环境：Xcode 27.0（27A266a），iPhone 18 Pro / iOS 27.0 模拟器。

- 完整 Debug App 构建：`BUILD SUCCEEDED`。
- `PromptKitTests.testPromptDecodesBackendPayload`：通过。
- `PromptKitUITests.testMainTabsCanBeOpened`：通过，实际启动 App 并切换三个标签页。
- 共执行 2 项测试，0 失败：`TEST SUCCEEDED`。
- 结果保存在本地 `.build/MigrationTests.xcresult`，不纳入提交。

现有源码有未使用 `deleteTag` 返回值的警告。Xcode 27 测试库也会给出测试 bundle 最低系统版本与 SDK 库版本的链接警告；本次在 iOS 27 模拟器上测试通过，未验证旧系统测试运行时。

## 验证边界

尚未验证真机签名、实际后端增删改查或旧系统运行。基础测试不代表完整业务覆盖。API 默认仍为 `http://127.0.0.1:3001/api`；iCloud 同步、数据导出和离线数据库仍未实现。

当前入口文档为 [README](README.md) 和 [Xcode 本地构建与测试指南](XCODE_LOCAL_BUILD_AND_TEST.md)。早期交付和安装文档保留为历史参考。
