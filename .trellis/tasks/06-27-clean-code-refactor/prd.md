# PRD: Clean Code 重构 — 技术债务偿还计划

## 1. 概述

### 1.1 目标
对 Flutter 客户端进行全面 Clean Code 重构，消除三轮 review 积累的 **70 个代码质量问题**，降低维护成本，防止新 bug 引入。

### 1.2 背景
- **Round 1** (06-13): 发现 41 个问题，涵盖空 catch、不安全转型、重复代码、build 方法超标等
- **Round 2** (06-13): 41 个问题全部未修复，新增 7 个问题（命名误导、变量副作用、魔数等）
- **Round 3** (06-27): 48 个问题全部未修复，新增 22 个问题（文件过大、SRP 违反、shell 注入等）

三轮累计 **70 个问题**，其中 P0 级 7 个、P1 级 15 个、P2 级 25+ 个。

### 1.3 范围
- 只改动 `lib/` 下 Flutter 代码
- 不改动 `opencode-dev/`
- 功能行为零变化——重构仅涉及代码结构、命名、安全性，不含新功能

### 1.4 不纳入范围
- 新增 UI 功能（另有 06-27-ux-enhancement 任务跟踪）
- 测试框架引入（后续单独任务）
- 升级第三方依赖版本

---

## 2. 阶段划分

---

### Phase 0: 安全底线修复（P0 — 可能导致运行时崩溃）

这些问题的共同特征：**线上用户可能因此遇到白屏、数据丢失或不可恢复的错误。**

#### R0.1 — 消除空 catch 吞异常 (3 处)

| # | 文件 | 行 | 问题 | 风险 |
|---|------|-----|------|------|
| E01 | `chat_screen.dart` | 293 | `catch (_) {}` — `_loadTodos` 失败后静默 | 待办列表永不加载，用户无反馈 |
| E02 | `chat_screen.dart` | 329 | `catch (_) { ... fallback }` — `_sendMessage` 内层吞异常 | 异步 API 异常被吞，静默使用同步回退 |
| E03 | `chat_screen.dart` | 1043 | `catch (_) { return Uint8List(0); }` — `_dataUriBytes` | base64 解码错误被吞，返回空数据 |

**验收标准:**
- [ ] 所有 `catch (_)` 替换为 `catch (e) { debugPrint('Tag: $e'); }` 或更具体的异常处理
- [ ] E02 改为按异常类型分流（`on TimeoutException` 走 fallback，其余 rethrow）

#### R0.2 — 消除 `Future.wait` + `as` 不安全转型 (1 处)

| # | 文件 | 行 | 问题 | 风险 |
|---|------|-----|------|------|
| E04 | `chat_screen.dart` | 239-243 | `results[0] as List<Message>` 等 5 个 unsafecast | Future 顺序变化即 runtime crash |

**验收标准:**
- [ ] `Future.wait` 拆分为 5 个独立 `await` 调用：`final msgs = await api.getMessages(...);`
- [ ] 或使用 Dart 3 records 返回类型安全的结果

**实现要点:**
```dart
// 推荐方案：独立 await
final msgs = await widget.api.getMessages(widget.session.id);
final agents = await widget.api.getAgents();
final providers = await widget.api.getProviders();
final commands = await widget.api.getCommands();
final configData = await widget.api.getConfigProviders();
```

#### R0.3 — 消除 JSON 不安全转型 (全项目)

| # | 文件 | 行 | 问题 | 风险 |
|---|------|-----|------|------|
| E05 | `chat_screen.dart` | 122-126 | `props['partID'] as String?` — SSE 事件字段 | 服务端字段改名即 crash |
| E06 | `chat_screen.dart` | 134 | `... as String? ?? ''` — Delta 输出拼接 | 类型不对返回空字符串 |
| E07 | `event_service.dart` | 112-113 | `payload['type'] as String?` — SSE 事件类型 | 同上 |
| E08 | `opencode_api.dart` | 多处 | `e['info'] as Map<String, dynamic>? ?? {}` | 存在遗漏 |

