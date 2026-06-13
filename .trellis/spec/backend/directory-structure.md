# Backend Directory Structure

> This project has no traditional backend. "Backend" refers to:
> 1. The **opencode HTTP server** (`opencode serve`) that this app connects to remotely
> 2. The **local storage layer** (SharedPreferences) on the device

## Service Layer (`lib/services/`)

| File | Purpose |
|------|---------|
| `storage_service.dart` | CRUD for server entries via SharedPreferences |
| `api_service.dart` (future) | HTTP client for opencode REST API |

## Data Models (`lib/models.dart`)

All shared data models live in a single `models.dart` file at `lib/`:
- `ServerEntry` — represents a remote opencode server connection (url, auth, metadata)

## Pattern Rules

- Services are **static classes** with static methods (no instantiation)
- Models use `fromJson`/`toJson` serialization for SharedPreferences persistence
- API calls (future) should be wrapped in a single service class
