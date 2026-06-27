# PRD: 编程体验增强 — 输入历史/中止/诊断/上下文

> **分析日期**: 2026-06-27
> **范围**: `lib/` 下 Flutter 代码（不改动 `opencode-dev/`）
> **状态**: Phase 3-4 ✅ 已完成, Phase 5 ⏳ 大部分完成, 剩余 Follow-up 建议

---

## 完成度追踪

| Phase | 内容 | 状态 |
|-------|------|------|
| Phase 3 | 输入体验增强 (输入历史/中止/Shell模式) | ✅ 已完成 |
| Phase 4 | 诊断与反馈 (诊断/上下文指示器/待办) | ✅ 已完成 |
| Phase 5 | 交互式 UI (Follow-up/权限/问题/Revert) | ✅ 已完成 |

---

## 1. 概述

### 1.1 目标
补齐 Flutter 客户端与 Web UI 在编程核心体验上的差距，包括输入效率、实时反馈和交互式 UI。

### 1.2 背景
Phase 1+2 已实现文件附件发送和工具 Part 渲染。当前剩余核心缺口：

- **输入体验**：无法浏览历史输入、不能快速中止请求、无 shell 模式
- **诊断反馈**：AI 代码中的 lint 错误在 Web 端内联显示，Flutter 端完全不可见
- **上下文感知**：不知道 token 使用量、无法查看 AI 的待办列表
- **交互式 UI**：权限、问题、follow-up 的交互体验简陋

### 1.3 范围
- 只改动 `lib/` 下 Flutter 代码
- 不改动 `opencode-dev/`

---

## 2. 阶段划分

### Phase 3: 输入体验增强（P0）

#### 2.1.1 输入历史

| # | 需求 | 优先级 | 参考 Web |
|---|------|--------|---------|
| H1 | ArrowUp/Down 浏览已发送的消息（上限 100 条） | P0 | `prompt-input.tsx` → `history.ts` |
| H2 | 历史持久化到本地存储 (`shared_preferences`) | P0 | `Persist.global("prompt-history", ...)` |
| H3 | 输入框空时 ArrowUp 恢复最近一条输入 | P0 | - |
| H4 | 历史跨越会话重启后保留 | P1 | - |

**实现要点：**
- 在 `_ChatScreenState` 增加 `List<String> _inputHistory` 和 `int _historyIndex`
- `_sendMessage()` 成功后将输入存入历史
- 监听键盘 ArrowUp/Down（通过 `KeyboardListener` 或 `CallbackShortcuts`）
- 持久化：`StorageService` 存储 JSON 数组

#### 2.1.2 快速中止

| # | 需求 | 优先级 | 参考 Web |
|---|------|--------|---------|
| H5 | 发送消息后输入栏变为"停止"按钮（替代发送按钮） | P0 | `prompt-input.tsx` |
| H6 | 点击停止调用 `POST /session/:id/abort` | P0 | `Ctrl+G` / abort 按钮 |
| H7 | 中止后自动刷新消息，重置输入栏 | P0 | - |

**实现要点：**
- `_sending` 为 true 时，`_buildInputBar()` 的发送按钮替换为红色停止图标
- 停止按钮调用已有的 `widget.api.abortSession()`
- 中止后 `_sending = false`，恢复输入栏

#### 2.1.3 Shell 模式

| # | 需求 | 优先级 | 参考 Web |
|---|------|--------|---------|
| H8 | 输入 `!` 开头时输入框视觉切换（mono 字体、改背景色） | P1 | `prompt-input.tsx` Shell 模式 |
| H9 | `!command` 按回车时调用 `POST /session/:id/shell`（已有 API） | P1 | - |
| H10 | Backspace 清空后退出 shell 模式 | P2 | - |

**实现要点：**
- `_onInputChanged()` 检测 text 是否以 `!` 开头
- 切换 TextField 的 `style` 为 monospace + 不同背景色
- 发送时判断 shell 模式 → 调用 `runShell()` 而非 `sendMessage()`

---

### Phase 4: 诊断与反馈（P0）

#### 2.2.1 代码诊断

| # | 需求 | 优先级 | 参考 Web |
|---|------|--------|---------|
| D1 | `write` 工具 Part 渲染时检查 `metadata.diagnostics` | P0 | `edit.tsx`/`write.tsx` → `DiagnosticsDisplay()` |
| D2 | 显示诊断信息：行号+严重度+消息 | P0 | 红色/黄色徽标 |
| D3 | 最多显示 3 条，仅 severity=1（error） | P0 | 同 Web |
| D4 | 诊断显示在代码块下方 | P0 | - |

