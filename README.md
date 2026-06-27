# OpenCode Remote

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Dart SDK](https://img.shields.io/badge/Dart-%5E3.11.4-0175C2?logo=dart)](https://dart.dev)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)

**OpenCode Remote** 是一款基于 Flutter 构建的移动端远程控制应用，专为 [opencode](https://opencode.ai) AI 编程助手设计。通过手机即可远程连接 opencode 服务器，实时查看 AI 编码会话、浏览项目文件、发送消息并监控 AI 执行过程。

> 🚀 **一句话定位**：将 opencode AI 编程助手装进口袋，随时随地掌控你的编码会话。

---

## 功能概览

### 双运行模式

应用提供两种使用方式，通过**首次启动引导**（iOS 风格毛玻璃界面）让用户自由选择：

| 模式 | 说明 | 适用场景 |
|------|------|----------|
| **WebView 模式** | 通过内嵌 WebView 加载 opencode 的 Web 界面，功能完整，一致性最高 | 偏好 opencode 原生 Web 界面的用户 |
| **原生 Flutter UI 模式** | 通过 opencode REST API 直接交互的原生界面 | 需要移动端原生体验、离线操作或更流畅交互的用户 |

### 原生模式下包含的功能

#### 📊 Dashboard（仪表盘）
- 服务器健康状态实时显示（连接状态、版本号）
- 最近 5 条会话列表（支持按当前项目过滤）
- 快捷操作入口
- 当前项目上下文卡片

#### 💬 会话管理 & 聊天
- **会话列表**：浏览所有会话，支持按标题搜索
- **创建会话**：新建空会话，可选标题
- **消息聊天**：与 AI 实时对话，支持文本、附件、Shell 命令、Slash 命令
- **流式响应**：通过 SSE（Server-Sent Events）实时接收 AI 响应，支持流式 Delta 更新
- **消息操作**：复制内容、查看差异、回滚消息
- **会话操作**：重命名、分享、中止、分叉（Fork）、删除、查看子会话、待办列表、总结
- **Agent/Model 选择**：在聊天栏上方切换 AI Agent 和模型（支持搜索过滤）
- **上下文用量**：实时显示 Token 消耗和上下文窗口占比

#### 📁 文件浏览
- **树形文件浏览器**：分层展开目录结构
- **文件内容查看**：以全屏弹窗展示文件源码（等宽字体）
- **文件搜索**：按文件名、文本内容、符号名搜索
- **图片预览**：支持常见图片格式的预览提示
- **面包屑导航**：当前路径层级显示

#### 📂 项目管理
- **当前项目**：显示当前活跃项目的名称和路径
- **项目列表**：浏览 opencode 服务器上的所有项目，支持搜索过滤
- **切换项目**：一键切换当前工作上下文
- **添加/关闭项目**：从服务器添加新项目或关闭现有项目
- **VCS 信息**：查看当前 Git 分支、提交信息
- **Workspace（分支）列表**：切换 Git 工作分支

#### 🖥️ 远程终端
- 内置终端模拟器，通过 opencode 的 Shell API 远程执行命令
- 命令历史记录
- 控制台风格 UI（暗色背景、`$` 提示符）
- 支持清除输出、加载状态指示

#### ⚙️ 诊断与配置
- **Config 查看**：浏览服务器配置项
- **Provider 信息**：AI 模型提供商列表及默认模型配置
- **工具状态**：LSP 服务器、格式化器、MCP 服务器的运行状态（健康指示灯）
- **认证设置**：查看支持的认证方式，设置 Provider API Key

#### 💡 AI 交互增强
- **思考过程展示**：可折叠的 Reasoning Block，展示 AI 推理过程
- **工具调用可视化**：以卡片形式展示 AI 执行的各种工具（Write、Read、Bash、Edit、Grep、Glob、WebFetch 等），包含状态、输入、输出
- **差异对比**：以行级 Diff View 展示代码变更（+/- 高亮）
- **代码块高亮**：Markdown 代码块语法高亮（支持 190+ 语言），一键复制
- **权限请求弹窗**：AI 请求操作权限时弹出交互对话框（允许一次/始终允许/拒绝）
- **问题弹窗**：AI 向用户提问时展示

#### 🌐 WebView 模式
- 支持 Basic Auth 认证
- 服务器切换
- 加载进度指示
- 刷新控制
- 可随时通过设置切换到原生模式

### 通用功能

- **多服务器管理**：添加、编辑、删除多个 opencode 服务器连接
- **主题切换**：浅色/深色/跟随系统
- **运行模式切换**：WebView ↔ 原生（无需重新安装）
- **事件驱动更新**：通过 SSE 实时推送消息和会话变更
- **i18n 就绪**：所有 UI 字符串集中在 `lib/strings.dart`，便于国际化

---

## 技术栈

| 层级 | 技术 |
|------|------|
| **框架** | Flutter (Dart SDK ^3.11.4) |
| **API 通信** | HTTP REST (opencode Server API) |
| **实时推送** | Server-Sent Events (SSE) |
| **本地存储** | SharedPreferences |
| **WebView** | `webview_flutter` + `webview_flutter_web` |
| **文件选择** | `file_picker` + `image_picker` |
| **富文本** | `flutter_markdown` + `flutter_highlight` |
| **HTTP 客户端** | `http` package |
| **状态管理** | `setState` + `ValueNotifier` |
| **UI 风格** | Material 3 + 自定义设计系统 |

---

## 项目结构

```
opencode_remote/
├── lib/
│   ├── main.dart                        # 应用入口、主题配置、路由分发
│   ├── strings.dart                     # 集中式 UI 字符串常量（i18n 就绪）
│   ├── theme.dart                       # 设计系统：颜色、间距、圆角常量
│   ├── models.dart                      # 模型 barrel export
│   ├── models/                          # 数据模型（与 opencode API 对应）
│   │   ├── agent.dart                   #   AI Agent 模型
│   │   ├── command.dart                 #   Slash 命令模型
│   │   ├── config.dart                  #   服务器配置模型
│   │   ├── diff.dart                    #   文件差异模型
│   │   ├── enums.dart                   #   应用枚举（AppMode）
│   │   ├── file.dart                    #   文件/目录节点模型
│   │   ├── health.dart                  #   健康状态/项目/VCS 模型
│   │   ├── lsp.dart                     #   LSP/Formatter/MCP 状态模型
│   │   ├── message.dart                 #   消息模型
│   │   ├── part.dart                    #   消息 Part（文本/工具/文件/推理等）
│   │   ├── provider.dart                #   AI 提供商与模型模型
│   │   ├── search.dart                  #   搜索匹配/符号模型
│   │   ├── server_entry.dart            #   服务器连接条目模型
│   │   ├── session.dart                 #   会话、摘要、Token、共享等模型
│   │   ├── todo.dart                    #   待办事项模型
│   │   └── tool.dart                    #   工具条目模型
│   ├── screens/
│   │   ├── onboarding_screen.dart       #   首次启动引导（毛玻璃效果）
│   │   ├── launcher_screen.dart         #   服务器列表（启动首页）
│   │   ├── webview_screen.dart          #   WebView 模式
│   │   ├── settings_sheet.dart          #   设置面板（模式/主题/关于）
│   │   └── native/
│   │       ├── dashboard_screen.dart    #   Dashboard 仪表盘
│   │       ├── session_list_screen.dart #   会话列表
│   │       ├── chat_screen.dart         #   消息聊天（核心页面）
│   │       ├── message_bubble.dart      #   消息气泡组件
│   │       ├── file_browser_screen.dart #   文件浏览器
│   │       ├── project_screen.dart      #   项目信息
│   │       ├── config_screen.dart       #   诊断与配置
│   │       ├── terminal_screen.dart     #   远程终端
│   │       ├── model_picker_sheet.dart  #   模型选择面板
│   │       └── tool_part_widget.dart    #   工具执行卡片
│   ├── widgets/                         # 可复用 UI 组件
│   │   ├── main_scaffold.dart           #   原生模式主框架（NavigationRail）
│   │   ├── agent_bar.dart               #   聊天栏上方的 Agent/Model 选择条
│   │   ├── chat_input_bar.dart          #   聊天输入栏
│   │   ├── command_suggestions.dart     #   Slash 命令建议
│   │   ├── reasoning_block.dart         #   可折叠推理过程展示
│   │   ├── code_block_builder.dart      #   Markdown 代码块语法高亮
│   │   ├── diff_view.dart               #   Diff 差异对比组件
│   │   ├── attachment_preview.dart      #   附件预览
│   │   ├── revert_banner.dart           #   回滚状态横幅
│   │   ├── todo_banner.dart             #   待办事项横幅
│   │   ├── project_avatar.dart          #   项目头像
│   │   ├── workspace_list.dart          #   Git 分支列表
│   │   ├── add_project_dialog.dart      #   添加项目对话框
│   │   ├── server_edit_dialog.dart      #   编辑服务器对话框
│   │   ├── app_card.dart                #   通用卡片容器
│   │   ├── app_dialog.dart              #   通用对话框
│   │   ├── app_bottom_sheet.dart        #   通用底部面板
│   │   ├── app_snackbar.dart            #   通用提示条
│   │   ├── app_states.dart              #   加载/空/错误状态组件
│   │   ├── app_section_header.dart      #   段落标题
│   │   ├── app_selectable_tile.dart     #   可选 Tile
│   │   ├── app_status_dot.dart          #   状态指示灯
│   │   ├── app_full_screen_dialog.dart  #   全屏弹窗
│   │   ├── app_primary_button.dart      #   主按钮
│   │   ├── app_cancel_button.dart       #   取消按钮
│   │   ├── app_input_decoration.dart    #   输入框样式
│   │   ├── file_parts_row.dart          #   文件 Part 行
│   │   └── ...
│   └── services/
│       ├── opencode_api.dart            #   opencode REST API 封装（完整）
│       ├── storage_service.dart         #   SharedPreferences 存储服务
│       └── event_service.dart           #   SSE 事件流服务
├── test/
│   └── widget_test.dart                 #   基础 Widget 测试
├── android/                             # Android 平台配置
├── ios/                                 # iOS 平台配置
├── macos/                               # macOS 平台配置
├── web/                                 # Web 平台配置
├── test/                                # 测试目录
├── pubspec.yaml                         # 依赖清单
├── analysis_options.yaml                # Dart linter 配置
└── README.md                            # 本文件
```

---

## API 概览

应用通过 opencode HTTP Server 的 REST API 进行通信。主要 API 端点包括：

| 端点 | 方法 | 用途 |
|------|------|------|
| `/global/health` | GET | 获取服务器健康状态 |
| `/project` | GET/POST | 获取/添加项目列表 |
| `/project/current` | GET | 获取当前项目 |
| `/project/:id` | DELETE | 移除项目 |
| `/vcs` | GET | 获取 Git/VCS 信息 |
| `/path` | GET | 获取路径信息 |
| `/session` | GET/POST | 获取/创建会话 |
| `/session/:id` | GET/PATCH/DELETE | 会话详情/更新/删除 |
| `/session/:id/abort` | POST | 中止会话 |
| `/session/:id/message` | GET/POST | 获取消息/发送消息 |
| `/session/:id/prompt_async` | POST | 异步发送消息 |
| `/session/:id/command` | POST | 执行 Slash 命令 |
| `/session/:id/shell` | POST | 执行 Shell 命令 |
| `/session/:id/children` | GET | 获取子会话 |
| `/session/:id/fork` | POST | 分叉会话 |
| `/session/:id/share` | POST/DELETE | 分享/取消分享 |
| `/session/:id/diff` | GET | 获取差异 |
| `/session/:id/todo` | GET | 获取待办事项 |
| `/session/:id/revert` | POST | 回滚消息 |
| `/session/:id/summarize` | POST | 总结会话 |
| `/file` | GET | 列出目录文件 |
| `/file/read` | GET | 读取文件内容 |
| `/file/search` | GET | 搜索文件内容 |
| `/file/find` | GET | 按文件名查找 |
| `/file/symbol` | GET | 查找符号 |
| `/agent` | GET | 获取 Agent 列表 |
| `/provider` | GET | 获取 Provider/模型列表 |
| `/command` | GET | 获取 Slash 命令列表 |
| `/config` | GET | 获取服务器配置 |
| `/config/providers` | GET | 获取提供商配置 |
| `/config/:key` | PATCH | 更新配置项 |
| `/lsp` | GET | LSP 状态 |
| `/formatter` | GET | 格式化器状态 |
| `/mcp` | GET | MCP 服务器状态 |
| `/auth` | GET | 认证方式列表 |
| `/auth/:provider` | PUT | 设置 Provider 认证 |
| `/event` | GET (SSE) | 实时事件流 |
| `/instance/dispose` | POST | 销毁实例 |
| `/log` | POST | 写入日志 |

---

## 快速开始

### 前置条件

- Flutter SDK ^3.11.4
- 一台 Android / iOS 设备（或模拟器）
- opencode 服务端（运行中且启用了 HTTP 服务器）
- 手机与服务器位于同一局域网（或可访问的网络）

### 1. 启动 opencode 服务端

在电脑上选择以下任一方式启动：

```bash
# Web 模式（自动打开浏览器，默认无需密码）
opencode web

# Server 模式（允许局域网访问，推荐手机连接）
opencode serve --hostname 0.0.0.0
```

> 如需认证，设置环境变量 `OPENCODE_SERVER_PASSWORD`。

### 2. 运行应用

```bash
# 获取依赖
flutter pub get

# 连接设备后运行
flutter run

# 代码分析
flutter analyze
```

### 3. 添加服务器连接

打开 App，点击右下角 **+** 按钮添加服务器：

- **名称**：任意自定义名称（如"家里PC"）
- **地址**：电脑的局域网 IP 地址
- **端口**：opencode 服务端口（默认 4096）
- **用户名/密码**：如有认证配置则填写

点击服务器卡片即可连接使用。

### ADB 无线连接（Android 11+）

无需 USB 线即可部署到手机：

```bash
# 首次配对
adb pair <ip>:<port>

# 连接设备
adb connect <ip>:<port>

# 部署运行
flutter run
```

> 手机需开启「开发者选项」→「无线调试」。

---

## 设计系统

应用拥有完整的设计系统（定义在 `lib/theme.dart`）：

- **主色**：靛蓝 (`#6366F1` / `#818CF8`)
- **配色**：成功绿、危险红、警告橙、信息蓝
- **圆角体系**：16px（默认）、12px（卡片）、8px（小圆角）、6px（标签）
- **暗色模式**：完整暗色系颜色变量（`DarkColors`）
- **终端配色**：仿 VS Code 终端主题

所有 UI 组件均使用统一的 `AppColors` 和 `DarkColors` 常量，确保视觉一致性。

---

## 开发指南

### 本地运行

```bash
# 安装依赖
flutter pub get

# 运行
flutter run

# 指定 platform
flutter run -d android
flutter run -d ios
flutter run -d chrome  # Web 预览
```

### 代码规范

- 所有 UI 文本必须使用 `S` 常量（`lib/strings.dart`），不要使用内联字符串
- 所有颜色/尺寸使用 `AppColors` / `DarkColors` 常量
- 遵循 `analysis_options.yaml` 中的 linter 规则
- 模型类统一放在 `lib/models/` 下，使用 `fromJson` 工厂方法

### 国际化

所有用户可见文本集中在 `lib/strings.dart` 的 `S` 类中。如需添加新的语言支持，只需为该类提供翻译即可。

---

## 相关资源

- [opencode 官方网站](https://opencode.ai)
- [Flutter 文档](https://flutter.dev/docs)
- [Dart 文档](https://dart.dev/guides)

---

## 许可证

[MIT License](LICENSE)

Copyright © 2025 OpenCode Remote Contributors
