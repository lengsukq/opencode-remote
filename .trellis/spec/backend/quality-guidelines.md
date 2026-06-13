# Quality Guidelines — Backend/Service Layer

## Code Review Standards

- Services are **static-only classes** — no mutable state in service classes
- Every `fromJson` must handle null for every field (use `as String?`, `as int?`)
- Sort entries by `lastUsed` descending after loading
- Wrap JSON parsing in try/catch with fallback

## Testing

- No tests exist yet (early stage)
- Future: unit tests for `ServerEntry.fromJson`/`toJson` roundtrip
- Future: unit tests for `StorageService` CRUD operations

## Naming

- Private constants prefixed with underscore + `_key` (e.g., `_keyServers`)
- Method names mirror action: `loadServers`, `saveServers`, `addOrUpdate`, `delete`
