# PromptKit iPhone App：Xcode 本地构建、运行与自动化测试指南

更新日期：2026-10-13。本文依据本机 Xcode GUI、工具链和当前工作区的 PromptKit 源码编写。

| 项目 | 检查结果 |
| --- | --- |
| Xcode 版本 | 27.0，构建号 27A266a |
| iOS 应用 | PromptKit，SwiftUI |
| 本地仓库 | `/Users/rgwei/pj/pj_my/PromptKit` |
| iOS 源码目录 | 仓库根目录及 Models / Services / Views / Utils |
| 已安装模拟器示例 | iPhone 18 Pro，iOS 27.0 |
| 当前工程状态 | `PromptKit.xcodeproj`，共享 Scheme：PromptKit |
| 当前测试状态 | XCTest 单元测试和 UI 测试各一个 target |
| 建议首次接入配置 | 最低 iOS 16.0，Swift 5 语言模式 |

本项目在 2026-10-13 从原仓库的 `PromptKit/` 迁移为独立本地仓库，并接入 Xcode 工程。后端未迁移，仍在原仓库中。

## 1. 先理解当前项目的运行条件

当前项目已有 App target、共享 Scheme 和基础测试配置，可以直接打开 `PromptKit.xcodeproj`。无需重新创建工程或复制源码。

当前数据路径是：

```text
SwiftUI 页面 → DataStore → APIService → HTTP 后端
```

`Services/APIService.swift` 的地址写死为：

```text
http://127.0.0.1:3001/api
```

因此，编译 App 不要求后端运行，但运行后的模板加载、保存、标签管理等功能需要后端。当前还没有实现 iPhone 本地数据库、离线读写或完整的 iCloud 同步；设置界面出现相关选项不等于这些功能已经实现。

旧文档声称最低支持 iOS 15，但 `SettingsView.swift` 和 `TagPickerView.swift` 使用了 iOS 16 才支持的 `.scrollContentBackground(.hidden)`。首次接入建议将最低版本设为 iOS 16；如果要保留 iOS 15 支持，需要先增加版本兼容处理。

## 2. 在 Xcode 27 GUI 中打开工程

1. 启动 Xcode，选择 `File → Open…`。
2. 选择 `/Users/rgwei/pj/pj_my/PromptKit/PromptKit.xcodeproj`，点击 Open。
3. 在顶部选择 `PromptKit` Scheme 和具体模拟器，例如 iPhone 18 Pro / iOS 27.0。
4. 按 `⌘B` 构建，按 `⌘R` 安装并运行。

工程已经包含所有 15 个业务 Swift 文件。不要再导入一套同名源码，以免出现重复类型或多个 `@main` 入口。

若以后需要新建其他工程，本机 Xcode 27 的完整模板向导是 `File → New → Project… → Choose Template… → iOS → App → Next`。本工程无需执行此操作。

## 3. 检查工程配置

选择左侧工程，再选择 `TARGETS → PromptKit`：

- `General → Minimum Deployments → iOS`：16.0。
- `Build Settings → Swift Language Version`：Swift 5。
- `Signing & Capabilities`：自动签名，真机运行时选择自己的 Team。
- 测试目标：`PromptKitTests` 和 `PromptKitUITests`，均使用 XCTest。

Swift 5 是语言模式，实际编译器仍由 Xcode 27 提供。本工程只针对 iPhone。

## 4. 启动本地后端

在终端执行：

```bash
cd /Users/rgwei/pj/pj_my/prompt_shortcut_tools
npm install
npx prisma generate
npm run dev
```

依赖已安装且 Prisma Client 已生成时，可以只执行 `npm run dev`。保持服务运行，再启动模拟器中的 App。

当前 `package.json` 的开发命令监听 `127.0.0.1:3001`，与 App 的地址一致。可在浏览器打开：

```text
http://127.0.0.1:3001/api/prompts
```

也可以只读检查：

```bash
curl --fail http://127.0.0.1:3001/api/prompts
```

返回 JSON 才说明后端接口可用。首次运行不需要重新初始化或清空现有 `prisma/prompts.db`。

