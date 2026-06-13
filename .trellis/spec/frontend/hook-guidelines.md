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
