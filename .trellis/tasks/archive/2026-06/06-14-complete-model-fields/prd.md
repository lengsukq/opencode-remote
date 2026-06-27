# Complete Model Fields

## Background
Flutter models are missing 40+ fields compared to the opencode SDK/server types, limiting feature implementation and data display.

## Scope
Phase 2 of 5-phase alignment plan. Add all missing fields to existing models, no new features.

## Acceptance Criteria (All Phases)
- **功能一致**: 与 opencode Web 端功能保持一致，所有 Web 端已有的核心功能都必须在 Flutter 端实现
- **操作体验类似**: 交互方式、快捷键、反馈机制与 Web 端一致
- **风格仿 iOS**: 使用 iOS 原生风格设计（毛玻璃效果、原生滚动、HIG 规范）
- **完整 Review**: 所有功能完成后，必须进行全量代码审查，确保无遗漏、无退化

## Deliverables
1. Session — +16 fields (slug, directory, parentID, version, summary, cost, tokens, share, agent, model, metadata, revert, time.*)
2. Message — +10 fields (sessionID, agent, path, cost, tokens, finish, error, parentID, time.completed)
3. Part — 9 new subclasses (FilePart, SubtaskPart, StepStartPart, StepFinishPart, SnapshotPart, PatchPart, AgentPart, RetryPart, CompactionPart)
4. ProviderModel — +9 fields (api, capabilities, cost, limit, options, headers, release_date, variants)
5. Provider — +4 fields (source, env, key, options)
6. Agent — +6 fields (model, prompt, tools, options, temperature/topP, permission)
7. SessionStatus — discriminated union refactor
8. MCPStatus — 5-variant discriminated union refactor
9. flutter analyze — zero errors

## Files
- lib/models.dart
