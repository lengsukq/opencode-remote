# PRD: Flutter 客户端功能对齐 Web 端

## 1. 概述

### 1.1 目标
将 Flutter 移动客户端（`opencode_remote`）的功能与 opencode Web UI 对齐，消除体验落差，确保移动端用户能够使用完整的 opencode 功能。

### 1.2 背景
当前 Flutter 客户端实现了 opencode REST API 的大部分端点调用，但存在以下核心差距：
- **消息发送**仅支持纯文本，无法像 Web 端一样附带文件/图片
- **消息渲染**忽略了多个服务器返回的 Part 类型
- **命令/功能唤起**体验简陋，缺少 Web 端的弹出面板、输入历史、@ 提及等
- **交互式 UI**（权限、待办、上下文统计等）缺失或过于简单

### 1.3 范围
- 参考代码: `opencode-dev/packages/app/`（React 前端）、`opencode-dev/packages/web/`（Astro 共享页）
- 参考 API: `https://opencode.ai/docs/zh-cn/server/`
- 实现目标: `opencode_remote` Flutter 包（`lib/`）
- **不改动 `opencode-dev/` 下任何文件**

---

## 2. 阶段划分

### Phase 1: 文件发送与附件（高优先级）

#### 2.1.1 功能描述
允许用户从手机本地选择文件/图片附加到聊天消息中发送。

#### 2.1.2 参考实现
Web 端 `prompt-input.tsx` 通过以下方式实现：
- **文件选择器按钮**：输入框旁的 `+` 按钮调用 `pickAttachmentFiles()`
- **全局拖放**：`handleGlobalDrop()` 监听 `dragover`/`drop`
- **剪贴板粘贴**：`handlePaste()` 处理 Ctrl+V 图片和文件
- **图片预览**：`PromptImageAttachments` 展示缩略图行，点击进入 `ImagePreview` 全屏

#### 2.1.3 要求

| # | 需求 | 优先级 |
|---|------|--------|
| F1 | 输入框旁添加**附件按钮**（`+`），点击触发系统文件选择器 | P0 |
| F2 | 支持选择**图片**（相册 + 拍照）和**文件**（本地存储） | P0 |
| F3 | 选中文件后在输入框上方显示**附件缩略图/文件名列表**，可移除 | P0 |
| F4 | 发送消息时将文件构造为 `{'type': 'file', 'mime': ..., 'url': ..., 'filename': ...}` Part | P0 |
| F5 | **剪贴板粘贴图片**（从系统剪贴板读取并附加） | P1 |
| F6 | **图片全屏预览**（点击缩略图放大查看） | P1 |
| F7 | 消息接收端渲染 `file` 类型的 Part（显示文件名、图标、图片缩略图） | P0 |
| F8 | 支持 `image_picker` + `file_picker` 依赖 | P0 |

#### 2.1.4 API 变更
- 消息体 `parts` 数组新增 `{'type': 'file', 'mime': 'image/png', 'url': 'data:image/png;base64,...', 'filename': 'screenshot.png'}`（或通过服务端 `/upload` 上传后引用——需确认是否有上传端点）
- `sendMessage()` / `sendMessageAsync()` 增加 `parts` 参数，允许 caller 传入混合 Parts

#### 2.1.5 依赖新增
```
dependencies:
  image_picker: ^1.x
  file_picker: ^8.x
```

---

### Phase 2: 消息 Part 渲染完善（高优先级）

#### 2.2.1 功能描述
Web 端对每种 Part 类型有专用渲染器；Flutter 端需要补齐。

#### 2.2.2 参考实现
Web 端 `message-part/` 包实现了：
- `file` → 附件名称/图标
- `tool`（`bash`） → 命令 + 输出块
- `tool`（`read`） → 代码预览（Shiki 高亮）
- `tool`（`write`/`edit`） → 代码 + 差异 + 诊断
- `tool`（`grep`/`glob`） → 结果列表 + 计数
- `tool`（`webfetch`） → 获取结果标题 + 内容
- `tool`（`task`） → 子任务详情
- `patch` → 差异对比
- `reasoning` → 可折叠推理输出
- `subtask` → 子任务描述 + agent
- `step-start` / `step-finish` → 提供者图标 + 模型名称

#### 2.2.3 要求

