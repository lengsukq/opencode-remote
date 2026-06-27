# TODO: 项目核心功能对齐 Web 端体验

> 基于 `prd.md` 的详细实现清单  
> **总预估**: ~10 天  
> **实际完成**: ~8 天  
> **状态**: 大部分已完成，剩余 Phase 7 (拖拽排序, P2-P3)

---

## Phase 1: 项目侧栏与快捷切换（P0 ~3 天）

### 1.1 新增 `ProjectAvatar` 小组件

**文件**: `lib/widgets/project_avatar.dart` (新增, ~80 行)

- [x] **1.1.1** 创建 `ProjectAvatar` StatelessWidget
  - 参数: `Project project`, `bool isActive`, `VoidCallback? onTap`
  - 显示为首字母圆形头像（`project.name[0]`）
  - 激活状态高亮边框（`AppColors.primary`）
  - 当前项目 badge（"当前" 标记）
- [ ] **1.1.2** 添加在线/活动状态指示点（可选，`Project` 模型无此字段时可暂时留空）
- [x] **1.1.3** 正确使用 `AppColors` 常量，不使用硬编码颜色
- [x] **1.1.4** 触摸目标 ≥ 44px

### 1.2 重构 `MainScaffold` — NavigationRail 集成项目 rail

**文件**: `lib/widgets/main_scaffold.dart` (大改)

- [x] **1.2.1** 添加 `_projects` 列表加载 + `_activeProject` 状态
- [x] **1.2.2** 在 `initState` 中异步加载项目列表（`_api.getProjects()`）
- [x] **1.2.3** 修改 `NavigationRail` 的结构：
  - 移除原有的「项目」`NavigationRailDestination`
  - 在 `NavigationRail` 的 `leading` 和 `destinations` 之间插入项目头像区域（可滚动）
- [x] **1.2.4** 项目头像区域：每个 `ProjectAvatar` 占一个 slot
  - 点击头像 → `_switchProject(project)`
  - 当前项目高亮
- [x] **1.2.5** 添加 `_switchProject(Project)` 方法
- [x] **1.2.6** 在 rail 底部、设置齿轮上方添加「+」按钮（`Icons.add_circle_outline`）
- [x] **1.2.7** 添加 `VoidCallback onAddProject` 用于后续与 Phase 3 联动
- [x] **1.2.8** 项目 > 4 个时 rail 区域可滚动

### 1.3 传递 `activeProject` 到子页面

**文件**: `lib/widgets/main_scaffold.dart`

- [x] **1.3.1** 修改 `_buildPage()` 方法，将所有子页面构造参数加上 `activeProject`：
  - [x] DashboardScreen 接收 `activeProject`
  - [x] SessionListScreen 接收 `activeProject`
  - [x] FileBrowserScreen 接收 `activeProject`
  - [x] ChatScreen（push 时传递）

### 1.4 移除旧的 ProjectScreen Tab 导航

- [x] **1.4.1** 项目 rail 已覆盖快捷切换功能后，保留 ProjectScreen 作为"项目管理"详细页面
- [x] **1.4.2** ProjectScreen 仍然可通过其他方式进入

---

## Phase 2: 全局项目上下文系统（P0 ~2 天）

### 2.1 SessionListScreen 项目上下文

**文件**: `lib/screens/native/session_list_screen.dart`

- [x] **2.1.1** 构造函数添加 `Project? activeProject` 参数
- [x] **2.1.2** AppBar title 动态显示：
  - 有 `activeProject` → `"${activeProject.name} / 会话"`
  - 无 `activeProject` → `"会话"`
- [x] **2.1.3** 当 `activeProject` 变化时（通过 `didUpdateWidget` 检测）自动调用 `_load()` 刷新
- [x] **2.1.4** 无项目上下文时保持现有行为（显示全部会话）

### 2.2 DashboardScreen 项目上下文

**文件**: `lib/screens/native/dashboard_screen.dart`

- [x] **2.2.1** 构造函数添加 `Project? activeProject` 参数
- [x] **2.2.2** 显示当前项目名称在 Dashboard 顶部
- [x] **2.2.3** 最近会话列表只显示当前项目下的会话
- [x] **2.2.4** 无项目时显示提示"选择一个项目开始"

