/// Centralized UI strings for the opencode-remote app.
///
/// All user-facing text MUST use these constants instead of inline literals.
/// This enables future i18n via flutter_localizations.
class S {
  S._();

  // === General ===
  static const copied = '已复制';
  static const thinkingProcess = '思考过程';
  static const cancel = '取消';
  static const confirm = '确定';
  static const save = '保存';
  static const loading = '加载中...';
  static const retry = '重试';
  static const settings = '设置';
  static const search = '搜索';
  static const refresh = '刷新';
  static const close = '关闭';
  static const ok = 'OK';
  static const done = '完成';
  static const back = '返回';
  static const create = '创建';
  static const edit = '编辑';
  static const delete = '删除';
  static const rename = '重命名';
  static const abort = '中止';
  static const share = '分享';
  static const fork = '分叉';
  static const diff = '查看差异';
  static const summarize = '总结';

  // === Session ===
  static const newSession = '新建会话';
  static const createEmptySession = '创建空会话';
  static const sessionTitleHint = '会话标题（可选）';
  static const noSessions = '暂无会话';
  static const noMatchingSessions = '无匹配会话';
  static const searchSessionTitle = '搜索会话标题...';
  static const noChildSessions = '无子会话';
  static const noTodos = '无待办事项';
  static const childSessions = '子会话';
  static const todoList = '待办列表';
  static const startConversation = 'Start a conversation';
  static const unnamedSession = '未命名会话';
  static const createFailed = '创建失败';
  static const sessionAborted = '会话已中止';
  static const abortFailed = '中止失败';
  static const shared = '已分享';
  static const unshared = '已取消分享';
  static const shareFailed = '分享失败';

  // === Chat ===
  static const sendFailed = '发送失败';
  static const messageActions = '消息操作';
  static const copyContent = '复制内容';
  static const selectAgent = '选择 Agent';
  static const selectModel = '选择模型';
  static const addAttachment = '添加附件';
  static const runShellCommand = '运行 Shell 命令';
  static const applyCodeToFile = '应用代码到文件';
  static const enterMessage = '输入消息... (/ 查看命令)';
  static const enterShellCommand = '输入 shell 命令...';
  static const allowOnce = '允许一次';
  static const alwaysAllow = '始终允许';
  static const deny = '拒绝';
  static const permissionRequest = '权限请求';
  static const question = '问题';

  // === Navigation Tabs ===
  static const dashboard = '仪表';
  static const sessions = '会话';
  static const files = '文件';

  // === Model Picker ===
  static const noMatchModel = '无匹配模型';
  static const searchModelHint = '搜索模型...';

  // === Server ===
  static const servers = '服务器';
  static const noServers = '还没有服务器';
  static const clickToAdd = '点击 + 添加';
  static const switchServer = '切换服务器';
  static const addNewServer = '添加新服务器';
  static const addServer = '添加服务器';
  static const editServer = '编辑服务器';
  static const connectionFailed = '连接失败';
  static const instanceDisposed = '实例已销毁';
  static const lastUsed = '最后使用:';
  static const name = '名称';
  static const address = '地址';
  static const port = '端口';
  static const username = '用户名';
  static const password = '密码';
  static const nameHint = '家里PC';
  static const addressHint = '10.10.10.216';
  static const portHint = '4096';
  static const usernameHint = 'opencode';
  static const passwordHint = '';

  // === Mode / Theme ===
  static const runMode = '运行模式';
  static const theme = '主题';
  static const about = '关于';
  static const webviewMode = 'WebView 模式';
  static const nativeMode = '原生模式';
  static const light = '浅色';
  static const dark = '深色';
  static const followSystem = '跟随系统';
  static const webviewDesc = '通过浏览器界面远程控制';
  static const nativeDesc = '使用原生 Flutter 界面';
  static const chooseMode = '选择你偏好的运行模式';

