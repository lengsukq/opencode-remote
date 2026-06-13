# Component (Widget) Guidelines

## Patterns Used

### Private Sub-Widgets
Inline helper widgets defined as private classes in the same file:
- `_ServerCard` in `launcher_screen.dart`
- `_EditDialog` in `webview_screen.dart`
- `_inputDec` as a function returning `InputDecoration`

### StatefulWidget vs StatelessWidget
- `StatefulWidget` for screens with mutable state
- `StatelessWidget` for pure-presentation widgets
- Never mix business logic into widget build methods

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
