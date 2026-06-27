# PRD: Spec Compliance Review — 规范符合性修复

> **分析日期**: 2026-06-27  
> **审查范围**: `lib/` 下全部 Flutter 代码  
> **审查依据**: `.trellis/spec/frontend/` 中全部规范文件  
> **总问题数**: ~50 个，分布在 15+ 文件  

---

## 1. 概述

### 1.1 目标

根据 `.trellis/spec/frontend/` 中定义的规范标准，对代码库进行全面审查和修复。

核心修复方向：
1. **UI 字符串集中化** — 将所有硬编码的中文/英文 UI 字符串迁移到 `S` 类
2. **共享组件替换** — 用 `AppCard` / `AppDialog` / `AppBottomSheet` / `AppLoadingIndicator` 等替换内联模式
3. **语法常量统一** — 将所有魔数（边框半径、内边距）替换为 `AppColors.kXxx` 常量
4. **布尔值命名规范** — 将所有布尔字段加上 `is`/`has`/`show` 前缀
5. **State 类超限修复** — 减少 `_ChatScreenState` 中的成员变量数量
6. **mounted 守卫补全** — 为所有 `setState` 在 `await` 之后的情况添加守卫
7. **内联私有小部件提取** — 将超过 50 行的私有小部件提取到独立文件

### 1.2 范围

- 只改动 `lib/` 下 Flutter 代码
- 不改动 `opencode-dev/`
- 只改动代码规范符合性，不改变任何运行时行为
- 已在 `06-27-clean-code-refactor` 中规划的修复任务不重复列出

### 1.3 与 `06-27-clean-code-refactor` 的关系

本 PRD 侧重于**规范符合性**（`spec compliance`），而 `06-27-clean-code-refactor` 侧重于**代码质量和架构重构**。两者有交集，本 PRD 聚焦于那些具体规范文件中明确要求的模式。

---

## 2. 发现汇总

| 规范文件 | 检查项 | 发现数 | 严重性 |
|---------|--------|--------|--------|
| `component-guidelines.md` | 共享组件使用 | 27 | 高 |
| `component-guidelines.md` | UI 字符串集中化 | 40+ | 高 |
| `component-guidelines.md` | 主题常量使用 | 28+ | 中 |
| `quality-guidelines.md` | 布尔值命名 | 8 | 中 |
| `state-management.md` | State 类成员 ≤ 20 | 1 | 高 |
| `hook-guidelines.md` | mounted 守卫 | 2 | 高 |
| `clean-code-patterns.md` | setState 后 mounted 检查 | 2 | 高 |
| `component-guidelines.md` | 内联小部件 > 50 行 | 2 | 中 |

---

## 3. Phase A: 高频 UI 模式规范化（高优先级）

### A.1 硬编码 UI 字符串 → `S.xxx` 引用

**涉及文件**: 11 个  
**实例数**: 40+ 处

**规范依据**: `component-guidelines.md` "UI Strings" — 所有面向用户的文本必须使用 `S.xxx`

