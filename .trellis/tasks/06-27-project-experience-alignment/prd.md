# PRD: 项目核心功能对齐 Web 端体验

> **分析日期**: 2026-06-27
> **范围**: `lib/` 下 Flutter 代码（不改动 `opencode-dev/`）
> **参考**: opencode-dev Web UI（`packages/app/`）的行为作为参考标准

---

## 1. 概述

### 1.1 目标

将 Flutter Remote 客户端的**项目查找、切换、管理**的核心体验与 opencode Web UI 对齐，消除以下维度的体验落差：

1. **项目可见性** — Web 端项目始终在 Sidebar 中可见，Flutter 端需切换 Tab 才能访问
2. **切换效率** — Web 端 1 次点击切换项目，Flutter 端需 3-5 步操作
3. **上下文感知** — Web 端全局状态随项目切换自动刷新，Flutter 端缺少全局状态层
4. **项目管理** — Web 端支持添加项目、拖拽排序、Workspace 管理；Flutter 端只提供只读列表

### 1.2 背景

当前 Flutter Remote 端（`opencode_remote`）的项目相关功能处于**最小可行状态**：

| 功能 | 当前状态 | 差距分析 |
|------|---------|---------|
| 项目列表 | `GET /project` 列出，静态卡片展示 | 不能搜索、添加、删除 |
| 当前项目 | `GET /project/current` + VCS 分支显示 | 切换后无全局反馈 |
| 项目切换 | `api.directory = project.path` | 3-5 步操作，无侧栏快捷方式 |
| 项目持久化 | **无** | Web 端每个 Server 持久化 project list |
| 会话过滤 | 隐含通过 `?directory=` 参数 | SessionListScreen 无项目上下文指示 |
| Workspace | 仅显示当前分支名 | Web 端可展开查看/切换分支 |

### 1.3 范围

- 只改动 `lib/` 下 Flutter 代码
- 不改动 `opencode-dev/`
- 功能行为零负影响：重构/新增不应破坏现有会话和聊天功能

### 1.4 参考架构

opencode Web 端的核心设计：

```
GlobalProvider (multi-server)
  → per-server projects list via createServerProjects()
  → persists { worktree, expanded }[]
  → activeProject → layout.home.selection

Sidebar (NavigationRail equivalent)
  → SortableProject avatars (always visible)
  → click → navigateToProject() → updates layout + router
  → "+" button → DialogSelectDirectory → Project.open()

Home → sessions filtered by selected project
PromptProjectSelector → searchable dropdown for project switch
```

---

## 2. 阶段划分

### Phase 1: 项目侧栏与快捷切换（P0）

#### 2.1.1 功能描述

将当前 `NavigationRail` 中的「项目」Tab 改造为项目头像 rail，用户无需离开当前页面即可一键切换项目上下文。

#### 2.1.2 参考实现

Web 端 `sidebar-shell.tsx` + `sidebar-project.tsx`：
- 左侧 rail 显示项目圆形头像（首字母/icon）
- 点击头像 → `navigateToProject(worktree)` → 更新全局状态
- 在线指示点 + 未读消息数 Badge
- 悬停预览最近会话

#### 2.1.3 要求

| # | 需求 | 优先级 | 参考文件 |
|---|------|--------|---------|
| P1.1 | NavigationRail 中「项目」Tab 变更为项目头像列表（替代单个 icon） | P0 | `sidebar-project.tsx` |
| P1.2 | 每个项目显示为首字母头像 / 文件夹 icon / 自定义 icon | P0 | `sidebar-items.tsx` |
| P1.3 | 当前项目头像高亮（颜色/边框） | P0 | |
| P1.4 | 当前项目名称显示在 rail 底部或 header 区域 | P0 | |
| P1.5 | 点击非当前项目头像 → 立即切换项目 | P0 | |
| P1.6 | 切换后自动刷新当前页面的上下文（会话/文件列表） | P0 | `navigateToProject()` |
| P1.7 | 头像显示项目在线状态 + 未读/活动指示点 | P1 | |
| P1.8 | 侧栏底部「+」按钮用于添加项目 | P0 | |
| P1.9 | 项目头像支持右键/长按上下文菜单（编辑、关闭） | P2 | `DialogEditProject` |

