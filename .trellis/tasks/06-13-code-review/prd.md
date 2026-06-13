# Code Review: Clean Code 规范检查

## 目标
对整个项目代码进行 Clean Code 规范检查，识别不符合规范的代码并修复。

## 检查范围
- `lib/` 下所有 Dart 文件

## Clean Code 检查项
1. **命名规范** — 类名 PascalCase、变量/方法 camelCase、常量有意义的命名
2. **函数长度** — 单个方法不超过 30 行（不含空行/注释）
3. **重复代码** — 相同的逻辑/模式重复 2+ 次的应提取
4. **硬编码** — 魔数、字符串常量应提取为命名常量
5. **空安全** — 不必要的 null 判断、`!` 强制解包
6. **错误处理** — 吞异常（空 catch）、丢失错误上下文
7. **Widget 拆分** — 过大 build 方法应拆分小组件
8. **import 规范** — 未使用的 import、wildcard import

---

## 完成状态

- [x] lib/main.dart 审查
- [x] lib/models.dart 审查
- [x] lib/theme.dart 审查
- [x] lib/services/ 审查
- [x] lib/screens/ 全部 9 个文件审查
- [x] 跨文件共性问题汇总
- [x] 优先级矩阵
- [x] 结果写入 `research/clean-code-review.md`