| # | 文件 | 需替换字符串（示例） |
|---|------|-------------------|
| A1.1 | `lib/screens/settings_sheet.dart` | `'设置'` → `S.settings`, `'运行模式'` → `S.runMode`, `'原生模式'` → `S.nativeMode`, `'通过浏览器界面远程控制'` → `S.webviewDesc`, `'使用原生 Flutter 界面'` → `S.nativeDesc` |
| A1.2 | `lib/screens/native/config_screen.dart` | `'添加/更新配置'` → `S.addUpdateConfig`, `'配置键'` → `S.configKey`, `'配置值'` → `S.configValue`, `'取消'` → `S.cancel`, `'保存'` → `S.save`, `'配置已更新'` → `S.configUpdated`, `'更新失败'` → `S.updateFailed` |
| A1.3 | `lib/screens/launcher_screen.dart` | `'原生'/'WebView'` → `S.nativeMode`/待补充, `'设置'` → `S.settings`, `'服务器'` → `S.servers`, `'还没有服务器'` → `S.noServers`, `'点击 + 添加'` → `S.clickToAdd` |
| A1.4 | `lib/screens/onboarding_screen.dart` | `'选择你偏好的运行模式'` → `S.chooseMode`, `'通过浏览器界面远程控制'` → `S.webviewDesc`, `'原生模式'` → `S.nativeMode`, `'使用原生 Flutter 界面'` → `S.nativeDesc` |
| A1.5 | `lib/screens/native/file_browser_screen.dart` | `'加载失败: $e'` → `S.loadFailed`, `'读取失败: $e'` → `S.readFailed`, `'图片预览需要在服务端配置后可用'` → `S.imagePreviewHint`, `'搜索失败: $e'` → `S.searchFailed` |
| A1.6 | `lib/screens/webview_screen.dart` | `'加载失败: '` → `S.connectionFailed`, `'切换服务器'` → `S.switchServer`, `'添加新服务器'` → `S.addNewServer` |
| A1.7 | `lib/widgets/main_scaffold.dart` | `'仪表'` → 需在 `S` 中添加 `dashboard`, `'会话'` → `S.sessions`（需添加）, `'文件'` → 需添加 `files`, `'项目'` → `S.project`, `'诊断'` → `S.diagnostics` |
| A1.8 | `lib/widgets/app_states.dart` | `'连接失败'` → `S.connectionFailed`, `'重试'` → `S.retry` |
| A1.9 | `lib/widgets/code_block_builder.dart` | `'已复制'` → 需在 `S` 中添加 `copied` |
| A1.10 | `lib/widgets/reasoning_block.dart` | `'思考过程'` → 需在 `S` 中添加 `thinkingProcess` |
| A1.11 | `lib/screens/native/model_picker_sheet.dart` | `'无匹配模型'` → `S.noMatchModel`, `'选择模型'` → `S.selectModel`, `'搜索模型...'` → `S.searchModelHint` |

**需要新增的 S 常量**:
```dart
// General
static const copied = '已复制';
static const thinkingProcess = '思考过程';

// Navigation tabs
static const dashboard = '仪表';
static const sessions = '会话';
static const files = '文件';
static const project = '项目';
static const diagnostics = '诊断';

// Model picker
static const noMatchModel = '无匹配模型';
static const searchModelHint = '搜索模型...';
```

**Todo 清单**:
- [ ] A1.1: 修复 `settings_sheet.dart` 中的 5 处硬编码字符串
- [ ] A1.2: 修复 `config_screen.dart` 中的 7 处硬编码字符串
- [ ] A1.3: 修复 `launcher_screen.dart` 中的 7 处硬编码字符串
- [ ] A1.4: 修复 `onboarding_screen.dart` 中的 4 处硬编码字符串
- [ ] A1.5: 修复 `file_browser_screen.dart` 中的 5 处硬编码字符串
- [ ] A1.6: 修复 `webview_screen.dart` 中的 3 处硬编码字符串
- [ ] A1.7: 修复 `main_scaffold.dart` 中的 5 处硬编码字符串（需先在 `S` 中添加对应常量）
- [ ] A1.8: 修复 `app_states.dart` 中的 2 处硬编码字符串
- [ ] A1.9: 修复 `code_block_builder.dart` 中的 1 处硬编码字符串
- [ ] A1.10: 修复 `reasoning_block.dart` 中的 1 处硬编码字符串
- [ ] A1.11: 修复 `model_picker_sheet.dart` 中的 3 处硬编码字符串

---

### A.2 内联 AlertDialog → AppDialog

**规范依据**: `component-guidelines.md` "AppDialog" — 所有 AlertDialog 应使用 `AppDialog` 助手

**涉及文件**: 3 个文件，8 处