工程 Info.plist 已启用 `NSAllowsLocalNetworking` 并声明本地网络用途。如果 App 控制台仍报告 ATS 阻止本地 HTTP 请求，可以在 `TARGETS → PromptKit → Info` 中配置本地开发所需的 App Transport Security 例外。`NSAllowsLocalNetworking` 用于本地网络访问；如果具体地址仍受阻，应结合日志和地址类型配置开发用例外。部署到远程服务时优先使用 HTTPS，避免把允许任意 HTTP 加载作为默认发布配置。

## 5. 在 GUI 中构建和运行

### 5.1 选择 Scheme 和模拟器

Xcode 顶部工具栏有两个选择器：

- **Active Scheme**：选择 `PromptKit`。
- **Active Run Destination**：选择具体的 iPhone 模拟器。

本机已安装 **iPhone 18 Pro / iOS 27.0**，可以直接使用。不要选择只能构建的通用设备目的地来启动模拟器。

最低支持版本与模拟器系统版本是两个概念：App 最低支持 iOS 16，仍可以在 iOS 27 模拟器中运行。如果需要验证旧系统兼容性，需要另外安装相应的运行时。

### 5.2 先 Build，再 Run

| 操作 | 菜单或快捷键 | 作用 |
| --- | --- | --- |
| 构建 | `Product → Build` / `⌘B` | 编译并生成 App |
| 运行 | 左上角 ▶ / `⌘R` | 构建、安装到模拟器并启动 |
| 停止 | 左上角 ■ / `⌘.` | 停止当前运行 |
| 测试 | `Product → Test` / `⌘U` | 执行配置好的自动化测试 |
| 查看错误 | `⌘5` | 打开 Issues Navigator |
| 查看构建和测试报告 | `⌘9` | 打开 Report Navigator |
| 显示调试区 | `⇧⌘Y` | 查看运行日志和断点状态 |
| 清理构建目录 | `Product → Clean Build Folder` / `⇧⌘K` | 出现构建缓存问题时重新生成产物 |

首次建议先按 **⌘B**。解决构建错误后再按 **⌘R**，模拟器会打开并启动 App。

Build 成功表示代码可以生成构建产物，不代表界面交互、网络请求或业务功能已经通过测试。Run 后应确认“模板”“快捷贴贴”“设置”三个标签页可打开，并检查后端数据是否正确加载。

### 5.3 常见问题

| 现象 | 优先检查 |
| --- | --- |
| `Cannot find DataStore in scope` | `DataStore.swift` 是否加入 App target，关联源码是否完整 |
| 两个应用入口或类型重复 | 新工程默认文件与仓库文件是否同时参与编译 |
| `scrollContentBackground` 可用版本错误 | 最低系统版本是否设为 iOS 16，或是否已有兼容处理 |
| 界面启动但列表为空 | 后端是否运行、API 是否返回数据、控制台是否有网络错误 |
| 签名报错 | 运行目的地是否误选为真机，Team 和 Bundle Identifier 是否正确 |
| 模拟器不可用 | 对应 iOS 运行时是否安装，目的地是否为具体模拟器 |

## 6. 在 GUI 中建立并执行自动化测试

### 6.1 当前测试目标

- `PromptKitTests`：验证后端 Prompt JSON 中的字段、可选值和带毫秒的时间字符串解码。
- `PromptKitUITests`：启动 App，并验证“模板”“快捷贴贴”“设置”三个标签页可切换。

两组测试已加入共享 Scheme。当前是基础验证，不代表所有业务功能已覆盖。

### 6.2 执行测试

按 `⌘U`，或选择 `Product → Test`。使用 **Test Navigator（⌘6）** 单独运行某条测试，在 **Report Navigator（⌘9）** 查看完整报告。

`Product → Scheme → Edit Scheme… → Test` 可查看两个测试目标。单元测试不依赖后端；当前 UI 测试只断言标签页切换，不断言接口数据或修改后端数据库。

### 6.3 本项目适合优先覆盖的内容

