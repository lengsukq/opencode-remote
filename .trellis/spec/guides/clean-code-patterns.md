# Clean Code Patterns Guide

> **Purpose**: Specific Clean Code patterns proven in this codebase. Follow these when writing new code or refactoring existing code.

---

## File Organization

### Rule: One File, One Purpose

A file must serve **exactly one purpose**. If you can't describe what a file does in a single sentence without using "and", it needs splitting.

Extract when:

- File **> 500 lines** → split (models.dart is the only allowed exception)
- File has **3+ public classes** → split
- File mixes **data models + UI widgets** → split
- File contains **State class + unrelated helper classes** → extract helpers
- `State` class has **20+ members** → extract helpers

### Rule: Widget Extraction

Widgets that are:
- **> 50 lines** → should be a separate file
- **Used in 2+ screens** → go in `lib/widgets/`
- **Screen-specific but large** → go in `lib/screens/<screen>/` sub-directory

---

## Method Structure

### Rule: Max 30 Lines Per Method

Every method (including `build()`) should be ≤ 30 lines. Split any method that reaches 31+.

**Pattern: Split async fetch from state assignment**

```dart
// BAD: 35 lines
Future<void> _load() async {
  setState(() => _loading = true);
  try {
    final a = await api.getA();
    final b = await api.getB();
    // 25 more lines of logic + setState...
  } catch (e) { ... }
}

// GOOD: 3 methods, each ≤ 15 lines
Future<void> _load() async { ... _loadAllData(); ... _applyLoadedData(); ... }
Future<_LoadData> _loadAllData() async { ... }
void _applyLoadedData(_LoadData data) { ... }
```

**Pattern: Split send methods by type**

```dart
// BAD: one _sendMessage handles shell + command + text
Future<void> _sendMessage() async {
  if (shell) { await _sendShell(); }
  else if (cmd) { await _sendCommand(); }
  else { await _sendText(); }
  // shared post-send logic
}

// GOOD: dispatch to specialized methods
Future<void> _sendMessage() async {
  await dispatch();   // 5 lines
  _postSend();        // 5 lines
}
Future<void> _sendShell() async { ... }
Future<void> _sendCommand() async { ... }
Future<void> _sendText() async { ... }
```

---

## State Management

### Rule: Guard All setState After Await

```dart
// ALWAYS check mounted after async gap
Future<void> _doSomething() async {
  final result = await api.call();
  if (!mounted) return;       // ← REQUIRED
  setState(() => _data = result);
}
```

### Rule: Clean dispose()

```dart
@override
void dispose() {
  _controller.removeListener(_handler);  // 1. remove listeners
  _controller.dispose();                  // 2. dispose controllers
  _subscription?.cancel();                // 3. cancel subscriptions
  _service?.dispose();                    // 4. dispose services
  super.dispose();                        // 5. super last
}
```

---

## Error Handling

### Rule: Never Empty Catch

```dart
// BAD
catch (_) {}

// GOOD
catch (e) { debugPrint('Tag: $e'); }

// BETTER (when appropriate)
catch (e) {
  debugPrint('Tag: $e');
  rethrow;  // or handle gracefully
}
```

### Rule: Safe JSON Casts

```dart
// BAD — runtime crash if null
final name = json['name'] as String;

// GOOD — safe with fallback
final name = json['name'] as String? ?? '';
final list = json['items'] as List<dynamic>? ?? [];
final map = json['data'] as Map<String, dynamic>? ?? {};
```

### Rule: No Future.wait + as

```dart
// BAD — crashes if future order changes
final results = await Future.wait([f1(), f2()]);
final a = results[0] as TypeA;

// GOOD — typed individual awaits
final a = await f1();
final b = await f2();
```

---

## Naming

| Element | Pattern | Example |
|---------|---------|---------|
| Constants | `_k` prefix + camelCase | `_kMaxItems`, `_kDefaultAgent` |
| Magic numbers | Named const | `_kContextWindowTokens = 128000` |
| Booleans | `is`/`has`/`show` prefix | `isLoading`, `hasError`, `showCommands` |
| Event handlers | `_handle` prefix | `_handleDelta`, `_handlePermission` |
| Async methods | `_load`, `_send`, `_refresh` | `_loadTodos`, `_sendMessage` |
| Private widgets | `_` prefix class name | `_LoadData` (data holder) |

---

## Code Review Checklist

Before committing, verify:

- [ ] `flutter analyze` passes with **zero errors**
- [ ] No file exceeds **500 lines** (rare exceptions justified in comment)
- [ ] File has **one clear purpose** (no mixing of unrelated concepts)
- [ ] No method exceeds **30 lines**
- [ ] `State` class has **≤ 20 member variables**
- [ ] No empty `catch` blocks
- [ ] All `setState` after `await` is guarded by `mounted`
- [ ] No `Future.wait` + `as` cast pattern
- [ ] All JSON `as` casts use nullable pattern (`as Type? ?? default`)
- [ ] No duplicate UI patterns (extracted if seen 2+ times)
- [ ] All magic numbers extracted to named `const`
- [ ] `dispose()` cleans up listeners, controllers, subscriptions, services