| # | 文件 | 行号 | 当前用途 | 替换方案 |
|---|------|------|---------|---------|
| A2.1 | `chat_screen.dart` | 143 | Permission Request 对话框 | `AppDialog.showCustom` + 3 个按钮的 actions |
| A2.2 | `chat_screen.dart` | 187 | Question 对话框 | `AppDialog.showCustom` + 2 个按钮 |
| A2.3 | `chat_screen.dart` | 473 | Message Detail 对话框 | `AppDialog.showCustom`（全屏 Dialog） |
| A2.4 | `chat_screen.dart` | 505 | 错误对话框 | `AppDialog.showConfirm`（确认按钮） |
| A2.5 | `chat_screen.dart` | 803 | Shell 确认对话框 | `AppDialog.showConfirm` |
| A2.6 | `config_screen.dart` | 82 | 编辑配置对话框 | 考虑用 `AppDialog.showCustom` |
| A2.7 | `session_list_screen.dart` | 339 | Fork 会话确认 | `AppDialog.showConfirm` |
| A2.8 | `session_list_screen.dart` | 373 | 待办列表（其实是 Dialog 含 ListView） | `AppDialog.showCustom` |

**注意**: 对于权限/问题对话框（A2.1, A2.2），因包含 3 个不同颜色/样式的按钮，可能需要对 `AppDialog` 进行增强以支持自定义 actions，或保持少量内联。

**Todo 清单**:
- [ ] A2.1: 将权限对话框改为 `AppDialog.showCustom`
- [ ] A2.2: 将问题对话框改为 `AppDialog.showCustom`
- [ ] A2.3: 将消息详情对话框改为 `AppDialog.showCustom`
- [ ] A2.4: 将错误对话框改为 `AppDialog.showConfirm`
- [ ] A2.5: 将 Shell 确认改为 `AppDialog.showConfirm`
- [ ] A2.6: 将编辑配置对话框改为 `AppDialog.showCustom`
- [ ] A2.7: 将 Fork 确认改为 `AppDialog.showConfirm`
- [ ] A2.8: 将待办列表改为 `AppDialog.showCustom`

---

### A.3 内联 showModalBottomSheet → AppBottomSheet

**规范依据**: `component-guidelines.md` "AppBottomSheet"

| # | 文件 | 行号 | 替换方案 |
|---|------|------|---------|
| A3.1 | `chat_screen.dart` | 599 | `AppBottomSheet.showOptions` |
| A3.2 | `chat_screen.dart` | 631 | `AppBottomSheet.showOptions` |
| A3.3 | `project_screen.dart` | 102 | `AppBottomSheet.showOptions` |
| A3.4 | `launcher_screen.dart` | 66 | `AppBottomSheet.show`（选服务器列表） |

**Todo 清单**:
- [ ] A3.1: 替换消息操作底部弹窗
- [ ] A3.2: 替换 Shell 操作底部弹窗
- [ ] A3.3: 替换项目操作底部弹窗
- [ ] A3.4: 替换服务器切换底部弹窗

---

### A.4 内联 Card → AppCard

**规范依据**: `component-guidelines.md` "AppCard"

| # | 文件 | 位置 | 当前代码 |
|---|------|------|---------|
| A4.1 | `dashboard_screen.dart` | `_SessionCard.build` | `Card(...)` 含 margin + InkWell |
| A4.2 | `session_list_screen.dart` | `_SessionCard.build` | `Card(...)` 含 margin + InkWell |
| A4.3 | `launcher_screen.dart` | `_ServerCard.build` | `Card(...)` 含 margin + InkWell |

**Todo 清单**:
- [ ] A4.1: 将 `dashboard_screen.dart` 中的 `Card` 替换为 `AppCard`
- [ ] A4.2: 将 `session_list_screen.dart` 中的 `Card` 替换为 `AppCard`
- [ ] A4.3: 将 `launcher_screen.dart` 中的 `Card` 替换为 `AppCard`

---

### A.5 内联 CircularProgressIndicator → AppLoadingIndicator

**规范依据**: `component-guidelines.md` "AppStates"

`AppLoadingIndicator`（`lib/widgets/app_states.dart`）已存在但**从未被使用**。所有 12 处加载状态都使用内联 `CircularProgressIndicator(color: AppColors.primary)`。

