# Fix Critical Bugs

## Background
Code review vs opencode SDK/server source revealed critical incompatibilities:
- SSE event parsing reads wrong field (event: line instead of data.payload.type)
- 6+ model fields read incorrect JSON keys or wrong types
- Auth endpoints send empty/malformed request bodies
- Provider.models list vs map type mismatch

## Scope
Phase 1 of 5-phase alignment plan. Fixes only crash/data-corruption bugs, no new features.

## Acceptance Criteria (All Phases)
- **功能一致**: 与 opencode Web 端功能保持一致，所有 Web 端已有的核心功能都必须在 Flutter 端实现
- **操作体验类似**: 交互方式、快捷键、反馈机制与 Web 端一致
- **风格仿 iOS**: 使用 iOS 原生风格设计（毛玻璃效果、原生滚动、HIG 规范）
- **完整 Review**: 所有功能完成后，必须进行全量代码审查，确保无遗漏、无退化

## Deliverables
1. event_service.dart — SSE parser reads payload.type, clears buffer correctly
2. models.dart — Provider.models as list from map values, SearchMatch double-dereference, ProviderAuthMethod.url→label, ProviderAuthAuthorization fields, FormatterStatus bool, Todo status string, DiffEntry flat format
3. opencode_api.dart — oauthAuthorize sends method body
4. chat_screen.dart — event listener error handler + subscription tracking
5. flutter analyze — zero errors

## Files
- lib/services/event_service.dart
- lib/models.dart
- lib/services/opencode_api.dart
- lib/screens/native/chat_screen.dart