### 2.3 FileBrowserScreen 项目上下文

**文件**: `lib/screens/native/file_browser_screen.dart`

- [x] **2.3.1** 构造函数添加 `Project? activeProject` 参数
- [x] **2.3.2** 初始 root 路径跟随 `activeProject.path`（有项目时）
- [x] **2.3.3** AppBar 显示"项目名 / 文件"

### 2.4 ChatScreen 项目上下文

**文件**: `lib/screens/native/chat_screen.dart`

- [x] **2.4.1** push ChatScreen 时传入 `activeProject`
- [x] **2.4.2** AppBar title 显示项目名

---

## Phase 3: 添加项目功能（P0 ~1.5 天）

### 3.1 新增 `AddProjectDialog`

**文件**: `lib/widgets/add_project_dialog.dart` (新增, ~100 行)

- [x] **3.1.1** 创建 `AddProjectDialog` StatefulWidget
- [x] **3.1.2** 包含一个 TextField 输入项目路径
- [x] **3.1.3** 确认按钮 → 回调返回 Project 对象
- [x] **3.1.4** 取消按钮
- [x] **3.1.5** 使用共享组件：`AppDialog` / `AppInputDecoration`
- [x] **3.1.6** 输入校验：路径不能为空

### 3.2 添加项目 API 交互

**文件**: `lib/services/opencode_api.dart`

- [x] **3.2.1** 确认 opencode 添加项目的 API 端点
- [x] **3.2.2** 添加 `OpenCodeApi.addProject(String directory)` 方法
- [x] **3.2.3** 添加 `OpenCodeApi.removeProject(String id)` 方法

### 3.3 集成添加项目到 UI

**文件**: `lib/widgets/main_scaffold.dart`

- [x] **3.3.1** 「+」按钮点击 → 弹出 `AddProjectDialog`
- [x] **3.3.2** 确认后调用 `_api.addProject(path)`
- [x] **3.3.3** 成功后刷新项目列表 + 自动设为当前项目（`_switchProject`）

### 3.4 项目持久化

**文件**: `lib/utils/project_helpers.dart` (新增, ~60 行)

- [x] **3.4.1** `saveProjects()` — 写入 SharedPreferences
- [x] **3.4.2** `loadProjects()` — 从 SharedPreferences 读取
- [x] **3.4.3** `projectListKey(String serverId)` → `'projects:$serverId'`
- [x] **3.4.4** JSON 序列化/反序列化

### 3.5 关闭/删除项目

**文件**: `lib/screens/native/project_screen.dart`

- [x] **3.5.1** 项目长按菜单添加"关闭项目"选项
- [x] **3.5.2** 确认后从项目列表移除
- [x] **3.5.3** 移除后如果关闭的是当前项目，清除 `_activeProject`

---

## Phase 4: 会话按项目过滤（P1 ~1 天）

### 4.1 会话列表上下文指示

**文件**: `lib/screens/native/session_list_screen.dart`

- [x] **4.1.1** 实现 `didUpdateWidget` 检测 `activeProject` 变化 → 自动 `_load()`
- [x] **4.1.2** 会话列表为空时区分两种情况
- [x] **4.1.3** 切换项目后保留会话搜索状态

### 4.2 验证 API directory 过滤

- [x] **4.2.1** `_buildUri` 追加的 `directory` 参数被服务端正确解析
- [x] **4.2.2** 切换项目后 `getSessions()` 返回该项目的会话（服务端过滤）
- [ ] **4.2.3** 如果服务端不支持按 directory 过滤 session，改为客户端过滤（待验证）

---

## Phase 5: 项目搜索（P1 ~1 天）

### 5.1 ProjectScreen 搜索

**文件**: `lib/screens/native/project_screen.dart`

- [x] **5.1.1** AppBar 下方添加 `TextField` 搜索框
- [x] **5.1.2** 输入文字时实时过滤 `_projects` 列表
- [x] **5.1.3** 搜索无结果时显示 `AppEmptyState`
- [x] **5.1.4** 清除搜索按钮

