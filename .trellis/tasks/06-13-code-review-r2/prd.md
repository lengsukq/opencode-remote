# Code Review Round 2 — 复查报告

## 检查结果

Sub-agent 已完成全面复查，覆盖 `lib/` 下所有 Dart 文件。

---

## 优先级矩阵

### P0 — 立即修复（崩溃风险）

| 问题 | 数量 | 位置 |
|------|------|------|
| **空 catch 块** — `catch (_) {}` 吞掉所有异常 | 7 处 | `storage_service.dart:22,74`、`event_service.dart:78,105`、`session_list_screen.dart:51`、`chat_screen.dart:321,573`、`config_screen.dart:70` |
| **JSON 不安全 `as` 转型** — `as List` / `as Map` 裸转型，API 变化即 crash | 25+ 处 | `opencode_api.dart` 全文件、`models.dart` 6 处、`event_service.dart` |
| **`Future.wait` 不安全转型** — `results[i] as Type` 无类型检查 | 5 块 | `project_screen.dart:32`、`dashboard_screen.dart:49`、`chat_screen.dart:107`、`config_screen.dart:36` |

### P1 — 尽快处理（可维护性）

| 问题 | 数量 | 位置 |
|------|------|------|
| **函数 > 30 行** | 28 个 | 最严重：`settings_sheet.dart` 126 行、`session_list_screen.dart` 93 行、`onboarding_screen.dart` 91 行 |
| **重复代码** | 8 对 | `_formatTime`(2)、`_showEditDialog`/`_EditDialog`、`_ModeTile`/`_ModeOption`、服务器切换(2)、`_detailRow`(2)、图片预览(2)、文件内容(2)、图片扩展名列表(2) |
| **错误处理不一致** | 各层 | `OpenCodeApi`: throw + bool return 混用；`StorageService`: catch-swallow + let-throw 混用 |

### P2 — 后续重构

| 问题 | 数量 | 说明 |
|------|------|------|
| **中文字符串硬编码** | 100+ 处 | 所有 UI 文件均有，未集中管理 |
| **魔数/颜色硬编码** | 30+ 处 | `Radius.circular(16)`、`EdgeInsets`、`Color(0xFF...)` 未使用主题常量 |

---

## 各文件问题数

| 文件 | 行数 | 问题数 | 主要问题 |
|------|------|--------|---------|
| `chat_screen.dart` | ~1060 | ~25 | Future.wait 转型、空 catch、函数超长、字符串硬编码 |
| `opencode_api.dart` | ~540 | ~20 | JSON 转型泛滥、错误处理不一致 |
| `dashboard_screen.dart` | ~490 | ~18 | Future.wait 转型、重复代码、字符串、函数超长 |
| `file_browser_screen.dart` | ~570 | ~16 | 重复代码、函数超长、字符串硬编码 |
| `session_list_screen.dart` | ~580 | ~12 | 空 catch、函数超长 |
| `config_screen.dart` | ~380 | ~12 | Future.wait 转型、空 catch、字符串硬编码 |
| `project_screen.dart` | ~260 | ~10 | Future.wait 转型、重复代码 |
| `launcher_screen.dart` | ~380 | ~10 | 重复代码、函数超长 |
| `webview_screen.dart` | ~260 | ~10 | 重复代码、函数超长 |
| `onboarding_screen.dart` | ~185 | ~8 | 函数超长、重复代码 |
| `settings_sheet.dart` | ~180 | ~8 | 函数超长、重复代码 |
| `models.dart` | ~620 | ~6 | JSON 转型、命名 |
| `event_service.dart` | ~110 | ~3 | 空 catch、JSON 转型 |
| `storage_service.dart` | ~95 | ~4 | 空 catch、JSON 转型 |
| `main.dart` | ~80 | ~3 | 魔数 |
| `theme.dart` | ~25 | 0 | 干净 |

---

## 详细报告

详见 `research/sub-agent-review-report.md` 和 `research/re-review-report.md`。
