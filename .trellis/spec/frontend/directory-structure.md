# Frontend Directory Structure

```
lib/
├── main.dart              # App entry, theme, routing
├── models.dart            # Shared data models (ServerEntry)
├── screens/               # Full-page widgets (one file per screen)
│   ├── launcher_screen.dart
│   └── webview_screen.dart
└── services/              # Business logic / data access
    └── storage_service.dart
```

## Rules

- Each screen gets one file in `screens/`
- Widgets used by only one screen stay in that screen's file (as private classes, prefixed with `_`)
- Shared models go in `models.dart`, not in screen files
- Services are stateless static classes in `services/`
- No `widgets/` directory yet — inline sub-widgets with `_` prefix
