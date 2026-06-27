# State Management

## Current Approach

- **`setState`** in `StatefulWidget` — no external library
- Loading state tracked with `bool _loading` flag
- Data fetched in `initState`, refreshed via dialog returns

## Data Flow

```
User Action → setState(_loading = true) → await Service.call() 
  → setState(_loading = false, data = result)
```

## Navigation State

- `Navigator.push(MaterialPageRoute)` for screen transitions
- `Navigator.pushAndRemoveUntil` for "back to root" (launcher)
- `PopScope` for back gesture handling
- `showModalBottomSheet` for server switching
- `showDialog` for add/edit forms

## Rules

- Never lift state beyond what's needed
- Services are stateless — all mutable state lives in widgets
- No global state, no InheritedWidget, no provider
- Future consideration: Riverpod if complexity grows

## State Class Health (Clean Code)

A well-structured `State` class:

| Metric | Healthy | Needs Refactor |
|--------|---------|----------------|
| Member variables | ≤ 20 | > 20 |
| Lines of code per file | ≤ 500 | > 500 |
| Methods > 30 lines | 0 | 1+ |

### When to Extract Managers

If a `State` class is near the limit, extract domain-specific groups:

```dart
// BAD: 23 fields in _ChatScreenState
class _ChatScreenState extends State<ChatScreen> {
  List<Message> _messages = [];
  List<Agent> _agents = [];
  List<Provider> _providers = [];
  bool _loading = true;
  String? _error;
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _sending = false;
  // ... 15 more fields ...
}

// GOOD: extract UI widgets remove 6 fields
// AgentBar widget owns: agentName, agentColor, selectedModel
// ChatInputBar widget owns: shellMode, sending, inputCtrl
// AttachmentPreview widget owns: attachments
// → State goes from 23 → 16 fields
```
