# PromptKit 本地构建与测试

更新日期：2026-10-22。Xcode 27.0（27A266a），Swift 5 语言模式，iPhone App 最低 iOS 16。

## 在 Xcode 中运行

1. 打开仓库根目录 `PromptKit.xcodeproj`。
2. 选择共享 Scheme `PromptKit` 和具体的 iPhone 模拟器。
3. `⌘B` 构建，`⌘R` 运行，`⌘U` 执行测试。
4. 在 Report Navigator（`⌘9`）检查构建与测试结果。

本地保存、加载、搜索、收藏和标签管理均使用 SQLite，**无需启动后端，也无需修改 API 地址**。首次运行时本地资料库为空；点击首页右下角加号创建笔记或模板。

真机运行需在 Signing & Capabilities 中选择自己的 Team，配置 Bundle Identifier，并完成手机配对、信任和 Developer Mode 设置。模拟器验证不能替代真机签名及系统兼容性验证。

## 命令行测试

如果 `xcode-select -p` 指向 CommandLineTools，在当前终端设置完整 Xcode 的工具路径；不需要修改系统全局设置：

```bash
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
xcodebuild -version
xcrun simctl list devices available
```

在项目目录执行（替换为本机实际的模拟器名称）：

```bash
xcodebuild \
  -project PromptKit.xcodeproj \
  -scheme PromptKit \
  -destination 'platform=iOS Simulator,name=iPhone 18 Pro Max,OS=27.0' \
  -derivedDataPath .build/ios \
  -parallel-testing-enabled NO \
  test
```

`test` 包含构建。需要保存报告时使用 `-resultBundlePath` 指定一个尚不存在的 `.xcresult` 目录；在 Xcode 中打开报告可检查断言、日志和截图。单独执行单元测试可增加 `-only-testing:PromptKitTests`。

检查退出码和实际执行数量，不能将仅编译成功视为业务测试通过。

## 测试覆盖和数据隔离

- 单元测试：使用 UUID 命名的临时目录和真实 SQLite 文件，测试结束删除目录；不调用后端，不读写日常使用的 App 数据库。
- UI 测试：在模拟器中新建随机名称的标签、笔记和模板，覆盖重启持久化、编辑、收藏、直接复制与填空预览。会保留测试记录，建议使用专门的测试模拟器。
- 尚未验证：真实 iPhone、iOS 16 运行时、Web 数据迁移和跨设备同步。

## 检查 SQLite 文件

应用把数据库保存在自身沙盒的：

```text
Library/Application Support/PromptKit/PromptKit.sqlite
```

查找已安装模拟器 App 的沙盒：

```bash
xcrun simctl get_app_container booted com.rgwei.PromptKit data
```

使用返回路径下的 `Library/Application Support/PromptKit/PromptKit.sqlite`，可通过 `sqlite3` 只读检查 `prompts`、`tags` 和 `PRAGMA user_version`。数据库启用了 WAL，运行中备份应使用 SQLite 的备份机制，不能只复制主文件。

数据库打开失败时应保留原文件并调查错误，不要通过删除用户数据库来解决构建或运行问题。

## 历史文档

[本地数据库审查](LOCAL_DATABASE_REVIEW.md) 记录的是改造前的 HTTP 原型状态及迁移建议；当前实现以本指南和 `Services/SQLiteStore.swift` 为准。`Services/APIService.swift` 仍保留，但当前 DataStore 已不使用 HTTP 后端。
