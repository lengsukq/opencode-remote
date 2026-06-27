# Frontend Directory Structure

```
lib/
├── main.dart                       # App entry, theme, routing
├── models.dart                     # Shared data models
├── theme.dart                      # Dark theme, AppColors, constants
├── strings.dart                    # (future) centralized UI strings
├── screens/
│   ├── native/                     # Native Flutter screens
│   │   ├── chat_screen.dart        # Main chat screen + _ChatScreenState
│   │   ├── dashboard_screen.dart   # Server dashboard
│   │   ├── session_list_screen.dart
│   │   ├── project_screen.dart
│   │   ├── file_browser_screen.dart
│   │   ├── config_screen.dart
│   │   ├── terminal_screen.dart
│   │   ├── message_bubble.dart     # Extracted: single message bubble
│   │   ├── tool_part_widget.dart   # Extracted: tool execution display
│   │   └── model_picker_sheet.dart # Extracted: model selection bottom sheet
│   ├── launcher_screen.dart
│   ├── webview_screen.dart
│   ├── onboarding_screen.dart
│   └── settings_sheet.dart
├── services/
│   ├── opencode_api.dart           # HTTP API client
│   ├── storage_service.dart        # SharedPreferences CRUD
│   └── event_service.dart          # SSE event streaming
├── utils/
│   └── time_format.dart            # Shared time formatting helpers
└── widgets/                        # Shared/reusable widgets
    ├── agent_bar.dart              # Agent bar with model/token display
    ├── agent_chip.dart             # Small label chip widget
    ├── attachment_preview.dart     # Attachment thumbnail strip
    ├── chat_input_bar.dart         # Chat text input with send/stop
    ├── code_block_builder.dart     # Syntax-highlighted code block
    ├── command_suggestions.dart    # Slash-command suggestions list
    ├── diff_view.dart              # Git-style diff display
    ├── file_parts_row.dart         # File attachment row in messages
    ├── main_scaffold.dart          # Bottom tab navigator
    ├── reasoning_block.dart        # Collapsible AI reasoning display
    ├── revert_banner.dart          # Message-reverted undo banner
    └── todo_banner.dart            # Todo completion progress bar
```

## Clean Code Rules

### File Size — One File, One Purpose
- **Hard limit**: Most files must be **≤ 500 lines**
- **Rare exceptions**: Data model files (`models.dart`) or generated code may exceed this, but only with clear justification in a comment at the top
- A file that exceeds 500 lines MUST be split:
  - Extract UI widgets into `lib/widgets/` or screen subdirectory
  - Extract business logic into manager classes or data classes
  - Extract unrelated types into their own files

### One Concept Per File
A file should serve **exactly one purpose**. Signs of concept mixing:
- File contains **3+ widget classes** → split into separate files
- File contains both **data models and UI widgets** → split
- File contains **State class + unrelated helper classes** → extract helpers
- File contains code for **two different screens** → split by screen

### Widget Extraction Threshold
- A private widget class (`_Foo`) should remain in the screen file if ≤ 50 lines
- If a private widget exceeds 50 lines, extract it to its own file as a **public** class
- If a pattern appears in **2+ screens**, extract it to `lib/widgets/` as a shared widget

### State Class Health
- `State` class should have ≤ 20 member variables
- If exceeding 20 members, split into domain-specific manager classes
- Manager classes are simple helper classes in the same directory, not providers

### Example: When to extract

```dart
// lib/screens/native/chat_screen.dart — BAD: 1240 lines, 7 concepts in 1 file
// Concepts mixed: chat logic, input bar, agent bar, attachments, todos, revert, commands
// → Split into:
//   lib/screens/native/chat_screen.dart          (≤500 lines, core chat logic only)
//   lib/widgets/chat_input_bar.dart               (1 file, 1 purpose: input bar)
//   lib/widgets/agent_bar.dart                    (1 file, 1 purpose: agent/model bar)
//   lib/widgets/attachment_preview.dart           (1 file, 1 purpose: attachment strip)
//   lib/widgets/command_suggestions.dart           (1 file, 1 purpose: command list)
//   lib/widgets/todo_banner.dart                  (1 file, 1 purpose: todo progress)
//   lib/widgets/revert_banner.dart                (1 file, 1 purpose: revert undo)
```

## Platform Separation

- `screens/` = web-compatible screens (WebView-based)
- `screens/native/` = native-only screens (full Flutter)
- Shared widgets go in `widgets/` regardless of platform