| # | 文件 | 行号 |
|---|------|------|
| A5.1 | `config_screen.dart` | 137 |
| A5.2 | `session_list_screen.dart` | 459 |
| A5.3-A5.5 | `file_browser_screen.dart` | 376, 389, 500, 565 |
| A5.6 | `terminal_screen.dart` | 166（terminalPrompt 颜色 — 此项可保留） |
| A5.7 | `chat_screen.dart` | 895 |
| A5.8 | `dashboard_screen.dart` | 189 |
| A5.9 | `project_screen.dart` | 65 |
| A5.10 | `launcher_screen.dart` | 141 |
| A5.11 | `webview_screen.dart` | 156 |

**Todo 清单**:
- [ ] A5.1: `config_screen.dart` — `CircularProgressIndicator(color: AppColors.primary)` → `AppLoadingIndicator()`
- [ ] A5.2: `session_list_screen.dart` — 同上
- [ ] A5.3-A5.5: `file_browser_screen.dart` — 4 处替换
- [ ] A5.7: `chat_screen.dart` — 1 处替换
- [ ] A5.8: `dashboard_screen.dart` — 1 处替换
- [ ] A5.9: `project_screen.dart` — 1 处替换
- [ ] A5.10: `launcher_screen.dart` — 1 处替换
- [ ] A5.11: `webview_screen.dart` — 1 处替换

---

## 4. Phase B: 常量与命名规范化（中优先级）

### B.1 魔数边框半径 → AppColors.kXxxBorderRadius

**规范依据**: `component-guidelines.md` "Border Radius Constants"

| 文件 | 出现次数 | 示例值 | 应替换为 |
|------|---------|-------|---------|
| `dashboard_screen.dart` | 3 | 6, 8, 12 | `kSmallBorderRadius`, `kSmallBorderRadius`, `kCardBorderRadius` |
| `tool_part_widget.dart` | 3 | 4, 6, 10 | `kChipBorderRadius`, `kChipBorderRadius`, `kSmallBorderRadius` |
| `message_bubble.dart` | 3 | 4, 8, 16 | `kChipBorderRadius`, `kSmallBorderRadius`, `kDefaultBorderRadius` |
| `launcher_screen.dart` | 4 | 4, 10, 12, 16 | `kChipBorderRadius`, `kSmallBorderRadius`, `kCardBorderRadius`, `kDefaultBorderRadius` |
| `onboarding_screen.dart` | 4 | 16, 20, 24 | 需要新的常量或接受接近的近似值 |
| `model_picker_sheet.dart` | 3 | 10 | `kSmallBorderRadius` |
| `file_parts_row.dart` | 2 | 10 | `kSmallBorderRadius` |
| `reasoning_block.dart` | 2 | 10 | `kSmallBorderRadius` |
| `chat_input_bar.dart` | 3 | 20 | 需要新的常量或接受近似值 |
| `code_block_builder.dart` | 1 | 8 | `kSmallBorderRadius` |
| `session_list_screen.dart` | 2 | 10, 12 | `kSmallBorderRadius`, `kCardBorderRadius` |
| `main_scaffold.dart` | 1 | 16 | `kDefaultBorderRadius` |

**Todo 清单**:
- [ ] B1.1: `dashboard_screen.dart` — 替换所有魔数边框半径
- [ ] B1.2: `tool_part_widget.dart` — 替换所有魔数边框半径
- [ ] B1.3: `message_bubble.dart` — 替换所有魔数边框半径
- [ ] B1.4: `launcher_screen.dart` — 替换所有魔数边框半径
- [ ] B1.5: `onboarding_screen.dart` — 替换所有魔数边框半径
- [ ] B1.6: `model_picker_sheet.dart` — 替换所有魔数边框半径
- [ ] B1.7: `file_parts_row.dart` — 替换所有魔数边框半径
- [ ] B1.8: `reasoning_block.dart` — 替换所有魔数边框半径
- [ ] B1.9: `chat_input_bar.dart` — 替换所有魔数边框半径（20 可能需要新常量）
- [ ] B1.10: `code_block_builder.dart` — 替换魔数边框半径
- [ ] B1.11: `session_list_screen.dart` — 替换所有魔数边框半径
- [ ] B1.12: `main_scaffold.dart` — 替换魔数边框半径