**实现要点：**
- `_ToolPartWidget._buildInput()` 中对 `write` 类型检查 `input['diagnostics']`
- 如果是 list，遍历最多前 3 条，渲染为红色警告条
- 显示格式：`行 ${line}: ${message}`

#### 2.2.2 上下文使用指示器

| # | 需求 | 优先级 | 参考 Web |
|---|------|--------|---------|
| D5 | 会话头显示 token 使用环形进度条 | P1 | `session-context-usage.tsx` |
| D6 | 点击打开详情：input/output/reasoning/cache 分项 | P2 | `session-context-tab.tsx` |
| D7 | 成本摘要（session.cost） | P2 | - |

**实现要点：**
- 从 `session.tokens`（已有模型）读取数据
- 在 `_agentBar` 左侧或 AppBar 添加 `CustomPaint` 环形进度
- 颜色渐变：绿 → 黄 → 红

#### 2.2.3 待办事项显示

| # | 需求 | 优先级 | 参考 Web |
|---|------|--------|---------|
| D8 | 从 `/session/{id}/todo` 获取并展示待办列表 | P1 | `session-todo-dock.tsx` |
| D9 | 用复选框展示，可勾选完成 | P1 | 动画进度 + 脉冲 |
| D10 | 完成时显示 "x/y 已完成！" | P2 | - |

**实现要点：**
- 新增 `_TodoDock` 组件，底部浮动显示
- 调用 `widget.api.getSessionTodo(sessionId)` 已有 API
- 复选框状态仅本地，不写回服务器

---

### Phase 5: 交互式 UI（P1）

#### 2.3.1 Follow-up 建议

| # | 需求 | 优先级 | 参考 Web |
|---|------|--------|---------|
| F1 | AI 回复后在输入栏上方显示建议的后续消息 | P1 | `session-followup-dock.tsx` |
| F2 | 点击建议自动填入输入框或直接发送 | P1 | - |
| F3 | 支持编辑建议再发送 | P2 | - |

**实现要点：**
- 监听 SSE `message.new` 事件后，检查最新消息的 `metadata.followUp`
- 渲染为横向滚动的 Chip 列表
- 点击 Chip → 填入输入框

#### 2.3.2 权限请求增强

| # | 需求 | 优先级 | 参考 Web |
|---|------|--------|---------|
| F4 | 三按钮：一次允许 / 始终允许 / 拒绝 | P1 | `session-permission-dock.tsx` |
| F5 | "始终允许"调用 `POST /permission/{id}` 带 `remember: true` | P1 | - |

**实现要点：**
- 修改 `_handlePermission()` 的对话框布局
- 第三个按钮 "始终允许" → `{'response': 'allow', 'remember': true}`

#### 2.3.3 问题对话框增强

| # | 需求 | 优先级 | 参考 Web |
|---|------|--------|---------|
| F6 | 支持多选选项（options 列表） | P2 | `session-question-dock.tsx` |
| F7 | 支持自定义文本输入 | P2 | - |

#### 2.3.4 Revert Dock

| # | 需求 | 优先级 | 参考 Web |
|---|------|--------|---------|
| F8 | 回退后显示被回退的文件列表 | P2 | `session-revert-dock.tsx` |
| F9 | 支持逐文件手动恢复 | P2 | - |

---

## 3. 非功能性需求

| # | 需求 | 说明 |
|---|------|------|
| N1 | 输入历史持久化上限 100 条，超限截断旧条目 |
| N2 | 中止请求后 SSE 事件继续正常处理 |
| N3 | 上下文指示器在会话创建/切换时自动重新获取 |
| N4 | 所有新 UI 组件遵循现有暗色主题 + AppColors |

## 4. 里程碑

| 里程碑 | 内容 | 预估工作量 |
|--------|------|-----------|
| M3 (Phase 3) | 输入历史 + 中止 + Shell 模式 | 2 天 |
| M4a (Phase 4) | 诊断 + 上下文指示器 + 待办 | 2 天 |
| M5 (Phase 5) | Follow-up + 权限/问题对话框 + Revert | 2 天 |

## 5. 不纳入范围

- 搜索式会话列表（移动端不需要）
- 侧面板（文件树+差异+上下文组合面板）
- 设置 V2 全面重写（仅增量改进现有 ConfigScreen）
- `@mention` 文件搜索（移动端场景不适用）
