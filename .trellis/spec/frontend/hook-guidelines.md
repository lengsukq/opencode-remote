# Custom Hook / State Patterns

Flutter does not use React-style hooks. StatefulWidget + `setState` is the current pattern.

## State Management Pattern

```dart
class _MyScreenState extends State<MyScreen> {
  List<ServerEntry> _servers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();       // load data async
  }

  Future<void> _reload() async {
    final servers = await StorageService.loadServers();
    setState(() {
      _servers = servers;
      _loading = false;
    });
  }

  // ...
}
```

## Rules

- Always check `mounted` before calling `setState` after `await`
- Private fields prefixed with underscore
- `initState` calls `super.initState()` first, then async load
- No external state management library (Provider, Riverpod, Bloc) — keep it simple

## Async Method Pattern

```dart
// BAD: no mounted check after await
Future<void> _doSomething() async {
  final result = await service.call();
  setState(() => _data = result);   // crash if disposed
}

// GOOD: guard with mounted
Future<void> _doSomething() async {
  final result = await service.call();
  if (mounted) setState(() => _data = result);
}

// GOOD: early return pattern
Future<void> _doSomething() async {
  final result = await service.call();
  if (!mounted) return;
  setState(() => _data = result);
}
```

## Disposal Pattern

Always cancel subscriptions and dispose controllers in `dispose()`:

```dart
@override
void dispose() {
  _inputCtrl.removeListener(_onInputChanged);  // remove listeners first
  _inputCtrl.dispose();                         // then dispose controllers
  _scrollCtrl.dispose();
  _eventSub?.cancel();                          // cancel stream subscriptions
  _eventService?.dispose();                     // dispose services
  super.dispose();
}
```

## Extract Data Class Pattern

When a `State` class has too many async data-loading methods, extract data holders:

```dart
// BAD: 40-line _load() mixing 5 API calls, parsing, and setState
Future<void> _load() async { ... }

// GOOD: separate data fetching from state assignment
Future<_LoadData> _loadAllData() async {
  return _LoadData(
    msgs: await api.getMessages(id),
    agents: await api.getAgents(),
    providers: await api.getProviders(),
    commands: await api.getCommands(),
    defaults: await api.getConfigProviders(),
  );
}

void _applyLoadedData(_LoadData data) {
  setState(() {
    _messages = data.msgs;
    _agents = data.agents;
    // ...
  });
}

class _LoadData {
  final List<Message> msgs;
  final List<Agent> agents;
  // ...
}
```
