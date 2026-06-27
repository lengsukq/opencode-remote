# Component (Widget) Guidelines

## Shared Components Library

The project provides a library of shared UI components in `lib/widgets/`.  
**Always prefer using these over inline patterns** — they ensure consistent theming and reduce duplication.

| Component | File | Purpose |
|-----------|------|---------|
| `AppCard` | `lib/widgets/app_card.dart` | Reusable card container with standard surface/border/radius |
| `AppInputDecoration` | `lib/widgets/app_input_decoration.dart` | Static helpers for `InputDecoration` (standard & search variants) |
| `AppDialog` | `lib/widgets/app_dialog.dart` | Static helpers for dialogs (`showTextInput`, `showConfirm`, `showCustom`) |
| `AppBottomSheet` | `lib/widgets/app_bottom_sheet.dart` | Static helpers for modal bottom sheets (`show`, `showOptions`) |
| `BottomSheetOption` | `lib/widgets/app_bottom_sheet.dart` | Generic option type for `AppBottomSheet.showOptions` |
| `AppFullScreenDialog` | `lib/widgets/app_full_screen_dialog.dart` | Full-screen dialog with AppBar + close button |
| `AppLoadingIndicator` | `lib/widgets/app_states.dart` | Centered `CircularProgressIndicator` with app color |
| `AppEmptyState` | `lib/widgets/app_states.dart` | Centered empty state with icon + title + optional subtitle |
| `AppErrorState` | `lib/widgets/app_states.dart` | Centered error state with message + optional retry button |
| `AppBadge` | `lib/widgets/app_states.dart` | Small colored badge/label with optional icon |
| `AppServerEditDialog` | `lib/widgets/server_edit_dialog.dart` | Server editing form (name/host/port/username/password) |

---

### `AppCard`

A reusable card container. Replaces all inline `Container(BoxDecoration(...))` patterns.

```dart
import '../widgets/app_card.dart';

// Standard card
AppCard(child: Text('Content'))

// With shadow and larger radius
AppCard(
  borderRadius: 16,
  boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 4)],
  child: Text('Shadow card'),
)

// Tappable card with InkWell
AppCard(
  onTap: () => print('tapped'),
  child: Text('Tappable'),
)
```

---

### `AppInputDecoration`

Shared styling for `TextField` decorations. Prevents repeated `OutlineInputBorder` setups.

```dart
import '../widgets/app_input_decoration.dart';

// Standard text field
TextField(
  decoration: AppInputDecoration.standard(hintText: '输入名称'),
)

// With label and prefix icon
TextField(
  decoration: AppInputDecoration.standard(
    labelText: '用户名',
    prefixIcon: Icon(Icons.person),
  ),
)

// Search field (borderless, rounded)
TextField(
  decoration: AppInputDecoration.search(hintText: '搜索...'),
)
```

---

### `AppDialog`

Shared dialog wrappers. Replaces all inline `AlertDialog(backgroundColor: AppColors.surface, ...)` patterns.

```dart
import '../widgets/app_dialog.dart';

// Single text input dialog
final name = await AppDialog.showTextInput(
  context,
  title: '输入名称',
  hintText: '请输入...',
  confirmLabel: '保存',
);

// Confirmation dialog
final confirmed = await AppDialog.showConfirm(
  context,
  title: '确认删除？',
  message: '此操作不可恢复',
  confirmColor: AppColors.danger,
);

// Custom content dialog
await AppDialog.showCustom(
  context,
  title: '自定义',
  content: MyCustomWidget(),
);
```

---

### `AppBottomSheet`

Shared bottom sheet wrappers. Replaces inline `showModalBottomSheet(backgroundColor: AppColors.surface, shape: RoundedRectangleBorder(...))`.