**验收标准:**
- [ ] 所有 SSE 事件解析处遵循 `as Type? ?? default` 模式
- [ ] `event_service.dart` 的 `_emitEvent` 添加 `try-catch` 兜底（已有 debugPrint）

#### R0.4 — 嵌套 try-catch 异常遮蔽修复

| # | 文件 | 行 | 问题 | 风险 |
|---|------|-----|------|------|
| E09 | `chat_screen.dart` | 325-331 | 内层 `catch (_)` 遮蔽异步 API 调用异常 | 异步版本 `sendMessageAsync` 永远无法被测试正确的错误分支 |

**验收标准:**
- [ ] 内层 catch 至少 `debugPrint` 原始异常
- [ ] 只对网络异常 (`SocketException`, `TimeoutException`) 做 fallback，不对 `TypeError` / `ArgumentError` fallback

---

### Phase 1: 结构拆解（P0 — 维护性瓶颈）

#### R1.1 — 拆分 `chat_screen.dart` (2075 行)

文件包含 10 个类/组件，严重违反单一职责原则。拆分为以下文件：

| # | 新文件 | 包含类 | 预估行数 |
|---|--------|--------|----------|
| F01 | `chat_screen.dart` | `ChatScreen` + `_ChatScreenState` | ~400 |
| F02 | `message_bubble.dart` | `_MessageBubble` | ~120 |
| F03 | `tool_part_widget.dart` | `_ToolPartWidget` + `_ToolPartWidgetState` + `_CodePreview` | ~300 |
| F04 | `model_picker_sheet.dart` | `_ModelPickerSheet` + `_ModelPickerSheetState` | ~150 |
| F05 | `code_block_builder.dart` | `_CodeBlockBuilder` | ~80 |
| F06 | `chat_widgets.dart` | `_ReasoningBlock`, `_FilePartsRow`, `_Chip`, `copyToClipboard` | ~200 |

**验收标准:**
- [ ] 每个新文件 ≤ 400 行
- [ ] 每个类 ≤ 200 行
- [ ] 导入路径正确，无编译错误
- [ ] `flutter analyze` 零错误

#### R1.2 — `_ChatScreenState` 职责拆分 (30+ 成员变量)

当前 `_ChatScreenState` 同时管理 7 个不相关的状态域：

| 领域 | 成员 | 建议的提取目标 |
|------|------|----------------|
| 消息管理 | `_messages`, `_streamingDeltas`, `_streamingToolStates` | 保留在 `_ChatScreenState` |
| Agent/Model | `_selectedAgent`, `_selectedModel`, `_agents`, `_providers` | 提取为 `_AgentModelManager` mixin 或独立类 |
| 输入历史 | `_inputHistory`, `_historyIndex` | 提取为 `InputHistoryManager` |
| 命令 | `_commands`, `_filteredCommands`, `_showCommands` | 提取为 `CommandManager` |
| 附件 | `_attachments` | 提取为 `AttachmentManager` |
| 事件 SSE | `_eventService`, `_eventSub` | 提取为 `EventConnectionManager` |
| 待办 | `_todos` | 提取为 `TodoManager` |
| Shell 模式 | `_shellMode` | 提取为 `ShellModeManager` |
| 发送状态 | `_sending` | 替换为枚举 `_SendState` |

**验收标准:**
- [ ] `_ChatScreenState` 成员变量 ≤ 12 个
- [ ] 每个 Manager 类 ≤ 50 行
- [ ] 重构后功能完全等价

---

### Phase 2: 方法与方法长度（P1 — 可读性障碍）

项目规范要求：**单个方法 ≤ 30 行，build 方法 ≤ 30 行。** 以下严重超标：

#### R2.1 — Build 方法拆分

