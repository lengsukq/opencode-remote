# Component (Widget) Guidelines

## Patterns Used

### Extracted Widget Files
Once a screen file exceeds 700 lines, extract UI components into separate widget files:
- `ChatInputBar`, `AgentBar`, `CommandSuggestions`, `AttachmentPreview` in `lib/widgets/`
- Screen-specific extracted widgets stay in `lib/screens/native/` (e.g., `MessageBubble`, `ToolPartWidget`)
- Extracted widgets are **public classes** that receive all dependencies via constructor parameters

### Private Sub-Widgets (Inline)
Use inline private classes for small widgets (≤ 50 lines) used by only one screen:
- `_ServerCard` in `launcher_screen.dart`
- `_EditDialog` in `webview_screen.dart`

### Extraction Threshold
| Condition | Action |
|-----------|--------|
| Private widget ≤ 50 lines, used by 1 screen | Keep inline |
| Private widget > 50 lines | Extract to own file |
| Pattern appears in 2+ screens | Extract to `lib/widgets/` |

### Clean Code Widget Pattern
```dart
// GOOD: extracted widget with explicit constructor params
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

## Theming

- Dark theme only, GitHub-dark inspired palette:
  - Background: `0xFF0D1117`
  - Surface/Card: `0xFF161B22`
  - Border: `0xFF30363D`
  - Accent/Primary: `0xFF6366F1`
  - Text primary: `0xFFE6EDF3`
  - Text secondary: `Colors.grey[500]`
- Opacity via `.withValues(alpha: 0.15)` syntax
- Use `ColorScheme.dark(...)` as base theme

## Card Pattern

```dart
Card(
  color: const Color(0xFF161B22),
  margin: const EdgeInsets.symmetric(vertical: 4),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
    side: const BorderSide(color: Color(0xFF30363D)),
  ),
  child: InkWell(
    borderRadius: BorderRadius.circular(12),
    onTap: ...,
    child: Padding(...),
  ),
)
```
