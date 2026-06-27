# Quality Guidelines — Backend/Service Layer

## Code Review Standards

- Services are **static-only classes** — no mutable state in service classes
- Every `fromJson` must handle null for every field (use `as String?`, `as int?`)
- Sort entries by `lastUsed` descending after loading
- Wrap JSON parsing in try/catch with fallback

## Clean Code — Backend Specific

### SharedPreferences Access Pattern
- Call `SharedPreferences.getInstance()` **once per method**, not stored as a field
- Wrap all JSON decoding in `try/catch` with `debugPrint` and fallback
- Use `const` key constants (`_keyServers`, `_keyLastId`)

### API Client Pattern (`opencode_api.dart`)
- Consistent error handling: `_check()` throws, `_checkBool()` returns bool — never mix
- Use `_safeList<T>()` and `_safeMap()` for all JSON responses
- Base URL, auth credentials come from constructor, not global state

### Example: Static Service Pattern

```dart
class StorageService {
  static const _keyServers = 'servers';

  static Future<List<ServerEntry>> loadServers() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyServers);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>? ?? [];
      return list.map((e) => ServerEntry.fromJson(e as Map<String, dynamic>? ?? {}));
    } catch (e) {
      debugPrint('StorageService.loadServers: $e');
      return [];
    }
  }
}
```

## Testing

- No tests exist yet (early stage)
- Future: unit tests for `ServerEntry.fromJson`/`toJson` roundtrip
- Future: unit tests for `StorageService` CRUD operations

## Naming

- Private constants prefixed with underscore + `_key` (e.g., `_keyServers`)
- Method names mirror action: `loadServers`, `saveServers`, `addOrUpdate`, `delete`