| # | 方法 | 当前行数 | 目标行数 | 拆分策略 |
|---|------|----------|----------|----------|
| M01 | `_ChatScreenState.build` | ~60 | ≤30 | 提取 `_buildAppBar()`, `_buildBody()`, `_buildMessageList()` |
| M02 | `_MessageBubble.build` | ~45 | ≤30 | 提取 `_buildReasoning()`, `_buildBubble()`, `_buildFileRow()` |
| M03 | `_ToolPartWidgetState.build` | ~60 | ≤30 | 提取 `_buildHeader()`, `_buildBody()`, `_buildInput()`（_buildInput 已存在） |
| M04 | `_ModelPickerSheetState.build` | ~80 | ≤30 | 提取 `_buildSearchBar()`, `_buildModelList()`, `_buildHeader()` |

#### R2.2 — 业务方法拆分

| # | 方法 | 当前行数 | 目标行数 | 拆分策略 |
|---|------|----------|----------|----------|
| M05 | `_load` | ~40 | ≤30 | 提取数据加载 + 默认值解析 + Agent auto-select 为子方法 |
| M06 | `_sendMessage` | ~35 | ≤30 | 提取 `_sendShell()`, `_sendCommand()`, `_sendText()` |
| M07 | `_showMessageDetail` | ~55 | ≤30 | 提取 `_buildPartSummary()` + `_buildInfoRows()` |
| M08 | `_applyCode` | ~75 | ≤30 | 提取 `_buildCodePreview()`, `_buildPathInput()`, `_handleWrite()` |
| M09 | `_handleDelta` | ~30 | ≤20 | 使用 Map-based dispatch 替代 else-if 链 |

#### R2.3 — `_load` 提取常量默认值

```dart
// 当前：魔法字符串
autoModel ??= defaults['build'];

// 目标：命名常量
static const _kDefaultAgentName = 'build';
static const _kContextWindowSize = 128000;  // tokens
```

**验收标准:**
- [ ] build 方法全部 ≤ 30 行
- [ ] 业务方法全部 ≤ 30 行
- [ ] 魔数全部提取为 `static const` 命名常量

---

### Phase 3: 重复代码治理（P1 — 持续膨胀之源）

#### R3.1 — 共享 InputDecoration 提取

`chat_screen.dart` 中 **5+ 处** 重复的 `InputDecoration`：

```dart
// 当前重复模式
const InputDecoration(
  hintText: '...',
  hintStyle: TextStyle(color: AppColors.textTertiary),
  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.border)),
  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.borderFocused)),
)

// 目标：提取到 theme.dart 或独立文件
class AppInputDecoration {
  static InputDecoration defaultInput({
    required String hintText,
    String? labelText,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) => InputDecoration(
    hintText: hintText,
    hintStyle: TextStyle(color: AppColors.textTertiary),
    labelText: labelText,
    labelStyle: TextStyle(color: AppColors.textSecondary),
    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.border)),
    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.borderFocused)),
    prefixIcon: prefixIcon,
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: AppColors.background,
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
  );
}
```

**验收标准:**
- [ ] 所有 `TextField` 使用 `AppInputDecoration`（或自定义变体）
- [ ] 零个裸 `InputDecoration(...)` 在 widget 中

#### R3.2 — 底部 Sheet 模式提取

`showModalBottomSheet` + `Radius.circular(16)` + `SafeArea` + `Column` + `Divider` + `ListTile` 模式出现 4 次。

提取为 `AppBottomSheet.showOptionSheet(context, title, items)` 通用方法。

**验收标准:**
- [ ] 所有底部选择 sheet 使用 `AppBottomSheet` 方法
- [ ] `Radius.circular(16)` 替换为 `AppColors.kDefaultBorderRadius`

#### R3.3 — 常量提取到 `theme.dart`

