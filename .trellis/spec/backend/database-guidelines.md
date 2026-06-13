# Database / Local Storage Guidelines

## Storage Backend

- **SharedPreferences** via `shared_preferences: ^2.3.4`
- All server entries serialized as a single JSON string under key `"servers"`
- Last selected server ID stored separately under key `"lastSelectedId"`

## Read Pattern

```dart
static Future<List<ServerEntry>> loadServers() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(_keyServers);
  if (raw == null) return [];
  // parse + sort by lastUsed descending
}
```

## Write Pattern

```dart
static Future<void> saveServers(List<ServerEntry> servers) async {
  final prefs = await SharedPreferences.getInstance();
  final raw = jsonEncode(servers.map((e) => e.toJson()).toList());
  await prefs.setString(_keyServers, raw);
}
```

## Conventions

- Always re-read from SharedPreferences before mutation (avoid stale state)
- Sort by `lastUsed` descending after loading
- `addOrUpdate` — find by `id`, replace or append
- For simple key-value (last selected id), use `setString`/`getString` directly