| # | 需求 | 优先级 |
|---|------|--------|
| P1 | 渲染 `file` Part：文件名 + 图标 + 图片缩略图，点击文件可下载/打开 | P0 |
| P2 | `tool` Part 按工具类型分开展示：bash/read/write/edit/grep/glob/task/webfetch | P0 |
| P3 | `tool` Part 支持**展开/折叠**输出内容 | P0 |
| P4 | 渲染 `reasoning` Part：可折叠区域，灰色背景，带"推理"标签 | P0 |
| P5 | 渲染 `patch` Part：代码差异高亮展示（参考 DiffView widget 扩展） | P1 |
| P6 | 渲染 `subtask` Part：显示子任务标题 + agent 名称 | P1 |
| P7 | 渲染 `step-start` / `step-finish` Part：显示 AI 切换步骤 | P2 |
| P8 | 保持向后兼容：当前文本和工具输出不退化 | P0 |

#### 2.2.4 Part 解析逻辑变更
- `Message._extractContent()` 当前只提取了 `text`、`reasoning`、`tool` 中的 output
- 需要改为保留**完整 Parts 列表**供 UI 逐条渲染，而非合入 content 字符串

#### 2.2.5 数据模型变更
- `Message` 类新增 `List<Part> parts` 字段
- `Message.fromInfo()` 从入参 `parts` 列表解析出各个 Part 对象

---

### Phase 3: 命令/功能唤起增强（中优先级）

#### 2.3.1 功能描述
提升 Flutter 端的命令输入体验，接近 Web 端的弹出面板水平。

#### 2.3.2 参考实现
Web 端 `prompt-input.tsx` + `slash-popover.tsx`：
- `/` → 斜杠命令弹出窗，显示描述和类型标签（内置/MCP/技能）
- `@` → agent + 文件弹出窗
- `!` → shell 模式（等宽字体，禁用拼写检查）
- ArrowUp/Down → 浏览历史（最多 100 条）
- Ctrl+G → 中止运行

#### 2.3.3 要求

| # | 需求 | 优先级 |
|---|------|--------|
| C1 | 输入 `/` 后弹出命令列表浮层：显示命令名 + 描述 + 参数提示 | P0 |
| C2 | 支持内置命令和自定义命令（从 `/command` API 同步） | P0 |
| C3 | 选择命令后自动填入参数模板或提示 | P1 |
| C4 | **输入历史**：ArrowUp/Down 浏览已发送的消息 | P1 |
| C5 | **Agent 快捷选择**：输入框上方显示当前 agent，可快速切换 | P1 |
| C6 | **输入框增强**：检测 shell 命令并切换显示模式 | P2 |
| C7 | **快速中止**：运行中的消息可一键取消（`abort`） | P1 |

---

### Phase 4: 交互式 UI 组件完善（中优先级）

#### 2.4.1 功能描述
Web 端有 dock 体系（权限、待办、follow-up、revert）；Flutter 端需补齐。

#### 2.4.2 要求

| # | 需求 | 优先级 |
|---|------|--------|
| I1 | **权限请求**对话框改为三按钮（一次允许 / 始终允许 / 拒绝） | P1 |
| I2 | **待办事项**显示：从 `/session/{id}/todo` 获取并展示为可勾选列表 | P1 |
| I3 | **Follow-up 建议**：在 AI 回复后显示建议的后续消息，点击即发送 | P2 |
| I4 | **会话分叉 UI**：消息长按菜单 → "从此处分叉"，确认后创建子会话 | P1 |
| I5 | **上下文使用指示器**：在会话头显示 token 使用量环状进度 | P2 |
| I6 | **会话 init**：接入 `POST /session/{id}/init` 端点 | P2 |

---

## 3. 非功能性需求

| # | 需求 | 说明 |
|---|------|------|
| N1 | 保持离线兼容 | 非网络操作不应阻塞 UI |
| N2 | SSE 事件响应 | 通过 `EventService` 实时响应 Part delta、permission、question 事件 |
| N3 | 低端设备适配 | 文件选取、图片压缩不应导致 OOM |
| N4 | 无障碍 | 所有交互元素应有语义标签 |

---

## 4. 里程碑

| 里程碑 | 内容 | 预计工作量 |
|--------|------|-----------|
| M1 (Phase 1) | 文件选择 + 附件 Part 发送 + 接收渲染 | 3-5 天 |
| M2 (Phase 2) | 完整 Part 渲染管线（工具、推理、差异等） | 4-6 天 |
| M3 (Phase 3) | 命令系统增强 + 输入历史 + agent 选择 | 2-3 天 |
| M4 (Phase 4) | 权限/待办/follow-up/分叉 UI | 2-4 天 |

---

## 5. 不纳入范围

- 桌面端功能（标题栏、标签管理、外部编辑器打开）
- 公共分享页面（Web 专属 `s/[id].astro`）
- Shiki 语法高亮（使用 flutter_highlight 替代）
- Web 端 contenteditable 富文本编辑器模式（移动端不适合）
