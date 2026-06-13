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

## Testing

- No tests exist yet
- Future: `flutter test` for widget tests

## Accessibility

- Use `Tooltip` on icon buttons (`tooltip:` parameter)
- Semantic labels not yet added
- Dark theme only — ensure sufficient contrast ratios