**设计约束：**
- `NavigationRail` 目前有 6 个目的地 + 设置齿轮。新增项目头像后，head 区域保持不变，trailing 设置齿轮保留
- 项目头像区域应可滚动（多于 4 个项目时）
- 如果不激活任何项目，显示默认状态（回到 Dashboard 概要视图）

#### 2.1.4 状态变更

新增全局状态（或提升到 `MainScaffold`）：
```dart
// 新增字段
Project? _activeProject;
String? _activeProjectDirectory;

// 切换方法
void _switchProject(Project project) {
  setState(() {
    _activeProject = project;
    _activeProjectDirectory = project.path;
  });
  _api.directory = project.path;  // 保留现有机制
}
```

子页面（SessionListScreen, FileBrowserScreen, ChatScreen）接收 `Project? activeProject` 并在切换时重建。

---

### Phase 2: 全局项目上下文系统（P0）

#### 2.2.1 功能描述

建立统一的项目上下文（Project Context），使得：
- 切换项目后所有页面感知到上下文变化
- SessionListScreen 只显示当前项目的 sessions
- ChatScreen title 显示项目名
- Dashboard 按项目分组显示

#### 2.2.2 参考实现

Web 端 `LayoutProvider` + `navigateToProject()`：
- `layout.home.selection` = `{ server, directory }`
- 所有页面通过 layout context 获取当前项目
- 切换时触发重建

#### 2.2.3 要求

| # | 需求 | 优先级 |
|---|------|--------|
| P2.1 | `MainScaffold` 维护 `_activeProject` 状态（Project?） | P0 |
| P2.2 | 所有子页面（Dashboard/SessionList/FileBrowser/Chat）通过参数接收当前项目 | P0 |
| P2.3 | 切换项目时子页面重建刷新 | P0 |
| P2.4 | SessionListScreen 显示当前项目名称在 header | P0 |
| P2.5 | ChatScreen AppBar 显示项目名（如"项目名 / 会话标题"） | P1 |
| P2.6 | 会话列表只显示当前项目的会话（API 已通过 `directory` 参数过滤） | P1 |
| P2.7 | 返回 Dashboard 时显示当前项目摘要 | P2 |

**影响文件：**
- `main_scaffold.dart` — 新增 `_activeProject`, `_switchProject()`
- `session_list_screen.dart` — 接收 `activeProject`，Header 显示项目名称
- `dashboard_screen.dart` — 接收 `activeProject`
- `project_screen.dart` — 需要与 main scaffold 通信切换事件

---

### Phase 3: 添加项目（P0）

#### 2.3.1 功能描述

用户可以从项目侧栏的「+」按钮打开添加项目对话框，输入/选择项目目录路径，将项目添加到当前服务器的项目列表中。

#### 2.3.2 参考实现

Web 端 `DialogSelectDirectoryV2` / `DialogSelectDirectory`：
- 目录选择器列出服务器文件系统
- 选定目录后调用 `Project.open(directory)` → `POST /project`
- 项目立即添加到 Sidebar

#### 2.3.3 要求

| # | 需求 | 优先级 | 备注 |
|---|------|--------|------|
| P3.1 | 项目 rail 底部「+」按钮打开添加项目对话框 | P0 | |
| P3.2 | 输入框输入项目目录路径（文本输入，允许粘贴） | P0 | 移动端不方便文件浏览 |
| P3.3 | 可选：调用服务器文件浏览器列出可选目录 | P2 | 参考 Web 端 DialogSelectDirectory |
| P3.4 | 确定后调 `POST /project` 或 `POST /project/git/init` | P0 | 需确认 opencode 协议 |
| P3.5 | 添加成功后刷新项目列表 + 自动设为当前项目 | P0 | |
| P3.6 | 项目持久化到本地存储（SharedPreferences） | P1 | 重启后恢复项目列表 |
| P3.7 | 删除/关闭项目支持（长按上下文菜单 → "关闭项目"） | P1 | |

---

### Phase 4: 会话按项目过滤（P1）

