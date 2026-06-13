# opencode_remote

通过手机远程控制 [opencode](https://opencode.ai) AI 编程助手。支持两种运行模式：WebView 和原生 Flutter UI。

## 功能

- **双模式切换**：WebView 模式（加载 opencode Web 界面）和原生模式（原生 Flutter UI）
- **首次启动引导**：iOS 风格毛玻璃模式选择界面
- **Dashboard**：服务器状态、最近会话、快捷操作
- **会话管理**：查看/创建/删除会话，发送消息
- **文件浏览**：远程浏览项目文件，查看文件内容
- **项目信息**：查看当前项目和所有项目列表
- **多服务器**：管理多个 opencode 服务器连接

## 截图

| 模式选择 | Dashboard | 会话列表 | 聊天 |
|---|---|---|---|
| iOS 毛玻璃风格 | 服务器状态 + 最近会话 | 列表 + 新建/删除 | 消息发送 |

## 快速开始

1. 在电脑上启动 opencode 服务器：
   ```bash
   opencode serve [--port 4096]
   ```

2. 手机和电脑在同一局域网，打开 App，点击 **+** 添加服务器

3. 填写：
   - **名称**：任意名称
   - **地址**：电脑的 IP 地址
   - **端口**：opencode 服务器端口（默认 4096）
   - **用户名/密码**：如需认证，设置 `OPENCODE_SERVER_PASSWORD` 环境变量

4. 选择运行模式开始使用

## 运行模式

### WebView 模式
通过 WebView 加载 opencode Web 界面，功能完整，兼容性最好。

### 原生模式
原生 Flutter UI，通过 opencode REST API 直接交互：
- Dashboard 概览
- 会话列表/消息聊天
- 文件浏览
- 项目信息

可在设置中随时切换模式。

## 技术栈

- **框架**：Flutter (Dart SDK ^3.11.4)
- **API**：opencode HTTP Server (REST API)
- **存储**：SharedPreferences
- **状态管理**：setState

## 开发

```bash
# 获取依赖
flutter pub get

# 运行（需连接手机）
flutter run

# 代码检查
flutter analyze
```

## 项目结构

```
lib/
├── main.dart                       # 入口 + 路由分发
├── models.dart                     # 数据模型
├── screens/
│   ├── onboarding_screen.dart      # 首次启动模式选择
│   ├── launcher_screen.dart        # 服务器列表
│   ├── webview_screen.dart         # WebView 模式
│   ├── settings_sheet.dart         # 设置面板
│   └── native/
│       ├── dashboard_screen.dart   # Dashboard
│       ├── session_list_screen.dart# 会话列表
│       ├── chat_screen.dart        # 消息聊天
│       ├── file_browser_screen.dart# 文件浏览
│       └── project_screen.dart     # 项目信息
└── services/
    ├── storage_service.dart        # 本地存储
    └── opencode_api.dart           # opencode REST API 封装
```

## 环境要求

- Flutter SDK ^3.11.4
- opencode 服务端（任意版本，需启用 HTTP 服务器）
- Android / iOS 设备（与服务器同局域网）