### 5.2 侧栏搜索（可选增强）

- [ ] **5.2.1** 项目 rail 顶部添加小搜索按钮（可选，低优先级）
- [ ] **5.2.2** 点击展开搜索框（可选，低优先级）

---

## Phase 6: Workspace（Git 分支）管理（P1-P2 ~1 天）

### 6.1 新增 `WorkspaceList` 组件

**文件**: `lib/widgets/workspace_list.dart` (新增, ~120 行)

- [x] **6.1.1** 创建 `WorkspaceList` 折叠/展开组件
- [x] **6.1.2** 标题显示"分支" + 当前分支名 + 展开/折叠图标
- [x] **6.1.3** 展开后调用 `GET /workspace/list` 获取分支列表
- [x] **6.1.4** 每个分支项：分支名 + 当前分支标记
- [x] **6.1.5** 点击非当前分支 → 切换分支
- [x] **6.1.6** 使用 `AppColors` 常量，符合组件规范

### 6.2 集成 WorkspaceList

- [x] **6.2.1** 在 `MainScaffold` 中集成 `WorkspaceList`
- [ ] **6.2.2** 切换分支后更新 `api.directory` 和 `activeProject`（待确认完整流程）

### 6.3 验证 Workspace API

- [x] **6.3.1** `GET /workspace/list` 已对接
- [x] **6.3.2** 不可用时降级为只显示当前分支名

---

## Phase 7: 拖拽排序与持久化（P2-P3 ~1.5 天）

### 7.1 ProjectScreen 拖拽排序

- [ ] **7.1.1** 将项目列表改为 `ReorderableListView`（待实现）
- [ ] **7.1.2** 拖拽结束后保存新顺序到本地（待实现）
- [ ] **7.1.3** 侧栏项目 rail 的顺序同步更新（待实现）

### 7.2 侧栏项目排序同步

- [ ] **7.2.1** 排序持久化（待实现）
- [ ] **7.2.2** 项目添加/删除后更新排序数据（待实现）
- [ ] **7.2.3** 多服务器独立排序（待实现）

---

## 字符串与主题更新

### S8 更新 strings.dart

**文件**: `lib/strings.dart`

- [x] **S8.1** 添加以下字符串常量：
  - `allSessions` 全部会话 ✅
  - `noActiveProject` 选择一个项目开始 ✅
  - `addProject` 添加项目 ✅
  - `projectPathHint` 输入项目目录路径 ✅
  - `closeProject` 关闭项目 ✅
  - `confirmCloseProject` 确定关闭该项目？✅
  - `projectAdded` 项目已添加 ✅
  - `projectRemoved` 项目已关闭 ✅
  - `searchProjects` 搜索项目... ✅
  - `workspaces` 分支 ✅
  - `switchBranch` 切换分支 ✅
  - `noWorkspaces` 无分支信息 ✅
  - `sessionInProject` '{name}' 中暂无会话 ✅

### S9 更新 theme.dart（如需要）

- [ ] **S9.1** 新增项目头像相关颜色常量（现有常量已足够覆盖）
- [x] **S9.2** 确认现有常量足够覆盖新组件需求 ✅

---

## 验收标准

### 基本流程验收

- [x] **A1.** 启动 app → 连接服务器 → 侧栏自动显示项目头像列表 ✅
- [x] **A2.** 点击项目头像 → 立即切换 → Dashboard/Sessions 显示对应项目内容 ✅
- [x] **A3.** 点击「+」→ 输入路径 → 添加项目 → 出现在侧栏 ✅
- [x] **A4.** 长按项目头像 → 弹出上下文菜单 → 关闭项目 ✅
- [x] **A5.** 切换服务器 → 项目列表独立存储和恢复 ✅
- [x] **A6.** 重启 app → 项目列表持久化恢复 ✅

### 回归验收

- [x] **R1.** 无项目时，所有页面保持现有行为（不崩溃）✅
- [x] **R2.** 会话创建/聊天/发送消息不受影响 ✅
- [x] **R3.** 文件浏览不受影响 ✅
- [x] **R4.** 暗色/亮色主题切换后新组件正常显示 ✅
