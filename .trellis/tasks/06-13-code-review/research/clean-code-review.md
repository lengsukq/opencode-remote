# Clean Code Review

> 对整个项目的 Dart 代码进行 Clean Code 规范检查。
> 审查日期: 2026-06-13

---

## 目录

- [跨文件共性问题](#跨文件共性问题)
- [lib/models.dart](#libmodelsdart)
- [lib/services/](#libservices)
- [lib/screens/](#libscreens)
- [优先级矩阵](#优先级矩阵)

---

## 跨文件共性问题

### 1. `Future.wait` 不安全转型 (4 个文件)

`Future.wait` 返回 `List<dynamic>`，所有结果访问都用 `results[i] as Type`，如果 future 顺序变化或类型不匹配即 runtime crash。

**涉及文件:**
- `lib/screens/native/dashboard_screen.dart:52-56`
- `lib/screens/native/chat_screen.dart:79-81`
- `lib/screens/native/project_screen.dart:38-40`

**建议:** 改用 Dart 3 record 类型或逐一定义变量。

### 2. `_formatTime` 重复 (3 个文件)

```dart
String _formatTime(int ms) { ... }
// 完全相同的函数在:
// - lib/screens/launcher_screen.dart:89-97
// - lib/screens/native/dashboard_screen.dart:359-367
// - lib/screens/native/chat_screen.dart:782-785 (不同格式: HH:mm)
```

**建议:** 提取到 `lib/utils/time_format.dart`。

### 3. `Radius.circular(16)` 硬编码 (9 个文件全部出现)

BottomSheet 圆角值在每处硬编码。

**建议:** 在 `theme.dart` 定义常量 `kDefaultBorderRadius = 16.0`。

### 4. `TextField` 装饰样式重复 (~15 处)

```dart
TextField(
  style: const TextStyle(color: AppColors.textPrimary),
  decoration: InputDecoration(
    hintText: '...',
    hintStyle: TextStyle(color: AppColors.textTertiary),
    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.border)),
    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.borderFocused)),
  ),
)
```

**建议:** 提取共享 `AppTextField` widget 或静态 `AppInputDecoration`。

### 5. 中文字符串硬编码

所有 UI 文本 (~80+ 处) 直接写在代码中。

**建议:** 提取到 `lib/strings.dart` 或使用 `MaterialLocalizations`。

### 6. JSON `as` 强制转型 (全项目)

大量 `jsonDecode` 后的值直接 `as List<dynamic>` / `as Map<String, dynamic>`，API 响应结构变化时直接 crash。

**建议:** 使用 `as?` + 默认值兜底。

---

## lib/models.dart

| 行 | 类别 | 问题 |
|----|------|------|
| 151 | 多余 null 断言 | `reasoning!` 在 `reasoning != null` 之后已被 promotion |
| 304 | 命名 | `fullID` → `fullId` (Dart 惯例) |
| 319, 353, 391 | 不安全转型 | `e.value as Map`, `e as Map` 等 |
| 25 | 魔数 | `rand.nextInt(99999)` 应提取常量 |
| 419-420, 432, 444 | 重复代码 | `FormatterStatus`/`MCPStatus`/`LSPStatus` 结构完全相同 |
| 多个 | 模板代码 | ~24 个 `fromJson` 重复相同模式，可考虑 `json_serializable` |

---

## lib/services/

### storage_service.dart

| 行 | 类别 | 问题 |
|----|------|------|
| 21, 73 | 空 catch | `catch (_) { return []; }` 吞掉所有异常 |
| 16, 18 | 不安全转型 | `jsonDecode(raw) as List`、`e as Map` 在空 catch 内 |
| 12+ | 重复 | `SharedPreferences.getInstance()` 每个方法都调 |
| 81, 87 | 魔字符串 | `'native'`/`'webview'` 硬编码 |

### opencode_api.dart

| 行 | 类别 | 问题 |
|----|------|------|
| 32 | 不安全 `!` | `directory!` 强制解包 |
| 56-60 vs 86,93,121,125,177,184,189,257,396,438 | 错误处理不一致 | 有些 throw、有些 return bool、有些 ignore |
| 236, 253, 277, 295 | 重复代码 | model 拼解析复制了 4 次 |
| 79-447 (多处) | 不安全转型 | JSON `as` 转型遍布所有方法 |

---

## lib/screens/

### launcher_screen.dart

| 行 | 类别 | 问题 |
|----|------|------|
| 100-160 | build 过大 | `build()` 方法 60 行 |
| 277-367 | 函数过长 | `_showEditDialog` 90 行 |
| 89-97 | 重复代码 | `_formatTime` 与 dashboard_screen 重复 |
| 369-380 | 重复代码 | `_inputDec` 与 webview_screen `_field` 基本相同 |

### webview_screen.dart

| 行 | 类别 | 问题 |
|----|------|------|
| 61-111 | 函数过长 | `_switchServer` 50 行 |
| 175-257 | 重复代码 | `_EditDialog` 与 launcher 的 `_showEditDialog` 基本重复 |

### onboarding_screen.dart

| 行 | 类别 | 问题 |
|----|------|------|
| 12-102 | build 过大 | `build()` 90 行，7 层嵌套 |
| 114-181 | 重复代码 | `_ModeOption` 与 settings_sheet 的 `_ModeTile` 基本相同 |

### settings_sheet.dart

| 行 | 类别 | 问题 |
|----|------|------|
| 32-88 | build 过大 | 56 行 |
| 105-163 | 重复代码 | `_ModeTile` 与 onboarding `_ModeOption` 重复 |

### native/dashboard_screen.dart

| 行 | 类别 | 问题 |
|----|------|------|
| 52-56 | 不安全转型 | `Future.wait` 结果 unsafe cast |
| 79-120 | 重复代码 | `_switchServer` 与 webview_screen 重复 |
| 481-489 | 重复代码 | `_formatTime` 与 launcher_screen 重复 |
| 297-358 | build 过大 | `_StatusCard.build` 61 行 |

### native/session_list_screen.dart

| 行 | 类别 | 问题 |
|----|------|------|
| 34 | 空 catch | `catch (_) { sessions = []; }` 吞异常 |
| 89-153 | 函数过长 | `_showSessionActions` 64 行 |
| 210-284 | 函数过长 | `_showDiff` 74 行 |

### native/chat_screen.dart

| 行 | 类别 | 问题 |
|----|------|------|
| 79-81 | 不安全转型 | `Future.wait` 结果 unsafe cast |
| 214 | 空 catch | 轮询中 `catch (_) {}` 吞掉所有 API 错误 |
| 1010-1012 | 命名 | 顶层 `copyToClipboard` 与私有方法同名 |
| 445-502 | build 过大 | 57 行 |
| 710-780 | build 过大 | `_MessageBubble.build` 70 行 |
| 830-903 | build 过大 | `_ModelPickerSheet.build` 73 行 |

### native/file_browser_screen.dart

| 行 | 类别 | 问题 |
|----|------|------|
| 78-114 vs 116-152 | 重复代码 | `_showFileContent` 和 `_readFileByPath` 90% 相同 |
| 324-326 | 魔字符串 | tab 类型用 raw string，应改为 enum |

### native/project_screen.dart

| 行 | 类别 | 问题 |
|----|------|------|
| 38-40 | 不安全转型 | `Future.wait` 结果 unsafe cast |
| 76 | 多余 null 断言 | `_current!` 在 `if` 检查后可 promotion |
| 174-262 | build 过大 | `_ProjectCard.build` 88 行 |
| 148-157 | 重复代码 | `_detailRow` 与 chat_screen 重复 |

---

## 优先级矩阵

| 优先级 | 数量 | 说明 |
|--------|------|------|
| P0 立即修复 | 3 | 空 catch 吞异常 (storage, chat)；不安全 JSON 转型 (models, api) |
| P1 尽快处理 | 5 | 错误处理不一致；`Future.wait` 转型；重复 `_formatTime`；重复对话框；重复服务器切换 |
| P2 后续重构 | 8 | build 方法拆分；`TextField` 装饰提取；常量提取；中文字符串提取；重复组件合并 |