```dart
import '../widgets/app_bottom_sheet.dart';

// Simple bottom sheet with any widget
final result = await AppBottomSheet.show(
  context: context,
  child: myWidget,
);

// Options list bottom sheet (title + tappable options)
final selected = await AppBottomSheet.showOptions<String>(
  context,
  title: '选择操作',
  options: [
    BottomSheetOption(icon: Icons.edit, label: '编辑', value: 'edit'),
    BottomSheetOption(icon: Icons.delete, label: '删除', value: 'delete', destructive: true),
  ],
);
```

---

### `AppFullScreenDialog`

Full-screen dialog with AppBar header + close button. Used for file content previews, image previews, etc.

```dart
import '../widgets/app_full_screen_dialog.dart';

// Content preview (scrollable)
await AppFullScreenDialog.show(
  context,
  title: '文件名',
  child: SingleChildScrollView(
    child: SelectableText(longContent),
  ),
);

// Image preview (non-expanded)
await AppFullScreenDialog.show(
  context,
  title: '图片名',
  expandContent: false,
  child: Image.memory(bytes),
);
```

---

### `AppStates`: Loading, Empty, Error, Badge

```dart
import '../widgets/app_states.dart';

// Loading state
if (_loading) return const AppLoadingIndicator();

// Empty state
if (_items.isEmpty) return const AppEmptyState(
  icon: Icons.inbox,
  title: '暂无数据',
  subtitle: '稍后再来看看',
);

// Error state with retry button
if (_error != null) return AppErrorState(
  message: _error!,
  onRetry: _reload,
);

// Status badge/label
AppBadge(
  label: '+5',
  color: AppColors.success,
  icon: Icons.add,
)
```

---

### `AppServerEditDialog`

Server editing form dialog with 5 fields: name, host, port, username, password.

```dart
import '../widgets/server_edit_dialog.dart';

// Add new server
final result = await showDialog<ServerEntry>(
  context: context,
  builder: (_) => const AppServerEditDialog(),
);

// Edit existing server
final result = await showDialog<ServerEntry>(
  context: context,
  builder: (_) => AppServerEditDialog(existing: existingEntry),
);
```

---

## Private Sub-Widgets (Inline)

Use inline private classes for small widgets (≤ 50 lines) used by only one screen:
- `_ServerCard` in `launcher_screen.dart`

### Extraction Threshold

| Condition | Action |
|-----------|--------|
| Private widget ≤ 50 lines, used by 1 screen | Keep inline |
| Private widget > 50 lines | Extract to own file |
| Pattern appears in 2+ screens | **Extract to `lib/widgets/`** as a shared component |
| It's a dialog/bottom sheet/card/input | **Prefer existing shared components** before inlining |

---

## Clean Code Widget Rules

### What NOT to put in extracted widgets
- ❌ API calls (`widget.api.xxx()`)
- ❌ `setState()` — use callbacks instead
- ❌ StatefulWidget unless absolutely needed for local UI state (e.g., `_expanded` toggle)
- ❌ Business logic (data transformation, validation)

### StatefulWidget vs StatelessWidget
- `StatefulWidget` for screens with mutable state
- `StatelessWidget` for pure-presentation widgets
- Never mix business logic into widget build methods
- Prefer `StatelessWidget` + callbacks over `StatefulWidget` whenever possible

### Extracted Widget Files
Once a screen file exceeds 700 lines, extract UI components into separate widget files:
- `ChatInputBar`, `AgentBar`, `CommandSuggestions`, `AttachmentPreview` in `lib/widgets/`
- Screen-specific extracted widgets stay in `lib/screens/native/` (e.g., `MessageBubble`, `ToolPartWidget`)
- Extracted widgets are **public classes** that receive all dependencies via constructor parameters

### Good Widget Pattern

```dart
class ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool shellMode;
  final bool sending;
  final VoidCallback onSend;

  const ChatInputBar({
    super.key,
    required this.controller,
    required this.shellMode,
    required this.sending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    // ... pure presentation logic only
  }
}
```

---

## Theming

### Color Palette
Use `AppColors` (light mode) and `DarkColors` (dark mode) from `lib/theme.dart`.

