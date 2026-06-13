# Type Safety

## Dart Conventions

- **Null safety** is enabled (Dart 3.x, SDK `^3.11.4`)
- Use `late` only when field is initialized after construction (e.g., `late WebViewController _controller`)
- Use nullable (`?`) for fields that may not be set (`ServerEntry? selected`)
- Avoid `dynamic` — only use when interfacing with JSON or dynamic data APIs

## JSON Deserialization

### Safe fromJson pattern

```dart
// GOOD: safe casts + defaults
factory ServerEntry.fromJson(Map<String, dynamic> json) => ServerEntry(
  id: json['id'] as String?,
  name: json['name'] as String? ?? '',
);

// BAD: unsafe cast can crash at runtime
factory BadExample.fromJson(Map<String, dynamic> json) => BadExample(
  data: json['data'] as Map<String, dynamic>,  // throws if null or wrong type
);
```

### Rules for JSON type casts

- Always use `as Type?` (nullable cast) followed by `?? default`
- Never use bare `as Type` on JSON-decoded values — API structure can change
- For `List` results from API, parse with fallback:
  ```dart
  final list = json['items'] as List<dynamic>? ?? [];
  return list.map((e) => Item.fromJson(e as Map<String, dynamic>)).toList();
  ```

### Future.wait results

`Future.wait` returns `List<dynamic>`. Do NOT use unchecked `as` casts:

```dart
// BAD: crashes if future order changes
final a = results[0] as TypeA;

// GOOD: use variables with fallback or records
final a = results[0];
if (a is TypeA) { ... } else { /* handle */ }

// OR use typed variables
final messages = await api.getMessages(id);
final agents = await api.getAgents();
// instead of Future.wait + as casts
```

## Null Safety Patterns

- After a null check (`if (x != null)`), Dart 3 promotes the variable — no `!` needed
  ```dart
  // BAD
  if (x != null) { use(x!); }
  // GOOD — promotion works
  if (x != null) { use(x); }
  ```
- Use `?.` and `??` instead of nested `if (x != null)` chains
- `!` (force unwrap) is only acceptable when the value was just assigned and is guaranteed non-null by program logic (e.g., after `late` initialization)

## Naming

- Use `Id` not `ID` in multi-word identifiers: `fullId`, `projectId`
- Boolean fields/methods: prefix with `is`/`has`/`can`/`should`
- Private helpers start with `_`, public API methods do not

## Generic Patterns

```dart
// copyWith: named parameters with optional types
ServerEntry copyWith({String? name, String? url}) => ...

// const constructor where possible
const ServerCard({super.key, ...});
```

## Rules

- JSON deserialization: always use `as String?`, `as int?` to handle null
- Provide defaults (`?? ''`) for optional string fields from JSON
- Use `const` constructor where possible for widgets
- Use `required` named parameters for widget constructors
- Never use `as` without a null-safe alternative on untrusted JSON data
