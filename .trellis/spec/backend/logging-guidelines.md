# Logging Guidelines

## Current State

- No logging library is used
- `debugPrint` / `print` are not used in production code
- Errors surface via `ScaffoldMessenger.showSnackBar` in UI

## Guidelines for Future

- Add `package:logging` or similar if debugging needs arise
- Log levels: INFO for connection, WARNING for API failures, SEVERE for crashes
- Never log passwords or auth tokens
- Use `debugPrint` in development, `logging` package in production