**需要新增的常量**（在 `theme.dart` 的 `AppColors` 中）:
```dart
static const double kMediumBorderRadius = 20;   // 用于 chat_input_bar.dart, onboarding_screen.dart
```

---

### B.2 魔数内边距 → AppColors.kPaddingXxx

**规范依据**: `component-guidelines.md` "Padding Constants"

| 当前值 | 应替换为 |
|--------|---------|
| `EdgeInsets.all(16)`（屏幕级间距） | `AppColors.kPaddingScreen` |
| `EdgeInsets.all(14)`（卡片内容间距） | `AppColors.kPaddingCard` |
| `EdgeInsets.all(12)`, `EdgeInsets.all(10)` 等（小型间距） | 可新增常量或手工处理 |

**Todo 清单**:
- [ ] B2.1: 查找所有 `EdgeInsets.all(16)` 并替换为 `AppColors.kPaddingScreen`
- [ ] B2.2: 查找所有 `EdgeInsets.all(14)` 并替换为 `AppColors.kPaddingCard`
- [ ] B2.3: 评估是否需要在 `AppColors` 中添加更多内边距常量

---

### B.3 布尔值命名规范化

**规范依据**: `quality-guidelines.md` "Naming Conventions" — 布尔值前缀使用 `is`/`has`/`show`

| # | 文件 | 当前名称 | 应为 |
|---|------|-----------|------|
| B3.1 | `chat_screen.dart` + 所有屏幕 | `_loading` | `_isLoading` |
| B3.2 | `chat_screen.dart` | `_sending` | `_isSending` |
| B3.3 | `chat_screen.dart` | `_shellMode` | `_isShellMode` |
| B3.4 | `file_browser_screen.dart` | `_searchMode` | `_isSearchMode` |
| B3.5 | `file_browser_screen.dart` + `session_list_screen.dart` | `_searching` | `_isSearching` |
| B3.6 | `reasoning_block.dart` | `_expanded` | `_isExpanded` |
| B3.7 | `event_service.dart` | `_cancelled` | `_isCancelled` |

**Todo 清单**:
- [ ] B3.1: 重命名所有 `_loading` → `_isLoading`
- [ ] B3.2: 重命名 `_sending` → `_isSending`
- [ ] B3.3: 重命名 `_shellMode` → `_isShellMode`
- [ ] B3.4: 重命名 `_searchMode` → `_isSearchMode`
- [ ] B3.5: 重命名 `_searching` → `_isSearching`
- [ ] B3.6: 重命名 `_expanded` → `_isExpanded`
- [ ] B3.7: 重命名 `_cancelled` → `_isCancelled`

---

## 5. Phase C: 代码结构规范化（中高优先级）

### C.1 State 类成员变量超限

**规范依据**: `state-management.md` "State Class Health" — ≤ 20 个成员

`_ChatScreenState` 目前有 22 个成员变量。需要将相关字段提取到领域特定组中。

```dart
// 提取方案：
class _StreamingState {
  final Map<String, String> deltas = {};
  final Map<String, Map<String, dynamic>> toolStates = {};
}

class _InputState {
  final TextEditingController controller = TextEditingController();
  final List<String> history = [];
  bool shellMode = false;
  bool showCommands = false;
  List<Command> filteredCommands = [];
  // ...
}

class _AttachmentState {
  List<Map<String, dynamic>> attachments = [];
  // ...
}
```

这样可以将 `_ChatScreenState` 从 22 个成员减少到 ~14 个。

