# Code Quality - Parallel Calls, toJson, mounted Checks

## Background
Code quality issues identified: 3 separate HTTP calls to /provider, sequential awaits, missing mounted checks before setState, missing toJson/copyWith on models, stream subscription management gaps.

## Scope
Phase 5 of 5-phase alignment plan. Code quality improvements only.

## Acceptance Criteria (All Phases)
- **功能一致**: 与 opencode Web 端功能保持一致，所有 Web 端已有的核心功能都必须在 Flutter 端实现
- **操作体验类似**: 交互方式、快捷键、反馈机制与 Web 端一致
- **风格仿 iOS**: 使用 iOS 原生风格设计（毛玻璃效果、原生滚动、HIG 规范）
- **完整 Review**: 所有功能完成后，必须进行全量代码审查，确保无遗漏、无退化

## Deliverables
1. Merge 3 /provider calls into 1 getAllProviderData()
2. Parallel await in _load() (Future.wait)
3. Add mounted checks before all setState calls
4. Add toJson/copyWith to all models
5. Save StreamSubscription, cancel in dispose
6. flutter analyze — zero errors

## Files
- lib/models.dart
- lib/services/opencode_api.dart
- lib/screens/native/chat_screen.dart
- lib/services/event_service.dart
