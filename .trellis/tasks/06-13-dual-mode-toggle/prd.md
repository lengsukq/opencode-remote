# PRD: 两种运转模式 — WebView / 完整原生实现

## 概述

在 opencode_remote 中增加双模式切换能力：保留现有 WebView 模式，同时用原生 Flutter UI 完整替代 WebView，通过 opencode HTTP REST API 直接交互。

## 功能需求

### 1. 首次启动选择
- 首次打开 App 时展示 iOS 风格的选择界面
- 风格：大圆角、毛玻璃效果、白灰配色、阴影
- 两个选项卡片：WebView 模式 / 原生模式
- 选择后进入对应模式的首页，不再重复显示（除非清除数据）

### 2. 设置入口
- 所有页面 AppBar 右上角加设置图标 (gear icon)
- 弹出菜单/Popover，包含模式切换开关（可加简短说明）
- 切换后立即跳转到对应模式的首页

### 3. WebView 模式（现有，无需改动）
- 保持现有 `WebViewScreen` 行为
- 加载 opencode Web UI
- 支持基本认证

### 4. 原生模式 — Dashboard
- 连接状态卡片：服务器地址、健康状态 (`/global/health`)、当前用户
- 最近会话列表：最近 5 条会话，显示标题、时间
- 快捷操作：新建会话、切换项目、查看所有会话

### 5. 原生模式 — 会话管理
- 会话列表页：显示所有会话 (`GET /session`)
- 支持创建新会话 (`POST /session`)
- 支持删除会话 (`DELETE /session/:id`)
- 支持搜索会话

### 6. 原生模式 — 消息/聊天
- 消息列表页：显示会话中的消息 (`GET /session/:id/message`)
- 发送消息 (`POST /session/:id/message`)
- 支持 markdown 渲染
- 消息气泡样式

### 7. 原生模式 — 文件浏览
- 文件树/文件列表 (`GET /file?path=...`)
- 文件内容阅读 (`GET /file/content?path=...`)
- 文本搜索 (`GET /find`)

### 8. 原生模式 — 项目信息
- 当前项目展示 (`GET /project/current`)
- 项目路径、VCS 信息 (`GET /vcs`)
- 切换项目

## 技术方案

### 新增/修改文件

```
lib/
├── main.dart                          # 修改：首次启动判断 + 路由分发
├── models.dart                        # 新增 API 数据模型
├── screens/
│   ├── launcher_screen.dart           # 修改：加设置入口
│   ├── webview_screen.dart            # 不变
│   ├── onboarding_screen.dart         # 新增：首次启动选择
│   ├── settings_sheet.dart            # 新增：设置面板（模式切换）
│   ├── native/
│   │   ├── dashboard_screen.dart      # 新增
│   │   ├── session_list_screen.dart   # 新增
│   │   ├── chat_screen.dart           # 新增
│   │   ├── project_screen.dart        # 新增
│   │   └── file_browser_screen.dart   # 新增
│   └── widgets/                       # 新增目录
│       ├── glass_card.dart            # 毛玻璃卡片组件
│       ├── session_tile.dart          # 会话列表项
│       ├── message_bubble.dart        # 消息气泡
│       └── status_card.dart           # 状态卡片
└── services/
    ├── storage_service.dart           # 修改：增加模式持久化
    └── opencode_api.dart              # 新增：opencode REST API 封装
```

### API 层 (`opencode_api.dart`)

封装 opencode HTTP Server 的 REST API 调用：
- 基础 URL + Basic Auth 配置
- 通用 HTTP 请求方法 (GET/POST/DELETE/PATCH)
- 各端点方法对应
- JSON 响应解析为 Dart 模型

### 模式状态管理

- `SharedPreferences` 存储当前模式 (`key: "app_mode"`, values: `"webview"` / `"native"`)
- `StorageService.getAppMode()` / `setAppMode()`
- 首次启动标记 (`hasLaunched` key)
- 模式切换时 clear navigation stack 并 push 对应首页

### 设计规范

- iOS 毛玻璃风格选择界面：白/灰色调、大圆角 (radius 20+)、阴影、半透明毛玻璃效果
- 原生模式内部沿用现有深色主题（0xFF0D1117 等），保持一致
- Dashboard 使用卡片式布局
- 消息列表用气泡样式

## 非功能需求

- 所有 API 调用要有 loading 和错误处理
- API 调用失败时展示友好的错误提示，不 crash
- 敏感信息（密码、token）不在日志中输出
