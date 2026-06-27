# TODO: 项目核心功能对齐 Web 端体验

> 基于 `prd.md` 的详细实现清单  
> **总预估**: ~10 天  
> **前置依赖**: Clean Code 重构完成（06-27-clean-code-refactor `Phase A` 解决 API 超时等基础问题）

---

## Phase 1: 项目侧栏与快捷切换（P0 ~3 天）

### 1.1 新增 `ProjectAvatar` 小组件

**文件**: `lib/widgets/project_avatar.dart` (新增, ~80 行)

- [ ] **1.1.1** 创建 `ProjectAvatar` StatelessWidget
  - 参数: `Project project`, `bool isActive`, `VoidCallback? onTap`
  - 显示为首字母圆形头像（`project.name[0]`）
  - 激活状态高亮边框（`AppColors.primary`）
  - 当前项目 badge（"当前" 标记）
- [ ] **1.1.2** 添加在线/活动状态指示点（可选，`Project` 模型无此字段时可暂时留空）
- [ ] **1.1.3** 正确使用 `AppColors` 常量，不使用硬编码颜色
- [ ] **1.1.4** 触摸目标 ≥ 44px

### 1.2 重构 `MainScaffold` — NavigationRail 集成项目 rail

**文件**: `lib/widgets/main_scaffold.dart` (大改)

- [ ] **1.2.1** 添加 `_projects` 列表加载 + `_activeProject` 状态
  ```dart
  List<Project> _projects = [];
  Project? _activeProject;
  ```
- [ ] **1.2.2** 在 `initState` 中异步加载项目列表（`_api.getProjects()`）
- [ ] **1.2.3** 修改 `NavigationRail` 的结构：
  - 移除原有的「项目」`NavigationRailDestination`
  - 在 `NavigationRail` 的 `leading` 和 `destinations` 之间插入**项目头像区域**（可滚动 `ListView`）
- [ ] **1.2.4** 项目头像区域：每个 `ProjectAvatar` 占一个 slot
  - 点击头像 → `_switchProject(project)`
  - 当前项目高亮
- [ ] **1.2.5** 添加 `_switchProject(Project)` 方法：
  ```dart
  void _switchProject(Project project) {
    _api.directory = project.path;
    setState(() => _activeProject = project);
  }
  ```
- [ ] **1.2.6** 在 rail 底部、设置齿轮上方添加「+」按钮（`Icons.add_circle_outline`）
- [ ] **1.2.7** 添加 `VoidCallback onAddProject` 用于后续与 Phase 3 联动
- [ ] **1.2.8** 项目 > 4 个时 rail 区域可滚动

### 1.3 传递 `activeProject` 到子页面

**文件**: `lib/widgets/main_scaffold.dart`

- [ ] **1.3.1** 修改 `_buildPage()` 方法，将所有子页面构造参数加上 `activeProject`：
  ```dart
  case NavPage.sessions:
    return SessionListScreen(
      entry: widget.entry, api: _api,
      activeProject: _activeProject,
    );
  ```
  - [ ] DashboardScreen 接收 `activeProject`
  - [ ] SessionListScreen 接收 `activeProject`
  - [ ] FileBrowserScreen 接收 `activeProject`
  - [ ] ChatScreen（push 时传递）

### 1.4 移除旧的 ProjectScreen Tab 导航

- [ ] **1.4.1** 项目 rail 已覆盖快捷切换功能后，保留 ProjectScreen 作为"项目管理"详细页面
- [ ] **1.4.2** ProjectScreen 仍然可通过其他方式进入（如从项目头像右键菜单）

---

## Phase 2: 全局项目上下文系统（P0 ~2 天）

### 2.1 SessionListScreen 项目上下文

**文件**: `lib/screens/native/session_list_screen.dart`

- [ ] **2.1.1** 构造函数添加 `Project? activeProject` 参数
- [ ] **2.1.2** AppBar title 动态显示：
  - 有 `activeProject` → `"${activeProject.name} / 会话"`
  - 无 `activeProject` → `"会话"`
- [ ] **2.1.3** 当 `activeProject` 变化时（通过 `didUpdateWidget` 检测）自动调用 `_load()` 刷新
- [ ] **2.1.4** 无项目上下文时保持现有行为（显示全部会话）

### 2.2 DashboardScreen 项目上下文

**文件**: `lib/screens/native/dashboard_screen.dart`

- [ ] **2.2.1** 构造函数添加 `Project? activeProject` 参数
- [ ] **2.2.2** 显示当前项目名称在 Dashboard 顶部（"当前项目: xxx"）
- [ ] **2.2.3** 最近会话列表只显示当前项目下的会话
- [ ] **2.2.4** 无项目时显示提示"选择一个项目开始"

### 2.3 FileBrowserScreen 项目上下文

**文件**: `lib/screens/native/file_browser_screen.dart`

- [ ] **2.3.1** 构造函数添加 `Project? activeProject` 参数
- [ ] **2.3.2** 初始 root 路径跟随 `activeProject.path`（有项目时）
- [ ] **2.3.3** AppBar 显示"项目名 / 文件"

