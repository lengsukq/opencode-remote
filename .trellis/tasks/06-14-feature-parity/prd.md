# Feature Parity - Tool Calls, Attachments, Permissions

## Background
The Flutter app is missing major features present in the web app: tool call visualization, file attachments, permission/request UI, prompt history, and real-time message streaming.

## Scope
Phase 4 of 5-phase alignment plan. Add missing features to match web app functionality.

## Acceptance Criteria (All Phases)
- **功能一致**: 与 opencode Web 端功能保持一致，所有 Web 端已有的核心功能都必须在 Flutter 端实现
- **操作体验类似**: 交互方式、快捷键、反馈机制与 Web 端一致
- **风格仿 iOS**: 使用 iOS 原生风格设计（毛玻璃效果、原生滚动、HIG 规范）
- **完整 Review**: 所有功能完成后，必须进行全量代码审查，确保无遗漏、无退化

## Deliverables
1. Tool call visualization (15+ tool types with custom rendering)
2. File/image attachments (paste, pick, drag-and-drop)
3. Permission request UI (allow once/always, deny)
4. Question/answer interaction UI
5. Prompt history (up/down arrow navigation)
6. Real-time streaming text display (paced rendering)
7. flutter analyze — zero errors

## Files
- lib/screens/native/chat_screen.dart
- lib/screens/native/ (new widgets)
- lib/widgets/ (new components)
