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
- Async methods that exceed 30 lines should be split: data fetching vs. state assignment

### Method Splitting Pattern

```dart
// BAD: 40-line method mixing fetch + state
Future<void> _load() async {
  setState(() => _loading = true);
  try {
    final msgs = await api.getMessages(id);    // 5 lines
    final agents = await api.getAgents();       // ...mixed...
    // ... 25 more lines of parsing + setState ...
  } catch (e) { ... }
}

// GOOD: separated concerns
Future<void> _load() async {                    // 10 lines
  setState(() => _loading = true);
  try {
    final data = await _loadAllData();
    if (mounted) _applyLoadedData(data);
  } catch (e) { setState(() { _error = ...; }); }
}

Future<_LoadData> _loadAllData() async { ... }  // 10 lines - pure fetch
void _applyLoadedData(_LoadData data) { ... }   // 10 lines - pure state assign
```

### State Class Member Limit
- A `State<X>` class should have **≤ 20 member variables**
- Categories that count toward the limit:
  - Data lists/maps (e.g., `_messages`, `_agents`)
  - Controllers (e.g., `_inputCtrl`, `_scrollCtrl`)
  - Flags (e.g., `_loading`, `_sending`, `_shellMode`)
  - State objects (e.g., `_eventService`, `_todos`)
- If exceeded, extract related members into domain-specific groups:
  ```dart
  // Instead of 30 fields in state, group into manager helpers
  class _AttachmentManager { List<_Attachment> attachments; ... }
  class _InputHistoryManager { List<String> history; int index; ... }
  ```

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

- **Never use empty catch blocks** (`catch (_) {}`) — always add `debugPrint` or propagate
- JSON parsing: use safe helpers (`_safeList`, `_safeMap`) instead of bare `as Type` casts
- `Future.wait` results must use individual typed `await` calls, never `results[i] as Type`
- API layer error handling must be consistent: either throw `OpenCodeApiException` (data methods) or return `bool` via `_checkBool` (command methods), never mix silently
- Example:
  ```dart
  // Services layer — throw on error
  void _check(http.Response res) {
    if (res.statusCode >= 400) throw ApiException(res.statusCode, res.body);
  }

  // Command methods — log on error, return bool
  bool _checkBool(http.Response res) {
    if (res.statusCode >= 400) { debugPrint('...'); return false; }
    return true;
  }
  ```

## Safe JSON Parsing

- Use `_safeList<T>(json, T.fromJson)` for list responses instead of `jsonDecode(...) as List<dynamic>`
- Use `_safeMap(json)` for object responses instead of `jsonDecode(...) as Map<String, dynamic>`
- These helpers are defined in `OpenCodeApi` class; replicate pattern in other services

## Duplicate Code — Fixed Patterns

The following have been unified — do NOT re-introduce duplicates:

| Pattern | Canonical Location |
|---------|-------------------|
| Time formatting | `lib/utils/time_format.dart` (`formatRelativeTime`, `formatTime`) |
| JSON safe parsing | `OpenCodeApi._safeList` / `OpenCodeApi._safeMap` |
| Theme constants | `AppColors.kDefaultBorderRadius` etc. in `lib/theme.dart` |

## Code Review Checklist

- [ ] No `as` cast without fallback on JSON-decoded values
- [ ] No empty `catch` blocks
- [ ] No function > 30 lines
- [ ] No file exceeds **500 lines** (one purpose per file)
- [ ] No hardcoded magic numbers/colors outside theme
- [ ] No duplicate `_formatTime` or similar helper functions (use `lib/utils/time_format.dart`)
- [ ] All UI strings centralized (or extracted to constants)
- [ ] `flutter analyze` passes with zero errors

## Testing

- No tests exist yet
- Future: `flutter test` for widget tests

## Accessibility

- Use `Tooltip` on icon buttons (`tooltip:` parameter)
- Semantic labels not yet added
- Ensure sufficient contrast ratios
