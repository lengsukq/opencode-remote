# Sub-Agent Code Review Report

**日期:** 2026-06-13 | **父任务:** 06-13-code-review

---

## 总结

| 类别 | 数量 | 严重程度 |
|------|------|---------|
| 空 catch 块 | 7 处 | P0 |
| JSON 不安全 `as` 转型 | 25+ 处 | P0 |
| `Future.wait` 不安全转型 | 5 块 | P0 |
| 函数 > 30 行 | 28 个 | P1 |
| 重复代码 | 8 对 | P1 |
| 中文字符串硬编码 | 100+ 处 | P2 |
| 魔数/颜色硬编码 | 30+ 处 | P2 |
| 错误处理不一致 | 各层均有 | P1 |

## 各文件问题数

| 文件 | 问题数 |
|------|--------|
| `lib/screens/native/chat_screen.dart` | ~25 |
| `lib/services/opencode_api.dart` | ~20 |
| `lib/screens/native/dashboard_screen.dart` | ~18 |
| `lib/screens/native/file_browser_screen.dart` | ~16 |
| `lib/screens/native/session_list_screen.dart` | ~12 |
| `lib/screens/native/config_screen.dart` | ~12 |
| `lib/screens/native/project_screen.dart` | ~10 |
| `lib/screens/launcher_screen.dart` | ~10 |
| `lib/screens/webview_screen.dart` | ~10 |
| `lib/screens/onboarding_screen.dart` | ~8 |
| `lib/screens/settings_sheet.dart` | ~8 |
| `lib/models.dart` | ~6 |
| `lib/services/event_service.dart` | ~3 |
| `lib/services/storage_service.dart` | ~4 |
| `lib/main.dart` | ~3 |
| `lib/theme.dart` | 0 |
