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