| # | 当前值 | 建议常量名 | 出现次数 |
|---|--------|-----------|----------|
| C01 | `Radius.circular(16)` | `AppColors.kDefaultBorderRadius` | 11+ 文件 |
| C02 | `BorderRadius.circular(10)` | `AppColors.kCardBorderRadius` | 多处 |
| C03 | `BorderRadius.circular(8)` | `AppColors.kSmallBorderRadius` | 多处 |
| C04 | `.withValues(alpha: 0.1)` | `AppTint.soft(Color c)` | 10+ 次 |
| C05 | `800` ms delay | `_kPollInterval = Duration(milliseconds: 800)` | 1 |
| C06 | `max 3` diagnostics | `_kMaxDiagnosticCount = 3` | 1 |
| C07 | `rand.nextInt(99999)` | `_kRandomIdMax = 99999` | models.dart:25 |

#### R3.4 — `_mimeFromExt` switch → const map

```dart
// 当前 ~30 行 switch
String _mimeFromExt(String ext) { ... }

// 目标
static const _mimeMap = <String, String>{
  'png': 'image/png',
  'jpg': 'image/jpeg',
  'jpeg': 'image/jpeg',
  // ...17 个条目
};
String _mimeFromExt(String ext) => _mimeMap[ext.toLowerCase()] ?? 'application/octet-stream';
```

---

### Phase 4: 安全与正确性（P1 — 潜在线上问题）

#### R4.1 — Shell 注入修复 (`_applyCode`, chat_screen.dart:561)

```dart
// 当前：危险 — shell 注入
'cat > "$path" << \'EOF\'\n$code\nEOF'

// 方案 A：base64 编码
'echo "$b64code" | base64 -d > "$path"'

// 方案 B：使用 API 的 writeFile 端点（优先推荐，如果存在）
await widget.api.runShell(widget.session.id,
  command: 'base64 -d > "$path"',
  agent: _selectedAgent,
  model: _selectedModel,
  input: b64code,
);
```

**验收标准:**
- [ ] `_applyCode` 不再包含 `cat >` shell 重定向
- [ ] 使用 base64 编码或 API 直接写入

#### R4.2 — `_sending` bool → `_SendingState` enum

```dart
// 当前
bool _sending = false;  // 无法区分"发送中"还是"shell 执行中"

// 目标
enum _SendingState { none, sending, shellCommand, aborting }
_SendingState _sendingState = _SendingState.none;
```

**验收标准:**
- [ ] 所有 `if (_sending)` 检查替换为 `if (_sendingState != _SendingState.none)`
- [ ] `_buildInputBar` 根据 `_sendingState` 显示不同的 UI

#### R4.3 — `_doRevert` / `_doUnrevert` / `_doFork` 缺少 mounted 检查

| # | 方法 | 行 | 问题 |
|---|------|-----|------|
| S01 | `_doRevert` | ~768 | `await` 后 `setState` 前未检查 `mounted` |
| S02 | `_doUnrevert` | ~777 | `await` 后 `setState` 前未检查 `mounted` |
| S03 | `_doFork` | ~870 | `Navigator.pushReplacement` 前检查了 `mounted` ✅ 已修复 |
| S04 | `_applyCode` | ~565 | `onPressed` async 中 `setState` 前无 `mounted` |

**验收标准:**
- [ ] 所有 `async` 方法中 `await` 后的 `setState` / `ScaffoldMessenger` 前都检查 `mounted`

---

### Phase 5: 可读性与命名（P2 — 长期可维护性）

#### R5.1 — 中文 UI 字符串提取 (30+ 处)

所有用户可见文本提取到 `lib/strings.dart`：

```dart
// lib/strings.dart
class S {
  static const selectAgent = '选择 Agent';
  static const selectModel = '选择模型';
  static const messageActions = '消息操作';
  static const copyContent = '复制内容';
  static const sendFailed = '发送失败';
  static const abort = '停止';
  static const enterMessage = '输入消息... (/ 查看命令)';
  static const enterShellCommand = '输入 shell 命令...';
  // ...30+ 条
}
```

