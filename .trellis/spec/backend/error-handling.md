# Error Handling Guidelines

## Current Patterns

- JSON parse errors: wrapped in try/catch, return fallback (empty list)
- SharedPreferences errors: unhandled (let crash — unlikely in practice)
- WebView errors: caught via `onWebResourceError` → `ScaffoldMessenger.showSnackBar`
- Dialog inputs: validate non-empty before submit

## Rules

- Parse failures return safe defaults (empty list, null), never rethrow
- Network errors in WebView: show user-facing SnackBar, don't crash
- Form validation: check `.trim().isEmpty` before accepting, show nothing if invalid
- No custom exception types yet — revert to try/catch with fallback