### 2.4 ChatScreen 项目上下文

**文件**: `lib/screens/native/chat_screen.dart`

- [ ] **2.4.1** push ChatScreen 时传入 `activeProject`
- [ ] **2.4.2** AppBar title 显示 `"${activeProject?.name ?? ''} / ${session.title}"`
  - 无项目时保持现有 `session.title`

---

## Phase 3: 添加项目功能（P0 ~1.5 天）

### 3.1 新增 `AddProjectDialog`

**文件**: `lib/widgets/add_project_dialog.dart` (新增, ~100 行)

- [ ] **3.1.1** 创建 `AddProjectDialog` StatefulWidget
- [ ] **3.1.2** 包含一个 TextField 输入项目路径（hint: "输入项目目录路径"）
- [ ] **3.1.3** 确认按钮 → 回调返回路径字符串 / `Project` 对象
- [ ] **3.1.4** 取消按钮
- [ ] **3.1.5** 使用共享组件：`AppDialog` / `AppInputDecoration`
- [ ] **3.1.6** 输入校验：路径不能为空

### 3.2 添加项目 API 交互

**文件**: `lib/services/opencode_api.dart`

- [ ] **3.2.1** 确认 opencode 添加项目的 API 端点
  - 检查: `POST /project` 或 `POST /project/git/init`
  - 参考 opencode-dev 的 SDK: `Project.open(directory)`
- [ ] **3.2.2** 添加 `OpenCodeApi.addProject(String directory)` 方法
  ```dart
  Future<Project> addProject(String directory) async {
    final res = await _post('/project', body: {'worktree': directory});
    _check(res);
    return Project.fromJson(_safeMap(jsonDecode(res.body)));
  }
  ```
- [ ] **3.2.3** 添加 `OpenCodeApi.removeProject(String id)` 方法

### 3.3 集成添加项目到 UI

**文件**: `lib/widgets/main_scaffold.dart`

- [ ] **3.3.1** 「+」按钮点击 → 弹出 `AddProjectDialog`
- [ ] **3.3.2** 确认后调用 `_api.addProject(path)`
- [ ] **3.3.3** 成功后刷新项目列表 + 自动设为当前项目（`_switchProject`）

### 3.4 项目持久化

**文件**: `lib/utils/project_helpers.dart` (新增, ~60 行)

- [ ] **3.4.1** `saveProjectList(String serverId, List<Project> projects)` — 写入 SharedPreferences
- [ ] **3.4.2** `loadProjectList(String serverId)` — 从 SharedPreferences 读取
- [ ] **3.4.3** `projectListKey(String serverId)` → `'projects:$serverId'`
- [ ] **3.4.4** JSON 序列化/反序列化

### 3.5 关闭/删除项目

**文件**: `lib/screens/native/project_screen.dart`

- [ ] **3.5.1** 项目长按/右键菜单添加"关闭项目"选项
- [ ] **3.5.2** 确认后从项目列表移除（本地 + 提示服务端）
- [ ] **3.5.3** 移除后如果关闭的是当前项目，清除 `_activeProject`

---

## Phase 4: 会话按项目过滤（P1 ~1 天）

### 4.1 会话列表上下文指示

**文件**: `lib/screens/native/session_list_screen.dart`

- [ ] **4.1.1** 实现 `didUpdateWidget` 检测 `activeProject` 变化 → 自动 `_load()`
- [ ] **4.1.2** 会话列表为空时区分两种情况：
  - 无项目 → 空状态："暂无会话"
  - 有项目 → 空状态："'项目名' 中暂无会话"
- [ ] **4.1.3** 切换项目后保留会话搜索状态

### 4.2 验证 API directory 过滤

- [ ] **4.2.1** 确认 `_buildUri` 追加的 `directory` 参数被服务端正确解析
- [ ] **4.2.2** 测试：切换项目后 `getSessions()` 返回的确实是该项目的会话
- [ ] **4.2.3** 如果服务端不支持按 directory 过滤 session，改为客户端过滤

---

## Phase 5: 项目搜索（P1 ~1 天）

### 5.1 ProjectScreen 搜索

**文件**: `lib/screens/native/project_screen.dart`

- [ ] **5.1.1** AppBar 下方添加 `TextField` 搜索框（`AppInputDecoration.search`）
- [ ] **5.1.2** 输入文字时实时过滤 `_projects` 列表
  - 匹配: `project.name` 包含关键词 OR `project.path` 包含关键词
- [ ] **5.1.3** 搜索无结果时显示 `AppEmptyState`
- [ ] **5.1.4** 清除搜索按钮

### 5.2 侧栏搜索（可选增强）

**文件**: `lib/widgets/project_sidebar.dart`

- [ ] **5.2.1** 项目 rail 顶部添加小搜索按钮（或搜索图标）
- [ ] **5.2.2** 点击展开搜索框，过滤项目头像列表

---