#### 2.4.1 功能描述

SessionListScreen 在项目上下文下只显示该项目的会话。

#### 2.4.2 实现要点

当前机制：`OpenCodeApi._buildUri()` 已自动在所有请求追加 `directory` 参数。所以 `getSessions()` 实际上已经在按目录过滤。

缺失部分：**UI 无任何指示**表明当前在过滤中，用户不知道当前看到的是「全部会话」还是「项目 A 的会话」。

#### 2.4.3 要求

| # | 需求 | 优先级 |
|---|------|--------|
| P4.1 | SessionListScreen AppBar 显示"项目名 > 会话"（有 activeProject 时） | P0 |
| P4.2 | 无 activeProject 时显示"全部会话" | P0 |
| P4.3 | 切换项目时自动刷新会话列表 | P1 |
| P4.4 | 会话卡片可显示所属项目名称（可选） | P2 |

---

### Phase 5: 项目搜索（P1）

#### 2.5.1 功能描述

在 ProjectScreen 和项目侧栏中提供搜索功能，用户可快速定位项目。

#### 2.5.2 参考实现

Web 端 `PromptProjectSelector`：
- 搜索式下拉框
- 输入关键词实时过滤项目列表
- 选择后切换项目

#### 2.5.3 要求

| # | 需求 | 优先级 |
|---|------|--------|
| P5.1 | 项目侧栏顶部添加搜索框 | P1 |
| P5.2 | 输入文字即时过滤项目头像列表 | P1 |
| P5.3 | 搜索匹配项目名 + 路径 | P1 |
| P5.4 | 支持键盘操作（选中的项目自动高亮） | P2 |

---

### Phase 6: Workspace（Git 分支）管理（P1-P2）

#### 2.6.1 功能描述

在项目详情或侧栏中展开显示 git 分支列表，支持切换分支。

#### 2.6.2 参考实现

Web 端 `SortableWorkspace`（`sidebar-workspace.tsx`）：
- 项目下可展开 workspace 列表
- 每个 workspace 显示分支名 + 会话数量
- 右键菜单：重命名、重置、删除

#### 2.6.3 要求

| # | 需求 | 优先级 | 备注 |
|---|------|--------|------|
| P6.1 | 项目卡片/头像下方可展开显示分支列表 | P1 | |
| P6.2 | 调用 `GET /workspace/list` 获取分支 | P1 | 需确认 endpoint |
| P6.3 | 点击分支切换当前工作目录（`api.directory` + 分支参数） | P1 | |
| P6.4 | 当前分支高亮显示 | P1 | |
| P6.5 | 当前分支旁边的项目头像上显示分支名 badge | P1 | 现已有 vcs!.branch |

---

### Phase 7: 拖拽排序与持久化（P2-P3）

#### 2.7.1 功能描述

项目列表支持拖拽重新排序，排序结果持久化到本地存储。

#### 2.7.2 要求

| # | 需求 | 优先级 |
|---|------|--------|
| P7.1 | 项目头像/卡片支持长按拖拽排序 | P2 |
| P7.2 | 排序结果保存到 SharedPreferences | P2 |
| P7.3 | 重新连接服务器后恢复排序顺序 | P2 |
| P7.4 | 支持多服务器独立项目列表 | P3 |

---

## 3. 文件变更清单

### 3.1 修改文件

| # | 文件 | 操作 | 说明 |
|---|------|------|------|
| M01 | `lib/widgets/main_scaffold.dart` | 大改 | NavigationRail 集成项目头像 rail；新增 `_activeProject` 状态；`_switchProject()` 方法 |
| M02 | `lib/screens/native/project_screen.dart` | 增强 | 使用共享组件；新增搜索；新增添加项目入口；新增删除/关闭 |
| M03 | `lib/screens/native/session_list_screen.dart` | 修改 | 接收 `activeProject` 参数；Header 显示项目上下文 |
| M04 | `lib/screens/native/dashboard_screen.dart` | 修改 | 接收 `activeProject` 参数；按项目分组会话 |
| M05 | `lib/screens/native/chat_screen.dart` | 修改 | AppBar 添加项目名称前缀 |
| M06 | `lib/screens/native/file_browser_screen.dart` | 修改 | 接收 `activeProject`；root 路径跟随项目 |
| M07 | `lib/strings.dart` | 增强 | 添加项目相关 UI 字符串 |
| M08 | `lib/theme.dart` | 增强 | 如需新增项目头像相关颜色常量 |

