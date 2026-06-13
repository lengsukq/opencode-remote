# Quality Guidelines — Frontend

## Linting

- Uses `package:flutter_lints/flutter.yaml` (standard Flutter lint set)
- No custom rules disabled or enabled yet
- Run: `flutter analyze`

## Naming Conventions

| Element | Convention | Example |
|---------|-----------|---------|
| Files | snake_case | `launcher_screen.dart` |
| Classes | PascalCase | `ServerEntry`, `LauncherScreen` |
| Private members | `_` prefix | `_servers`, `_reload()` |
| Constants | lowerCamelCase | `_keyServers` |
| Booleans | prefix with `is`/`has`/`show` | `isLoading`, `hasLaunched`, `showCommands` |

## Function/Method Length

- Single method should not exceed **30 lines** (excluding blank lines and braces)
- Widget `build()` methods should not exceed **30 lines** — break into extracted widgets or helper methods
- Dialog/sheet builder closures should be extracted into named methods or separate widgets

## Build Method Decomposition

```dart
// BAD: 50+ line build method
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Row(children: [Text('Title'), ... 20 more lines ...]),
      actions: [ ... 15 more lines ... ],
    ),
    body: Column(children: [ ... 15 more lines ... ]),
  );
}

// GOOD: extracted sub-widgets
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: _buildAppBar(),
    body: _buildBody(),
  );
}
```

## Duplicate Code

- Extract shared logic into **one place** — do not copy-paste functions across files
- Common patterns seen in this project that must NOT be duplicated:
  - `_formatTime()` → extract to `lib/utils/time_format.dart`
  - Server switching bottom sheet → one shared widget
  - Server edit dialog → one shared `ServerEditDialog` widget
  - Mode option card (onboarding vs settings) → one shared widget
  - `TextField` decoration pattern → shared `AppTextField` or `AppInputDecoration`
- If you see the same pattern 2+ times, extract it

## Magic Constants

- No raw numbers in widget code (border radii, padding, durations, shadow offsets)
- Define in `lib/theme.dart`:
  - `kDefaultBorderRadius` for `Radius.circular(16)`
  - `kDefaultPadding` for common spacing
  - `kAnimationDuration` for scroll/tween durations
- No raw hex colors outside `AppColors` class

## UI Strings

- All Chinese/English UI strings must be defined in a centralized location
- Do NOT hardcode UI strings inline in widget code
- Future: use `lib/strings.dart` or Flutter `MaterialLocalizations`

## Error Handling

- **Never use empty catch blocks** (`catch (_) {}`) — always log or propagate
- JSON parsing errors should have fallback defaults, never crash
- `Future.wait` results must be handled type-safely (use records or individual variables, not unchecked `as` casts)
- Inconsistent return patterns (some methods throw, some return bool, some ignore) are forbidden — pick one pattern per layer

## Code Review Checklist

- [ ] No `as` cast without fallback on JSON-decoded values
- [ ] No empty `catch` blocks
- [ ] No function > 30 lines
- [ ] No hardcoded magic numbers/colors outside theme
- [ ] No duplicate `_formatTime` or similar helper functions
- [ ] All UI strings centralized (or extracted to constants)
- [ ] `flutter analyze` passes with zero errors

## Testing

- No tests exist yet
- Future: `flutter test` for widget tests

## Accessibility

- Use `Tooltip` on icon buttons (`tooltip:` parameter)
- Semantic labels not yet added
- Ensure sufficient contrast ratios