## Phase 6: Workspace（Git 分支）管理（P1-P2 ~1 天）

### 6.1 新增 `WorkspaceList` 组件

**文件**: `lib/widgets/workspace_list.dart` (新增, ~120 行)

- [ ] **6.1.1** 创建 `WorkspaceList` 折叠/展开组件
- [ ] **6.1.2** 标题显示"分支" + 当前分支名 + 展开/折叠图标
- [ ] **6.1.3** 展开后调用 `GET /workspace/list` 获取分支列表
- [ ] **6.1.4** 每个分支项：分支名 + 当前分支标记 + 会话数（如有）
- [ ] **6.1.5** 点击非当前分支 → 切换分支
- [ ] **6.1.6** 使用 `AppColors` 常量，符合组件规范

### 6.2 集成 WorkspaceList

- [ ] **6.2.1** 在 `ProjectScreen` 的项目详情 BottomSheet 中集成 `WorkspaceList`
- [ ] **6.2.2** 切换分支后更新 `api.directory` 和 `activeProject`（如适用）

### 6.3 验证 Workspace API

- [ ] **6.3.1** 确认 `GET /workspace/list` 在服务端可用
- [ ] **6.3.2** 如果不可用，降级为只显示当前分支名（现有功能回归）

---

## Phase 7: 拖拽排序与持久化（P2-P3 ~1.5 天）

### 7.1 ProjectScreen 拖拽排序

**文件**: `lib/screens/native/project_screen.dart`

- [ ] **7.1.1** 将项目列表改为 `ReorderableListView`
- [ ] **7.1.2** 拖拽结束后保存新顺序到本地（`project_helpers.dart`）
- [ ] **7.1.3** 侧栏项目 rail 的顺序同步更新

### 7.2 侧栏项目排序同步

**文件**: `lib/widgets/main_scaffold.dart`

- [ ] **7.2.1** `_projects` 列表在加载时自动应用本地持久化的排序
- [ ] **7.2.2** 项目添加/删除后更新排序数据
- [ ] **7.2.3** 多服务器独立排序：key 为 `'project_order:$serverId'`

---

## 字符串与主题更新

### S8 更新 strings.dart

**文件**: `lib/strings.dart`

- [ ] **S8.1** 添加以下字符串常量：
  ```dart
  // Project (新增或增强)
  static const allSessions = '全部会话';
  static const noActiveProject = '选择一个项目开始';
  static const addProject = '添加项目';
  static const projectPathHint = '输入项目目录路径';
  static const closeProject = '关闭项目';
  static const confirmCloseProject = '确定关闭该项目？';
  static const projectAdded = '项目已添加';
  static const projectRemoved = '项目已关闭';
  static const searchProjects = '搜索项目...';
  static const workspaces = '分支';
  static const switchBranch = '切换分支';
  static const noWorkspaces = '无分支信息';
  static const sessionInProject = '\'{name}\' 中暂无会话';
  ```

### S9 更新 theme.dart（如需要）

- [ ] **S9.1** 新增项目头像相关颜色常量（如 `projectAvatarBg`）
- [ ] **S9.2** 确认现有常量足够覆盖新组件需求

---

## 验收标准

每个 Phase 完成后验证以下场景：

### 基本流程验收

- [ ] **A1.** 启动 app → 连接服务器 → 侧栏自动显示项目头像列表
- [ ] **A2.** 点击项目头像 → 立即切换 → Dashboard/Sessions 显示对应项目内容
- [ ] **A3.** 点击「+」→ 输入路径 → 添加项目 → 出现在侧栏
- [ ] **A4.** 长按项目头像 → 弹出上下文菜单 → 关闭项目
- [ ] **A5.** 切换服务器 → 项目列表独立存储和恢复
- [ ] **A6.** 重启 app → 项目列表持久化恢复

### 回归验收

- [ ] **R1.** 无项目时，所有页面保持现有行为（不崩溃）
- [ ] **R2.** 会话创建/聊天/发送消息不受影响
- [ ] **R3.** 文件浏览不受影响
- [ ] **R4.** 暗色/亮色主题切换后新组件正常显示

---

## 执行顺序建议

```
Week 1:
  Day 1-3:  Phase 1 (M1) — 项目侧栏 + ProjectAvatar + MainScaffold 重构
  Day 4-5:  Phase 2 (M2) — 全局项目上下文传递

Week 2:
  Day 1:    Phase 3 (M3) — 添加项目对话框 + API + 持久化
  Day 2:    Phase 4 (M4) — 会话按项目过滤
  Day 3-4:  Phase 5-6 — 项目搜索 + Workspace 管理
  Day 5:    Phase 7 — 拖拽排序 + 收尾测试
```

## 依赖关系

```
Phase 1 ──→ Phase 2 ──→ Phase 4
   │                      │
   └──→ Phase 3 ──────────┤
                           │
Phase 5 (可独立)           │
Phase 6 (依赖 Phase 1)    │
Phase 7 (依赖 Phase 1+3) ─┘
```