### 3.2 新增文件

| # | 文件 | 说明 | 预估行数 |
|---|------|------|----------|
| F01 | `lib/widgets/project_avatar.dart` | 项目头像小组件（首字母 + 状态指示 + badge） | ~80 |
| F02 | `lib/widgets/project_sidebar.dart` | 项目侧栏 rail 组件（从 main_scaffold 拆分） | ~150 |
| F03 | `lib/widgets/add_project_dialog.dart` | 添加项目对话框（文本输入 + 可选目录浏览） | ~100 |
| F04 | `lib/utils/project_helpers.dart` | 项目相关的工具方法（排序、持久化、名称生成） | ~60 |
| F05 | `lib/widgets/workspace_list.dart` | Workspace/分支列表展开组件 | ~120 |

---

## 4. 数据模型变更

### 4.1 Project 模型（已有）

```dart
class Project {
  final String id;
  final String name;
  final String path;
  // 新增（本地模型）
  // final String? icon;
  // final String? color;
  // final List<String>? workspaceIDs;
}
```

### 4.2 本地持久化

```dart
// SharedPreferences key
'projects:$serverId' → JSON array of { id, name, path, order }
```

---

## 5. 非功能性需求

| # | 需求 | 说明 |
|---|------|------|
| N1 | 向后兼容 | 所有变更不能破坏现有无项目上下文时的功能（全部会话模式） |
| N2 | 性能 | 项目列表 ≤ 50 个时不卡顿 |
| N3 | 无全局库引入 | 不引入 Provider/Riverpod/Bloc，用 `setState` + 参数传递 |
| N4 | 主题一致性 | 新组件遵循 `AppColors` + `S` 字符串规则 |
| N5 | 移动端适配 | 项目头像大小适配触摸操作（至少 44px touch target） |

---

## 6. 里程碑与预估工期

| 里程碑 | 内容 | 涉及文件 | 预估 |
|--------|------|---------|------|
| **M1** | Phase 1: 项目侧栏 rail + 快捷切换 | M01, M02, F01, F02 | 3 天 |
| **M2** | Phase 2: 全局项目上下文 | M01, M03, M04, M05, M06 | 2 天 |
| **M3** | Phase 3: 添加项目功能 | M02, F03, F04 | 1.5 天 |
| **M4** | Phase 4: 会话按项目过滤 | M03 | 1 天 |
| **M5** | Phase 5-7: 搜索 + Workspace + 排序 | M02, F05 | 2.5 天 |
| **总计** | | **~13 个文件** | **~10 天** |

---

## 7. 不纳入范围

- 富文本项目描述/备注
- 跨服务器项目迁移
- 项目级别的权限管理
- 项目级别的配置管理（ConfigScreen 已处理）
- 与服务端同步项目 icon/color（Web 端 `DialogEditProject` 功能，但需要服务端支持 `PATCH /project/{id}`）
- 会话合并/比较（另有任务跟踪）

---

## 8. 附录：Web 端参考行为速查

| 行为 | Web 端 | Flutter 端目标 |
|------|--------|---------------|
| 查看所有项目 | 左侧 rail + Home 页 | 左侧 rail + ProjectScreen |
| 切换项目 | 点击 rail 头像 | 点击 rail 头像 |
| 添加项目 | "+" → 目录选择器 → 确认 | "+" → 路径输入 → 确认 |
| 项目搜索 | PromptProjectSelector 下拉 | ProjectScreen 搜索框 |
| 分支切换 | 展开 workspace 列表 → 点击 | 展开列表 → 点击 |
| 会话过滤 | 自动按 project 过滤 | `api.directory` 过滤 + UI 指示 |
| 拖拽排序 | 头像拖拽 | 列表拖拽排序 |
| 持久化 | per-server projects | per-server projects (local storage) |