| 测试类型 | 建议验证内容 |
| --- | --- |
| 单元测试 | Prompt / Tag 解码、日期解析、变量提取与替换 |
| 网络测试 | 成功响应、HTTP 失败、连接失败、失败时不误更新状态 |
| 界面测试 | 启动、三个标签页切换、创建模板、搜索、收藏和详情更新 |

界面测试通常通过 `XCUIApplication` 启动 App，用控件标识查找输入框和按钮，并断言交互结果。后续可以为关键控件添加 `accessibilityIdentifier`，提高定位稳定性。

当前 APIService 和 DataStore 使用单例，API 地址固定，尚未提供可注入的测试边界。稳定的自动化测试应逐步引入可替换的数据服务、固定测试数据和模拟网络响应。纯单元测试尽量不依赖真实后端。

涉及增删改查的 UI 或集成测试，应使用独立测试数据库和固定数据，避免改动日常使用的 `prisma/prompts.db`。当前还没有自动完成这些隔离措施的配置。

## 7. 为命令行自动化准备工程

### 7.1 共享 Scheme

进入：

```text
Product → Scheme → Manage Schemes…
```

将 `PromptKit` 标记为 **Shared**。工程、共享 Scheme、测试计划和测试源码需要纳入版本管理，其他机器才能复用同一套配置。

本仓库 `.gitignore` 仅忽略 Xcode 个人设置、构建产物和本地凭据，不忽略工程文件或共享 Scheme。`.build/` 已被忽略。

### 7.2 使用完整 Xcode 工具链

本机检查时，`xcode-select -p` 返回：

```text
/Library/Developer/CommandLineTools
```

因此直接运行 `xcodebuild` 会报“需要完整 Xcode”的错误。在当前终端或自动化脚本中设置：

```bash
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
xcodebuild -version
```

这只影响当前进程及其子进程，无需改变系统全局开发工具路径。本机使用该方式返回：

```text
Xcode 27.0
Build version 27A266a
```

也可以在 Xcode Settings 的 Locations 页面检查 Command Line Tools 选择。

### 7.3 核对工程、Scheme 和目的地

以下命令可在当前工程直接执行：

```bash
cd /Users/rgwei/pj/pj_my/PromptKit
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer

xcodebuild -list -project PromptKit.xcodeproj
xcodebuild -showdestinations \
  -project PromptKit.xcodeproj \
  -scheme PromptKit
xcrun simctl list devices available
```

确认实际 Scheme 名称与模拟器名称、系统版本。不同机器安装的设备可能不同，不要直接照抄目的地名称。

## 8. 自动构建和自动测试

### 8.1 自动构建

```bash
cd /Users/rgwei/pj/pj_my/PromptKit
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer

xcodebuild \
  -project PromptKit.xcodeproj \
  -scheme PromptKit \
  -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 18 Pro,OS=27.0' \
  -derivedDataPath .build/ios \
  build
```

这对应 GUI 中的 Build：编译并生成 App，不会仅凭 `build` 就安装或启动应用。构建完成时检查进程退出码和 `BUILD SUCCEEDED`，失败时阅读具体错误。

### 8.2 自动执行测试

```bash
cd /Users/rgwei/pj/pj_my/PromptKit
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer

xcodebuild \
  -project PromptKit.xcodeproj \
  -scheme PromptKit \
  -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 18 Pro,OS=27.0' \
  -derivedDataPath .build/ios \
  -resultBundlePath ".build/Tests-$(date +%Y%m%d-%H%M%S).xcresult" \
  test
```

`test` 会构建测试所需内容、启动模拟器并执行已配置的测试。带时间戳的结果路径避免复用已经存在的 `.xcresult` 目录。

如果 UI 测试仍依赖当前 API，则执行前需要在另一个终端保持后端运行。使用固定测试数据和模拟响应之后，纯界面检查可以减少对后端状态的依赖。

测试完成后，在 Finder 中双击生成的 `.xcresult`，用 Xcode 查看断言失败、日志和测试附件。自动化流程应同时检查退出码、实际执行的测试数量和测试结果，不能把没有执行测试当作通过。