**Todo 清单**:
- [ ] C1.1: 创建 `_StreamingState` 辅助类，提取 `_streamingDeltas` 和 `_streamingToolStates`
- [ ] C1.2: 将输入相关字段（`_inputCtrl`, `_inputHistory`, `_shellMode`, `_showCommands`, `_filteredCommands`）归组到 `_InputState` 或保持分散但确保总成员数降到 20 以下
- [ ] C1.3: 验证 `_ChatScreenState` 最终成员数 ≤ 20

---

### C.2 mounted 守卫补全

**规范依据**: `hook-guidelines.md` "Always check mounted before calling setState after await"

| # | 文件 | 行号 | 问题 |
|---|------|------|------|
| C2.1 | `launcher_screen.dart` | 38-41 | `_reload()` 中 `await` 后直接 `setState`，无 `mounted` 检查 |
| C2.2 | `settings_sheet.dart` | 160-163 | `_setTheme()` 中 `await` 后直接 `setState`，无 `mounted` 检查 |

```dart
// 修复方案
Future<void> _reload() async {
  final servers = await StorageService.loadServers();
  if (!mounted) return;    // ← 添加
  setState(() { ... });
}
```

**Todo 清单**:
- [ ] C2.1: 在 `launcher_screen.dart:_reload()` 中 `await` 后添加 `if (!mounted) return;`
- [ ] C2.2: 在 `settings_sheet.dart:_setTheme()` 中 `await` 后添加 `if (!mounted) return;`

---

### C.3 内联私有小部件提取

**规范依据**: `component-guidelines.md` "Extraction Threshold" — 私有小部件 > 50 行应提取到独立文件

| # | 文件 | 类名 | 行数 | 状态 |
|---|------|------|------|------|
| C3.1 | `launcher_screen.dart` | `_ServerCard` | ~65 行 | ❌ 应提取 |
| C3.2 | `dashboard_screen.dart` | `_StatusCard` | ~60 行 | ❌ 应提取 |
| C3.3 | `file_browser_screen.dart` | `_TreeNode` | ~30 行 | ✅ 保持内联 |
| C3.4 | `session_list_screen.dart` | `_SessionCard` | ~30 行 | ✅ 保持内联（但含 `Card()` 违规 A4.2） |

**Todo 清单**:
- [ ] C3.1: 将 `_ServerCard` 提取为 `lib/widgets/server_card.dart` 中的 `ServerCard`（public 类）
- [ ] C3.2: 将 `_StatusCard` 提取为 `lib/widgets/status_card.dart` 中的 `StatusCard`（public 类）

---

## 6. 时间估算

| 阶段 | 估计工作量 | 依赖 |
|------|-----------|------|
| **Phase A: UI 规范** | 2-3 天 | 无 |
| A.1 字符串集中化 | 1 天 | 无 |
| A.2-A.4 组件替换 | 1-2 天 | 无 |
| A.5 AppLoadingIndicator | 0.5 天 | 无 |
| **Phase B: 常量/命名** | 1-2 天 | 无 |
| B.1 边框半径 | 0.5 天 | 无 |
| B.2 内边距 | 0.5 天 | 无 |
| B.3 布尔值命名 | 0.5 天 | 无 |
| **Phase C: 代码结构** | 1-2 天 | 部分依赖 Phase A |
| C.1 State 成员提取 | 1 天 | 无 |
| C.2 mounted 守卫 | 0.25 天 | 无 |
| C.3 小部件提取 | 0.5 天 | 无 |

**总计**: 4-7 天（可与 `06-27-clean-code-refactor` 中的非重叠任务并行）

---

## 7. 成功标准

- [ ] `flutter analyze` 通过且零错误
- [ ] 无新的运行时行为变更
- [ ] 所有 11 个屏幕文件中无硬编码 UI 字符串
- [ ] `AppLoadingIndicator`/`AppErrorState`/`AppEmptyState` 在 >= 1 个屏幕中使用
- [ ] `_ChatScreenState` 成员变量 ≤ 20
- [ ] 所有布尔变量符合 `is`/`has`/`show` 前缀规范
- [ ] 所有 `setState` 在 `await` 之后都有 `mounted` 保护