**验收标准:**
- [ ] 所有 UI 字符串引用 `S.xxx` 而非直接写中文
- [ ] 零个裸中文字符串在 widget 代码中

#### R5.2 — 命名规范化

| # | 当前 | 目标 | 原因 | 文件 |
|---|------|------|------|------|
| N01 | `_Chip` | `_AgentLabelChip` | 避免与内置 `Chip` 混淆 | chat_screen.dart:2136 |
| N02 | `fullID` (if exists) | `fullId` | Dart 惯例 — `Id` 不是缩写 | models.dart:304（如果有） |
| N03 | `copyToClipboard` (顶层与私有方法同名) | 私有改为 `_copyMsgToClipboard` | 避免混乱 | chat_screen.dart:762 vs 2157 |
| N04 | `results[0]..[4]` 变量 | `msgs`, `agents`, `providers`... | 已有 ✅ 命名良好 | chat_screen.dart |

**验收标准:**
- [ ] 无 `_` 前缀命名与公共库冲突
- [ ] 无两个同名函数（不同作用域）

#### R5.3 — 提取 SSE 事件类型类

```dart
// 目标：为 SSE 事件 payload 定义类型
class DeltaEvent {
  final String partID;
  final String field;
  final String? delta;

  factory DeltaEvent.from(Map<String, dynamic> data) {
    final props = /* ... */;
    return DeltaEvent(
      partID: props['partID'] as String? ?? '',
      field: props['field'] as String? ?? '',
      delta: props['delta'] as String?,
    );
  }
}
```

**验收标准:**
- [ ] `_handleDelta` 接收 `DeltaEvent` 而非 `Map<String, dynamic>`
- [ ] `_handlePermission` 接收 `PermissionEvent`
- [ ] `_handleQuestion` 接收 `QuestionEvent`
- [ ] 每处解析逻辑只在 factory 中出现一次

---

### Phase 6: 架构改进（P2 — 长期演进）

#### R6.1 — `_handleDelta` else-if → Map dispatch

```dart
// 当前 20+ 行 else-if
// 目标
static const _deltaHandlers = <String, void Function(_ChatScreenState, String, String)>{
  'text': _handleTextDelta,
  'state.status': _handleStatusDelta,
  'state.output': _handleOutputDelta,
  'state.error': _handleErrorDelta,
  'state.title': _handleTitleDelta,
};

void _handleDelta(Map<String, dynamic> data) {
  final props = _extractProps(data);
  if (props == null) return;
  final handler = _deltaHandlers[props.field];
  if (handler != null) handler(this, props.partID, props.delta ?? '');
}
```

#### R6.2 — SnackBar 模式提取

```dart
// 当前：8+ 次重复
ScaffoldMessenger.of(context).showSnackBar(SnackBar(
  content: Text('...'),
  backgroundColor: AppColors.surface,
));

// 目标
void _showSnack(String message) {
  if (!mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(message, style: TextStyle(color: AppColors.textPrimary)),
    backgroundColor: AppColors.surface,
    duration: Duration(seconds: 2),
  ));
}
```

---

## 3. 总体优先级矩阵

| 优先级 | 定义 | 数量 | 总影响 |
|--------|------|------|--------|
| **P0** | 可能导致运行时 crash / 数据丢失 | **7** 个 | 用户可见白屏、无响应 |
| **P1** | 严重违反 Clean Code / 安全风险 | **15** 个 | 维护成本高、潜在安全漏洞 |
| **P2** | 可读性 / 可维护性改进 | **25+** 个 | 长期代码健康度 |
| **总计** | | **48+** 个 | |

### Phase 优先级