### 8.3 保存为可重复执行的本地脚本

以下可作为可重复执行的本地脚本参考：

```bash
#!/usr/bin/env bash
set -euo pipefail

cd /Users/rgwei/pj/pj_my/PromptKit
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer

project_path='PromptKit.xcodeproj'
simulator_destination='platform=iOS Simulator,name=iPhone 18 Pro,OS=27.0'
result_path=".build/Tests-$(date +%Y%m%d-%H%M%S).xcresult"

xcodebuild \
  -project "$project_path" \
  -scheme PromptKit \
  -configuration Debug \
  -destination "$simulator_destination" \
  -derivedDataPath .build/ios \
  build

xcodebuild \
  -project "$project_path" \
  -scheme PromptKit \
  -configuration Debug \
  -destination "$simulator_destination" \
  -derivedDataPath .build/ios \
  -resultBundlePath "$result_path" \
  test
```

`set -euo pipefail` 使构建或测试失败时停止，并保留失败状态。若把日志通过管道传给其他工具，`pipefail` 还能避免后续日志命令掩盖构建失败。

普通情况下，`test` 本身已包含构建步骤，可以只执行 `test`；分别执行 `build` 和 `test` 便于区分 App 编译错误与测试失败。后续本地检查或 CI 可以复用同一脚本，现阶段直接使用 `xcodebuild` 即可。

## 9. 在真实 iPhone 上运行

### 9.1 GUI 配置

1. 在 `Xcode → Settings… → Accounts` 中添加开发用 Apple 账号。
2. 在 `TARGETS → PromptKit → Signing & Capabilities` 中启用自动签名，选择个人开发团队，并使用唯一的 Bundle Identifier。
3. 连接 iPhone，完成设备配对和信任。
4. 在手机中按系统提示开启 Developer Mode，通常位于“设置 → 隐私与安全性 → 开发者模式”。
5. 在顶部运行目的地选择该 iPhone，按 `⌘R`。

个人真机调试可以使用免费 Personal Team；App Store 和 TestFlight 分发需要相应开发者计划与分发配置。免费个人签名有有效期等限制，失效后需要重新签名安装。

### 9.2 真机访问本地后端

手机里的 `127.0.0.1` 指向手机自身，不能访问 Mac 的本地服务。真机调试需要：

- 将 APIService 地址改为 Mac 的局域网地址，例如 `http://192.168.1.100:3001/api`，使用实际地址替换示例。
- 将后端监听地址改为局域网可达的接口，例如开发时用 `npx next dev --hostname 0.0.0.0 --port 3001` 启动。
- 确认手机和 Mac 网络互通，并按系统提示允许本地网络访问；在需要时配置 `NSLocalNetworkUsageDescription`。

HTTP/ATS 配置、局域网可达性和本地网络授权是不同问题，应分别根据日志检查。后续应将模拟器、真机和远程服务地址做成可配置项。

## 10. 验证结果与边界

2026-10-13 的迁移已按文件内容逐一核对。现有 15 个业务 Swift 文件完整迁移；独立工程包含 App target、两个 XCTest target 和共享 Scheme。

构建与测试的实际验证结果见 [迁移记录](MIGRATION.md)。模拟器测试不能替代真机签名、局域网联通性或实际后端业务测试。当前 iCloud 同步、导出、离线数据库仍未实现。

原 2026-10-11 指南记录的“缺少工程、仅类型检查通过”属于迁移前状态，已被本次正式工程接入替代。

## 11. 相关项目文档

- `README.md`：iOS 源码和功能说明，部分描述需要按当前实现复核。
- `QUICKSTART.md`、`INSTALL.md`：早期安装说明；当前 Xcode 界面、测试选项和最低系统版本以本文为准。
- [本地数据库与 D1 数据迁移审查](LOCAL_DATABASE_REVIEW.md)：当前存储状态、数据兼容问题及后续持久化建议。

未来增加工程、测试脚本、可配置 API 地址或本地数据库时，应同步更新本文的路径、运行条件和验证结果。