**Common colors:**

```dart
AppColors.background       // screen backgrounds
AppColors.surface          // card / container backgrounds
AppColors.surfaceAlt       // alternate surface (code blocks, etc.)
AppColors.border           // default border color
AppColors.borderFocused    // focused input border color
AppColors.primary          // accent / primary buttons
AppColors.textPrimary      // primary text
AppColors.textSecondary    // secondary text
AppColors.textTertiary     // hint / placeholder text
```

**Semantic colors:**

```dart
AppColors.success  // green — positive states
AppColors.danger   // red — destructive actions / errors
AppColors.warning  // orange — warnings
AppColors.info     // blue — informational
```

**Terminal colors (for `terminal_screen.dart` only):**

```dart
AppColors.terminalBg
AppColors.terminalText
AppColors.terminalInput
AppColors.terminalError
AppColors.terminalPrompt
AppColors.terminalIcon
AppColors.terminalInputBg
```

### Border Radius Constants

**Always use these constants instead of raw numeric values:**

| Constant | Value | Usage |
|----------|-------|-------|
| `AppColors.kDefaultBorderRadius` | 16 | Dialogs, bottom sheets |
| `AppColors.kCardBorderRadius` | 12 | Cards, containers |
| `AppColors.kSmallBorderRadius` | 8 | Search fields, small containers |
| `AppColors.kChipBorderRadius` | 6 | Badges, small labels |

```dart
// ✅ GOOD
BorderRadius.circular(AppColors.kCardBorderRadius)

// ❌ BAD
BorderRadius.circular(12)
```

### Padding Constants

| Constant | Value | Usage |
|----------|-------|-------|
| `AppColors.kPaddingScreen` | `EdgeInsets.all(16)` | Screen-level padding |
| `AppColors.kPaddingCard` | `EdgeInsets.all(14)` | Card content padding |
| `AppColors.kPaddingInput` | `EdgeInsets.symmetric(h:16, v:10)` | Input field padding |

```dart
// ✅ GOOD
padding: AppColors.kPaddingCard

// ❌ BAD
padding: const EdgeInsets.all(14)
```

### Opacity
Use `.withValues(alpha: 0.15)` syntax for color opacity:

```dart
// ✅ GOOD
color: AppColors.success.withValues(alpha: 0.1)

// ❌ BAD — avoid deprecated withOpacity
color: AppColors.success.withOpacity(0.1)
```

---

## UI Strings

All user-facing text strings are centralized in `lib/strings.dart` as static constants on the `S` class:

```dart
import '../strings.dart';

// ✅ GOOD
Text(S.cancel)

// ❌ BAD — hardcoded literal
Text('取消')
```

**When adding a new UI string:**
1. Add the constant to `lib/strings.dart` in the appropriate category section
2. Reference it via `S.xxx` (Dart will auto-complete)

---

## Pre-Development Checklist

Before writing any new UI code, ask:

- [ ] Is this a **card** → use `AppCard`
- [ ] Is this a **text field** → use `AppInputDecoration.standard()`
- [ ] Is this a **dialog** → use `AppDialog.showTextInput()` / `showConfirm()`
- [ ] Is this a **bottom sheet** → use `AppBottomSheet.show()` / `showOptions()`
- [ ] Is this a **loading/empty/error state** → use `AppLoadingIndicator` / `AppEmptyState` / `AppErrorState`
- [ ] Is this a **badge** → use `AppBadge`
- [ ] Is this a **full-screen content dialog** → use `AppFullScreenDialog`
- [ ] Is this a **server edit form** → use `AppServerEditDialog`
- [ ] Did I use `AppColors.xxx` constants instead of raw hex colors?
- [ ] Did I use `AppColors.kXxxBorderRadius` instead of raw `Radius.circular(N)`?
- [ ] Did I use `S.xxx` from `lib/strings.dart` instead of hardcoded text?