| Phase | 内容 | 优先级 | 预估工作量 | 风险评估 |
|-------|------|--------|-----------|----------|
| Phase 0 | 安全底线修复 | **P0** | 0.5 天 | 不修则可能线上 crash |
| Phase 1 | 结构拆解 | **P0** | 1 天 | 2075 行单文件是最严重的维护瓶颈 |
| Phase 2 | 方法长度 | **P1** | 1 天 | 可读性障碍，影响所有后续开发 |
| Phase 3 | 重复代码 | **P1** | 0.5 天 | 持续产生不一致的根源 |
| Phase 4 | 安全正确性 | **P1** | 0.5 天 | 潜在 shell 注入风险 |
| Phase 5 | 可读性命名 | **P2** | 0.5 天 | 长期可维护性 |
| Phase 6 | 架构改进 | **P2** | 0.5 天 | 长期演进 |
| **总计** | | | **4.5 天** | |

---

## 4. 文件变更清单

| 文件 | 操作 | 说明 |
|------|------|------|
| `lib/screens/native/chat_screen.dart` | **拆分** | 拆为 6 个文件，自身保留 ~400 行 |
| `lib/screens/native/message_bubble.dart` | **新建** | 从 chat_screen.dart 提取 |
| `lib/screens/native/tool_part_widget.dart` | **新建** | 从 chat_screen.dart 提取 |
| `lib/screens/native/model_picker_sheet.dart` | **新建** | 从 chat_screen.dart 提取 |
| `lib/screens/native/code_block_builder.dart` | **新建** | 从 chat_screen.dart 提取 |
| `lib/screens/native/chat_widgets.dart` | **新建** | 从 chat_screen.dart 提取 |
| `lib/theme.dart` | **修改** | 添加常量、`AppInputDecoration`、`AppBottomSheet` |
| `lib/strings.dart` | **新建** | 集中管理所有 UI 字符串 |
| `lib/services/event_service.dart` | **修改** | 添加事件类型类（`DeltaEvent`, `PermissionEvent` 等） |
| `lib/models.dart` | **修改** | 提取 `_generateId` 魔数 |

---

## 5. 验收标准

### 5.1 功能等价性

- [ ] **零功能变化**: 所有 UI 交互、API 行为、状态流转与重构前完全一致
- [ ] 所有 `git diff` 不涉及 UI 文字、颜色、布局数值的变化

### 5.2 代码质量门禁

- [ ] `flutter analyze` 零 error、零 warning
- [ ] 无 `catch (_)` 静默异常
- [ ] 无 `results[i] as Type` 转型
- [ ] 无 raw JSON `as Type`（使用 `as Type? ?? default`）
- [ ] 无方法超过 30 行（最多 ±5 行容差，需注释说明）
- [ ] 魔数全部提取为 `static const`
- [ ] 中文 UI 字符串全部引用 `S.xxx`

### 5.3 构建完整性

- [ ] `flutter build apk --debug` 通过
- [ ] `flutter build ios --no-codesign` 通过（macOS）

---

## 6. 风险与缓解

| 风险 | 概率 | 影响 | 缓解措施 |
|------|------|------|----------|
| 拆分文件时漏 import | 中 | 高 | git diff + flutter analyze 双重验证 |
| 提取 shared widget 时行为偏差 | 低 | 中 | 提取后对比截图 |
| 成员变量提取到 Manager 后状态同步遗漏 | 中 | 中 | 每次提取后运行完整会话流程 |
| Shell 注入修复引入新 bug | 低 | 中 | 先在测试分支修复，用已有截图验证 |

---

## 7. 参考

- [Round 1 Review 报告](../archive/2026-06/06-13-code-review/research/clean-code-review.md)
- [Round 2 Review 报告](../archive/2026-06/06-13-code-review-r2/research/re-review-report.md)
- [Round 3 Review 报告](../archive/2026-06/06-13-code-review-r2/research/sub-agent-review-report.md)
- [前端质量规范](../../spec/frontend/quality-guidelines.md)
- [类型安全规范](../../spec/frontend/type-safety.md)
- [组件规范](../../spec/frontend/component-guidelines.md)
