# Rebuild SSE Event System

## Background
The SSE event parsing reads the wrong field (`event:` line vs `data.payload.type`) and handles only 3 of 50+ event types. No real-time streaming support.

## Scope
Phase 3 of 5-phase alignment plan. Fix event parsing, add streaming text delta support, permission/question event handlers.

## Acceptance Criteria (All Phases)
- **功能一致**: 与 opencode Web 端功能保持一致，所有 Web 端已有的核心功能都必须在 Flutter 端实现
- **操作体验类似**: 交互方式、快捷键、反馈机制与 Web 端一致
- **风格仿 iOS**: 使用 iOS 原生风格设计（毛玻璃效果、原生滚动、HIG 规范）
- **完整 Review**: 所有功能完成后，必须进行全量代码审查，确保无遗漏、无退化

## Deliverables
1. Event type matching via data.payload.type (50+ event types)
2. message.part.delta streaming text handling
3. message.updated / message.removed event handlers
4. permission.asked event → permission request UI
5. question.asked event → question UI
6. flutter analyze — zero errors

## Files
- lib/services/event_service.dart
- lib/screens/native/chat_screen.dart
