# Type Safety

## Dart Conventions

- **Null safety** is enabled (Dart 3.x, SDK `^3.11.4`)
- Use `late` only when field is initialized after construction (e.g., `late WebViewController _controller`)
- Use nullable (`?`) for fields that may not be set (`ServerEntry? selected`)
- `dynamic` used sparingly — only in `main.dart` for `initialEntry` parameter

## Generic Patterns

```dart
// fromJson: explicit casts with `as`
factory ServerEntry.fromJson(Map<String, dynamic> json) => ServerEntry(
  id: json['id'] as String?,
  name: json['name'] as String? ?? '',
);

// copyWith: named parameters with optional types
ServerEntry copyWith({String? name, String? url}) => ...
```

## Rules

- JSON deserialization: always use `as String?`, `as int?` to handle null
- Provide defaults (`?? ''`) for optional string fields from JSON
- Use `const` constructor where possible for widgets
- Use `required` named parameters for widget constructors