  // === Project ===
  static const project = '项目';
  static const addProject = '添加项目';
  static const currentProject = '当前项目';
  static const allProjects = '所有项目';
  static const noProjects = '暂无项目';
  static const path = '路径';
  static const projectPathHint = '输入项目目录路径';
  static const add = '添加';
  static const pathNotEmpty = '路径不能为空';
  static const addFailed = '添加失败';
  static const id = 'ID';
  static const switchToProject = '切换到该项目';
  static const switchedTo = '已切换到:';
  static const allSessions = '全部会话';
  static const noActiveProject = '选择一个项目开始';
  static const closeProject = '关闭项目';
  static const confirmCloseProject = '确定关闭该项目？';
  static const projectAdded = '项目已添加';
  static const projectRemoved = '项目已关闭';
  static const searchProjects = '搜索项目...';
  static const workspaces = '分支';
  static const switchBranch = '切换分支';
  static const noWorkspaces = '无分支信息';

  // === File Browser ===
  static const fileBrowser = '文件浏览';
  static const searchFiles = '搜索文件、内容或符号';
  static const searchKeyword = '输入搜索关键词';
  static const fileName = '文件名';
  static const content = '内容';
  static const symbol = '符号';
  static const emptyDir = '空目录';
  static const readFailed = '读取失败';
  static const searchFailed = '搜索失败';
  static const loadFailed = '加载失败';
  static const imagePreviewHint = '图片预览需要在服务端配置后可用';

  // === Terminal ===
  static const terminal = 'Terminal';
  static const clear = '清除';
  static const terminalTitle = 'OpenCode Remote Terminal';
  static const initializing = '初始化中...';
  static const ready = 'Ready. Type a command.';

  // === Tool ===
  static const failed = '失败';
  static const inProgress = '进行中';
  static const completed = '完成';
  static const waiting = '等待';
  static const diagnostics = '诊断';

  static const revertMessage = 'Revert Message';
  static const viewDetails = 'View Details';
  static const forkFromHere = 'Fork from Here';
  static const restoreReverted = 'Restore Reverted';
  static const shellCommand = 'Shell Command';
  static const image = 'Image';
  static const camera = 'Camera';
  static const file = 'File';

  // === Config ===
  static const diagnosticsAndConfig = '诊断与配置';
  static const addUpdateConfig = '添加/更新配置';
  static const configKey = '配置键';
  static const configValue = '配置值';
  static const configUpdated = '配置已更新';
  static const updateFailed = '更新失败';
  static const lspServer = 'LSP 服务器';
  static const formatter = '格式化器';
  static const mcpServer = 'MCP 服务器';
  static const defaultModel = '默认模型:';
  static const noDefaultModel = '无默认模型';
  static const noAuthInfo = '无认证信息';
  static const authSet = '认证已设置';

  // === Dashboard ===
  static const recentSessions = '最近会话';
  static const viewAll = '查看全部';
  static const quickActions = '快捷操作';
  static const connected = '已连接';
  static const unableToConnect = '无法连接';
  static const online = '在线';
  static const offline = '离线';
  static const logWritten = '日志已写入';
  static const disposeInstance = '销毁实例';
  static const writeDiagnosticLog = '写入诊断日志';
  static String disposeFailed(Object e) => '销毁失败: $e';

  // === Auth ===
  static const setAuth = '设置认证';
  static const providerIdHint = 'provider ID (如 openai)';
  static const apiKey = 'API Key';
  static const apiKeyHint = 'sk-...';
  static String setAuthFailed(Object e) => '设置认证失败: $e';

  // === Session (additional) ===
  static const unnamed = '未命名';
  static const newTitle = '新标题';
  static const stopSharing = '停止分享';
  static const noDiffs = '暂无差异';
  static const deleteSession = '删除会话';
  static const forkSession = '分叉会话';
  static const forkSessionConfirm = '从最新消息分叉一个新会话？';
  static const forkedAsNew = '已分叉为新会话';
  static const summarizeDone = '总结完成';
  static String diffTitle(Object title) => '差异: $title';
  static String diffFailed(Object e) => '获取差异失败: $e';
  static String summarizeFailed(Object e) => '总结失败: $e';
  static String forkFailed(Object e) => '分叉失败: $e';
  static String confirmDeleteSession(Object title) => '确定删除"$title"？';
  static String deleteFailed(Object e) => '删除失败: $e';
  static String unshareFailed(Object e) => '取消失败: $e';
  static String childSessionsFailed(Object e) => '获取子会话失败: $e';
  static String todoFailed(Object e) => '获取待办失败: $e';
  static String renameFailed(Object e) => '重命名失败: $e';

  // === Onboarding ===
  static const appTitle = 'OpenCode Remote';
  static const appVersion = 'v1.0.0';
}
