import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:image_picker/image_picker.dart';
import '../../models.dart';
import '../../theme.dart';
import '../../services/opencode_api.dart';
import '../../services/event_service.dart';
import '../../utils/time_format.dart';
import '../../widgets/diff_view.dart';

class ChatScreen extends StatefulWidget {
  final Session session;
  final ServerEntry entry;
  final OpenCodeApi api;

  const ChatScreen({
    super.key,
    required this.session,
    required this.entry,
    required this.api,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<Message> _messages = [];
  List<Agent> _agents = [];
  List<Provider> _providers = [];
  List<Command> _commands = [];
  bool _loading = true;
  String? _error;
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _sending = false;
  String? _selectedAgent;
  String? _selectedModel;
  bool _showCommands = false;
  List<Command> _filteredCommands = [];
  EventService? _eventService;
  StreamSubscription<ServerEvent>? _eventSub;
  final Map<String, String> _streamingDeltas = {};
  final Map<String, Map<String, dynamic>> _streamingToolStates = {};
  List<Map<String, dynamic>> _attachments = [];
  List<String> _inputHistory = [];
  int _historyIndex = -1;
  bool _shellMode = false;
  List<Todo> _todos = [];

  @override
  void initState() {
    super.initState();
    _load();
    _connectEvents();
    _inputCtrl.addListener(_onInputChanged);
  }

  Future<void> _createNewSession() async {
    try {
      final session = await widget.api.createSession();
      if (!mounted) return;
      await Navigator.pushReplacement(context, MaterialPageRoute(
        builder: (_) => ChatScreen(session: session, entry: widget.entry, api: widget.api),
      ));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('创建会话失败: $e')));
      }
    }
  }

  @override
  void dispose() {
    _inputCtrl.removeListener(_onInputChanged);
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    _eventSub?.cancel();
    _eventService?.dispose();
    super.dispose();
  }

  void _connectEvents() {
    _eventSub?.cancel();
    _eventService?.dispose();
    _eventService = EventService(
      baseUrl: widget.entry.url,
      username: widget.entry.username,
      password: widget.entry.password,
    );
    _eventService!.connect();
    _eventSub = _eventService!.events.listen(
      (event) {
        switch (event.type) {
          case EventType.messageNew:
          case EventType.sessionUpdated:
            _streamingDeltas.clear();
            _refreshMessages();
          case EventType.messagePartDelta:
            _handleDelta(event.data);
          case EventType.permissionAsked:
            _handlePermission(event.data);
          case EventType.questionAsked:
            _handleQuestion(event.data);
          default:
            break;
        }
      },
      onError: (e) => debugPrint('ChatScreen event error: $e'),
      cancelOnError: false,
    );
  }

  void _handleDelta(Map<String, dynamic> data) {
    final props = (data['payload'] is Map ? data['payload']['properties'] : data['properties']) as Map<String, dynamic>?;
    if (props == null) return;
    final partID = props['partID'] as String?;
    final field = props['field'] as String?;
    final delta = props['delta'] as String?;
    if (partID == null) return;

    if (field == 'text' && delta != null) {
      _streamingDeltas[partID] = (_streamingDeltas[partID] ?? '') + delta;
    } else if (field == 'state.status' && delta != null) {
      _streamingToolStates[partID] = {...?_streamingToolStates[partID], 'status': delta};
    } else if (field == 'state.output' && delta != null) {
      final existing = (_streamingToolStates[partID]?['output'] as String? ?? '') + delta;
      _streamingToolStates[partID] = {...?_streamingToolStates[partID], 'output': existing};
    } else if (field == 'state.error' && delta != null) {
      _streamingToolStates[partID] = {...?_streamingToolStates[partID], 'error': delta};
    } else if (field == 'state.title' && delta != null) {
      _streamingToolStates[partID] = {...?_streamingToolStates[partID], 'title': delta};
    }
    if (mounted) setState(() {});
  }

  void _handlePermission(Map<String, dynamic> data) {
    if (!mounted) return;
    final props = (data['payload'] is Map ? data['payload']['properties'] : data['properties']) as Map<String, dynamic>?;
    if (props == null) return;
    final permissionID = data['id'] as String?;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('权限请求', style: TextStyle(color: AppColors.textPrimary)),
        content: Text('${props['message'] ?? '允许此操作？'}', style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (permissionID != null) {
                widget.api.executeCommand(widget.session.id, command: 'permission', arguments: ['deny', permissionID]);
              }
            },
            child: Text('拒绝', style: TextStyle(color: AppColors.danger)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (permissionID != null) {
                widget.api.executeCommand(widget.session.id, command: 'permission', arguments: ['approve', permissionID, '--remember']);
              }
            },
            child: Text('始终允许', style: TextStyle(color: AppColors.warning)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              Navigator.pop(ctx);
              if (permissionID != null) {
                widget.api.executeCommand(widget.session.id, command: 'permission', arguments: ['approve', permissionID]);
              }
            },
            child: Text('一次允许'),
          ),
        ],
      ),
    );
  }

  void _handleQuestion(Map<String, dynamic> data) {
    if (!mounted) return;
    final props = (data['payload'] is Map ? data['payload']['properties'] : data['properties']) as Map<String, dynamic>?;
    if (props == null) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('问题', style: TextStyle(color: AppColors.textPrimary)),
        content: Text('${props['message'] ?? props['question'] ?? ''}', style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('取消', style: TextStyle(color: AppColors.textSecondary))),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => Navigator.pop(ctx),
            child: Text('确定'),
          ),
        ],
      ),
    );
  }

  void _onInputChanged() {
    final text = _inputCtrl.text;
    final isShell = text.startsWith('!') && !text.startsWith('!/');
    if (isShell != _shellMode) setState(() => _shellMode = isShell);
    if (text.startsWith('/') && text.length > 1) {
      final query = text.substring(1).toLowerCase();
      setState(() {
        _showCommands = true;
        _filteredCommands = _commands
            .where((c) => c.id.toLowerCase().contains(query) || c.title.toLowerCase().contains(query))
            .toList();
      });
    } else if (text.isEmpty || !text.startsWith('/')) {
      setState(() => _showCommands = false);
    }
    if (text.isEmpty) _historyIndex = _inputHistory.length;
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    try {
      final results = await Future.wait([
        widget.api.getMessages(widget.session.id),
        widget.api.getAgents(),
        widget.api.getProviders(),
        widget.api.getCommands(),
        widget.api.getConfigProviders(),
      ]);
      final msgs = results[0] as List<Message>;
      final agents = results[1] as List<Agent>;
      final providers = results[2] as List<Provider>;
      final commands = results[3] as List<Command>;
      final configData = results[4] as Map<String, dynamic>;
      final rawDefaults = configData['default'];
      final defaults = (rawDefaults is Map)
          ? (rawDefaults as Map<String, dynamic>).map((k, v) => MapEntry(k, v?.toString() ?? ''))
          : <String, String>{};

      String? autoModel;
      if (msgs.isNotEmpty) {
        final last = msgs.lastWhere((m) => m.model != null, orElse: () => msgs.last);
        autoModel = last.model;
      }
      autoModel ??= defaults['build'];

      if (!mounted) return;
      setState(() {
        _messages = msgs;
        _agents = agents;
        _providers = providers;
        _commands = commands;
        _selectedModel ??= autoModel;
        if (_selectedAgent == null && _agents.isNotEmpty) {
          final buildAgent = _agents.where((a) => a.name == 'build').firstOrNull;
          _selectedAgent = buildAgent?.name ?? _agents.first.name;
        }
        _loading = false;
        _error = null;
      });
      _scrollToBottom();
      _loadTodos();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _loadTodos() async {
    try {
      final todos = await widget.api.getSessionTodo(widget.session.id);
      if (mounted) setState(() => _todos = todos);
    } catch (_) {}
  }

  Future<void> _sendMessage() async {
    var text = _inputCtrl.text.trim();
    if (text.isEmpty) return;
    _inputCtrl.clear();
    setState(() {
      _sending = true;
      _showCommands = false;
    });

    final isShellCmd = _shellMode && text.startsWith('!');
    if (isShellCmd) text = text.substring(1).trim();

    try {
      if (isShellCmd) {
        await widget.api.runShell(widget.session.id, command: text, agent: _selectedAgent, model: _selectedModel);
      } else if (text.startsWith('/')) {
        final parts = text.substring(1).split(' ');
        final cmd = parts.first;
        final args = parts.skip(1).toList();
        await widget.api.executeCommand(widget.session.id, command: cmd, arguments: args, agent: _selectedAgent, model: _selectedModel);
      } else {
        try {
          final allParts = <Map<String, dynamic>>[
            {'type': 'text', 'text': text},
            ..._attachments,
          ];
          await widget.api.sendMessageAsync(
            widget.session.id,
            content: text,
            parts: allParts,
            agent: _selectedAgent,
            model: _selectedModel,
          );
        } catch (_) {
          final allParts = <Map<String, dynamic>>[
            {'type': 'text', 'text': text},
            ..._attachments,
          ];
          await widget.api.sendMessage(widget.session.id, content: text, parts: allParts, agent: _selectedAgent, model: _selectedModel);
        }
      }
      _inputHistory.add(text);
      if (_inputHistory.length > 100) _inputHistory.removeAt(0);
      _historyIndex = _inputHistory.length;
      _attachments = [];
      await _refreshMessages();
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.surface,
            title: const Text('发送失败', style: TextStyle(color: AppColors.textPrimary)),
            content: Text('$e', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            actions: [
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('确定'),
              ),
            ],
          ),
        );
        setState(() => _sending = false);
      }
    }
  }

  Future<void> _abortRequest() async {
    try {
      await widget.api.abortSession(widget.session.id);
      setState(() => _sending = false);
      await _refreshMessages();
    } catch (e) {
      debugPrint('ChatScreen._abortRequest: $e');
      setState(() => _sending = false);
    }
  }

  void _navigateHistory(int direction) {
    if (_inputHistory.isEmpty) return;
    final newIndex = (_historyIndex + direction).clamp(-1, _inputHistory.length - 1);
    if (newIndex == _historyIndex) return;
    _historyIndex = newIndex;
    if (newIndex == -1) {
      _inputCtrl.clear();
    } else {
      _inputCtrl.text = _inputHistory[newIndex];
      _inputCtrl.selection = TextSelection.collapsed(offset: _inputCtrl.text.length);
    }
  }

  Future<void> _pickAttachment() async {
    final source = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('添加附件', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.image, color: AppColors.primary),
              title: const Text('图片', style: TextStyle(color: AppColors.textPrimary)),
              subtitle: Text('从相册选择', style: TextStyle(color: AppColors.textTertiary, fontSize: 12)),
              onTap: () => Navigator.pop(ctx, 'image'),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.primary),
              title: const Text('拍照', style: TextStyle(color: AppColors.textPrimary)),
              subtitle: Text('使用相机拍摄', style: TextStyle(color: AppColors.textTertiary, fontSize: 12)),
              onTap: () => Navigator.pop(ctx, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.attach_file, color: AppColors.primary),
              title: const Text('文件', style: TextStyle(color: AppColors.textPrimary)),
              subtitle: Text('从本地存储选择', style: TextStyle(color: AppColors.textTertiary, fontSize: 12)),
              onTap: () => Navigator.pop(ctx, 'file'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source == null) return;
    try {
      switch (source) {
        case 'image':
          final picker = ImagePicker();
          final xFile = await picker.pickImage(source: ImageSource.gallery);
          if (xFile == null) return;
          await _addImageAttachment(xFile);
        case 'camera':
          final picker = ImagePicker();
          final xFile = await picker.pickImage(source: ImageSource.camera);
          if (xFile == null) return;
          await _addImageAttachment(xFile);
        case 'file':
          final result = await FilePicker.platform.pickFiles();
          if (result == null || result.files.isEmpty) return;
          await _addFileAttachment(result.files.first);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('选择附件失败: $e')));
      }
    }
  }

  Future<void> _addImageAttachment(XFile xFile) async {
    final bytes = await xFile.readAsBytes();
    final b64 = base64Encode(bytes);
    final name = xFile.name;
    final ext = name.split('.').last.toLowerCase();
    final mime = _mimeFromExt(ext);
    if (mounted) setState(() {
      _attachments.add({
        'type': 'file',
        'mime': mime,
        'url': 'data:$mime;base64,$b64',
        'filename': name,
      });
    });
  }

  Future<void> _addFileAttachment(PlatformFile file) async {
    Uint8List? bytes = file.bytes;
    if (bytes == null) return;
    final b64 = base64Encode(bytes);
    final ext = file.name.split('.').last.toLowerCase();
    final mime = _mimeFromExt(ext);
    if (mounted) setState(() {
      _attachments.add({
        'type': 'file',
        'mime': mime,
        'url': 'data:$mime;base64,$b64',
        'filename': file.name,
      });
    });
  }

  String _mimeFromExt(String ext) {
    switch (ext) {
      case 'png': return 'image/png';
      case 'jpg': case 'jpeg': return 'image/jpeg';
      case 'gif': return 'image/gif';
      case 'webp': return 'image/webp';
      case 'svg': return 'image/svg+xml';
      case 'pdf': return 'application/pdf';
      case 'md': return 'text/markdown';
      case 'json': return 'application/json';
      case 'py': return 'text/x-python';
      case 'dart': return 'text/x-dart';
      case 'js': return 'text/javascript';
      case 'ts': return 'text/typescript';
      case 'html': return 'text/html';
      case 'css': return 'text/css';
      case 'yaml': case 'yml': return 'text/yaml';
      case 'txt': return 'text/plain';
      default: return 'application/octet-stream';
    }
  }

  Future<void> _runShell() async {
    final command = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('运行 Shell 命令', style: TextStyle(color: AppColors.textPrimary)),
        content: TextField(
          autofocus: true,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            hintText: 'ls -la',
            hintStyle: TextStyle(color: AppColors.textTertiary),
            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.border)),
            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.borderFocused)),
          ),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消', style: TextStyle(color: AppColors.textSecondary))),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => Navigator.pop(ctx, ''),
            child: const Text('运行'),
          ),
        ],
      ),
    );
    if (command == null || command.isEmpty) return;
    setState(() => _sending = true);
    try {
      await widget.api.runShell(widget.session.id, command: command, agent: _selectedAgent, model: _selectedModel);
      await _refreshMessages();
      _waitForFirstReply();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Shell 执行失败: $e')));
        setState(() => _sending = false);
      }
    }
  }

  void _applyCode(String code, String? language, BuildContext ctx) {
    final pathCtrl = TextEditingController(
      text: language != null && language != 'plaintext' ? 'main.$language' : 'output.txt',
    );
    showDialog(
      context: ctx,
      builder: (ctx2) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('应用代码到文件', style: TextStyle(color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('将以下代码写入文件：', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                code.length > 200 ? '${code.substring(0, 200)}...' : code,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 11, fontFamily: 'monospace'),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: pathCtrl,
              autofocus: true,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
              decoration: const InputDecoration(
                labelText: '文件路径',
                hintText: 'lib/main.dart',
                labelStyle: TextStyle(color: AppColors.textSecondary),
                hintStyle: TextStyle(color: AppColors.textTertiary),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.border)),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.borderFocused)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx2), child: const Text('取消', style: TextStyle(color: AppColors.textSecondary))),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () async {
              final path = pathCtrl.text.trim();
              if (path.isEmpty) return;
              Navigator.pop(ctx2);
              try {
                await widget.api.runShell(widget.session.id, command: 'cat > "$path" << \'EOF\'\n$code\nEOF', agent: _selectedAgent, model: _selectedModel);
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text('代码已提交写入 $path'), duration: Duration(seconds: 2)),
                  );
                }
                _refreshMessages();
                _waitForFirstReply();
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('写入失败: $e')));
                }
              }
            },
            child: const Text('写入'),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshMessages() async {
    try {
      final messages = await widget.api.getMessages(widget.session.id);
      if (mounted) {
        setState(() {
          _messages = messages;
          _error = null;
        });
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint('ChatScreen._refreshMessages: $e');
    }
  }

  void _waitForFirstReply() {
    Future.delayed(const Duration(milliseconds: 800), () async {
      if (!mounted) return;
      await _refreshMessages();
      final lastMsg = _messages.isNotEmpty ? _messages.last : null;
      final hasReply = lastMsg != null && lastMsg.role != 'user' && lastMsg.content.isNotEmpty;
      if (mounted && hasReply) {
        setState(() => _sending = false);
      }
    });
  }

  void _showAgentPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('选择 Agent', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
            ),
            const Divider(),
            ..._agents.map((a) => ListTile(
              leading: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.smart_toy, color: AppColors.primary, size: 18),
              ),
              title: Text(a.name, style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
              subtitle: a.description != null ? Text(a.description!, style: TextStyle(color: AppColors.textTertiary, fontSize: 12)) : null,
              trailing: _selectedAgent == a.name ? const Icon(Icons.check, color: AppColors.primary) : null,
              onTap: () {
                setState(() => _selectedAgent = a.name);
                Navigator.pop(ctx);
              },
            )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showModelPicker() {
    final modelId = _selectedModel;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      isScrollControlled: true,
      builder: (ctx) => _ModelPickerSheet(
        providers: _providers,
        selectedId: modelId,
        defaultModel: _selectedModel,
        onSelect: (fullID) {
          setState(() => _selectedModel = fullID);
          Navigator.pop(ctx);
        },
      ),
    );
  }

  Future<void> _showMessageActions(Message msg) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('消息操作', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.copy, color: AppColors.textSecondary),
              title: const Text('复制内容', style: TextStyle(color: AppColors.textPrimary)),
              onTap: () => Navigator.pop(ctx, 'copy'),
            ),
            if (msg.role != 'user') ...[
              ListTile(
                leading: const Icon(Icons.undo, color: AppColors.textSecondary),
                title: const Text('回退此消息', style: TextStyle(color: AppColors.textPrimary)),
                onTap: () => Navigator.pop(ctx, 'revert'),
              ),
              ListTile(
                leading: const Icon(Icons.redo, color: AppColors.textSecondary),
                title: const Text('恢复已回退', style: TextStyle(color: AppColors.textPrimary)),
                onTap: () => Navigator.pop(ctx, 'unrevert'),
              ),
              ListTile(
                leading: const Icon(Icons.info_outline, color: AppColors.textSecondary),
                title: const Text('查看详情', style: TextStyle(color: AppColors.textPrimary)),
                onTap: () => Navigator.pop(ctx, 'detail'),
              ),
            ],
            ListTile(
              leading: const Icon(Icons.call_split, color: AppColors.textSecondary),
              title: const Text('从此消息分叉', style: TextStyle(color: AppColors.textPrimary)),
              onTap: () => Navigator.pop(ctx, 'fork'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (result == null) return;
    switch (result) {
      case 'copy':
        await _copyToClipboard(msg.content);
      case 'revert':
        await _doRevert(msg);
      case 'unrevert':
        await _doUnrevert();
      case 'detail':
        _showMessageDetail(msg);
      case 'fork':
        await _doFork(msg);
    }
  }

  Future<void> _copyToClipboard(String text) async {
    await copyToClipboard(text);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已复制', style: TextStyle(color: AppColors.textPrimary)), backgroundColor: AppColors.surface),
      );
    }
  }

  Future<void> _doRevert(Message msg) async {
    try {
      await widget.api.revertMessage(widget.session.id, msg.id);
      await _refreshMessages();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('回退失败: $e')));
      }
    }
  }

  Future<void> _doUnrevert() async {
    try {
      await widget.api.unrevertMessages(widget.session.id);
      await _refreshMessages();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('恢复失败: $e')));
    }
  }

  void _showMessageDetail(Message msg) async {
    try {
      final detail = await widget.api.getMessageDetail(widget.session.id, msg.id);
      if (!mounted) return;
      final info = detail.info;
      final parts = detail.parts;
      showDialog(
        context: context,
        builder: (ctx) => Dialog(
          backgroundColor: AppColors.surface,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: const Text('消息详情', style: TextStyle(color: AppColors.textPrimary, fontSize: 14)),
                leading: IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _detailRow('ID', info.id),
                    _detailRow('角色', info.role),
                    _detailRow('Parts 数量', parts.length.toString()),
                    const SizedBox(height: 12),
                    Text('Parts:', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    const SizedBox(height: 4),
                    ...parts.take(10).map((p) {
                      final summary = switch (p.type) {
                        'text' => p.text ?? '',
                        'reasoning' => p.reasoningText ?? '',
                        'tool' => '${p.tool?.tool ?? ''}: ${p.tool?.stateStatus ?? ''}',
                        'file' => p.file?.filename ?? p.file?.url ?? '',
                        'subtask' => '${p.subtask?.agent ?? ''}: ${p.subtask?.description ?? ''}',
                        'step-start' => '',
                        'step-finish' => p.stepFinish?.reason ?? '',
                        'snapshot' => '',
                        'patch' => '${p.patch?.files.length ?? 0} files',
                        'agent' => p.agent?.name ?? '',
                        'retry' => 'attempt ${p.retry?.attempt}',
                        'compaction' => p.compaction?.auto == true ? 'auto' : '',
                        _ => '',
                      };
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '  [${p.type}] ${summary}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 11, fontFamily: 'monospace'),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('获取详情失败: $e')));
      }
    }
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          Expanded(child: Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13))),
        ],
      ),
    );
  }

  Future<void> _doFork(Message msg) async {
    try {
      final session = await widget.api.forkSession(widget.session.id, messageID: msg.id);
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(
          builder: (_) => ChatScreen(session: session, entry: widget.entry, api: widget.api),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('分叉失败: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final agentName = _selectedAgent ?? 'build';
    final agentColorStr = _agents.where((a) => a.name == agentName).firstOrNull?.color;
    Color? agentColor;
    if (agentColorStr != null && agentColorStr.startsWith('#')) {
      final parsed = int.tryParse(agentColorStr.replaceFirst('#', '0xFF'));
      if (parsed != null) agentColor = Color(parsed);
    }

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyR, meta: true): _load,
        const SingleActivator(LogicalKeyboardKey.keyN, meta: true): _createNewSession,
        const SingleActivator(LogicalKeyboardKey.keyL, meta: true, shift: true): () {
          _inputCtrl.clear();
          _inputCtrl.text = '/';
          _inputCtrl.selection = TextSelection.collapsed(offset: 1);
        },
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Text(widget.session.title.isNotEmpty ? widget.session.title : '会话'),
            actions: [
              IconButton(
                icon: const Icon(Icons.terminal, color: AppColors.textSecondary),
                tooltip: 'Shell 命令',
                onPressed: _runShell,
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
                onPressed: _load,
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                    : _error != null
                        ? Center(child: Text(_error!, style: TextStyle(color: AppColors.textSecondary)))
                        : _messages.isEmpty
                            ? Center(child: Text('开始对话', style: TextStyle(color: AppColors.textTertiary)))
                            : ListView.builder(
                                controller: _scrollCtrl,
                                padding: const EdgeInsets.all(16),
                                itemCount: _messages.length,
                                itemBuilder: (ctx, i) {
                                  final isLatest = i == _messages.length - 1;
                                  final isSecondLatest = !isLatest && (_messages[i].role != 'user') && (i == _messages.length - 2);
                                  return _MessageBubble(
                                    message: _messages[i],
                                    isLatest: isLatest || isSecondLatest,
                                    streamingText: _streamingDeltas.isNotEmpty && isLatest && !_messages[i].content.endsWith('\n') ? _streamingDeltas.values.join() : null,
                                    onLongPress: () => _showMessageActions(_messages[i]),
                                    onToggleReasoning: null,
                                    onApplyCode: _applyCode,
                                  );
                                },
                              ),
              ),
              if (_showCommands && _filteredCommands.isNotEmpty) _buildCommandSuggestions(),
              if (_attachments.isNotEmpty) _buildAttachmentPreview(),
              _agentBar(agentName, agentColor ?? AppColors.primary),
              if (_todos.any((t) => !t.done))
                _buildTodoBanner(),
              _buildInputBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCommandSuggestions() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: ListView(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        children: _filteredCommands.map((c) => ListTile(
          dense: true,
          leading: Icon(Icons.terminal, color: AppColors.primary, size: 18),
          title: Text('/${c.id}', style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontFamily: 'monospace')),
          subtitle: c.description != null ? Text(c.description!, style: TextStyle(color: AppColors.textTertiary, fontSize: 11)) : null,
          onTap: () {
            _inputCtrl.text = '/${c.id} ';
            _inputCtrl.selection = TextSelection.collapsed(offset: _inputCtrl.text.length);
            setState(() => _showCommands = false);
          },
        )).toList(),
      ),
    );
  }

  Widget _buildAttachmentPreview() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: SizedBox(
        height: 48,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _attachments.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (ctx, i) {
            final att = _attachments[i];
            final name = att['filename'] as String? ?? '';
            final mime = att['mime'] as String? ?? '';
            final isImage = mime.startsWith('image/');
            return Chip(
              avatar: isImage
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.memory(
                        _dataUriBytes(att['url'] as String? ?? ''),
                        width: 32, height: 32, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(Icons.image, size: 18, color: AppColors.textSecondary),
                      ),
                    )
                  : Icon(Icons.attach_file, size: 18, color: AppColors.textSecondary),
              label: Text(
                name.length > 20 ? '${name.substring(0, 17)}...' : name,
                style: TextStyle(color: AppColors.textPrimary, fontSize: 12),
              ),
              deleteIcon: Icon(Icons.close, size: 14, color: AppColors.textTertiary),
              onDeleted: () => setState(() => _attachments.removeAt(i)),
              backgroundColor: AppColors.background,
              side: BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              visualDensity: VisualDensity.compact,
            );
          },
        ),
      ),
    );
  }

  Uint8List _dataUriBytes(String dataUri) {
    final comma = dataUri.indexOf(',');
    if (comma < 0) return Uint8List(0);
    try {
      return base64Decode(dataUri.substring(comma + 1));
    } catch (_) {
      return Uint8List(0);
    }
  }

  Widget _buildTodoBanner() {
    final done = _todos.where((t) => t.done).length;
    final total = _todos.length;
    final pct = total > 0 ? done / total : 0.0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Icon(Icons.checklist, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              pct >= 1.0 ? '已完成所有待办事项!' : '$done/$total 待办已完成',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 12),
            ),
          ),
          if (pct < 1.0)
            LinearProgressIndicator(
              value: pct,
              backgroundColor: AppColors.border,
              color: AppColors.success,
              minHeight: 4,
            ),
          if (pct >= 1.0)
            Icon(Icons.check_circle, size: 16, color: AppColors.success),
        ],
      ),
    );
  }

  Widget _agentBar(String agentName, Color agentColor) {
    final tokens = widget.session.tokens;
    final totalTokens = tokens != null ? tokens.input + tokens.output + tokens.reasoning : 0;
    final contextPct = totalTokens > 0 ? (totalTokens / 128000).clamp(0.0, 1.0) : 0.0;
    final ctxColor = contextPct < 0.5 ? AppColors.success : (contextPct < 0.8 ? AppColors.warning : AppColors.danger);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          _Chip(
            icon: Icons.smart_toy,
            label: agentName,
            color: agentColor,
            onTap: _showAgentPicker,
          ),
          const SizedBox(width: 8),
          _Chip(
            icon: Icons.model_training,
            label: _selectedModel != null ? _selectedModel!.split('/').last : '模型',
            color: _selectedModel != null ? AppColors.primary : AppColors.textSecondary,
            onTap: _showModelPicker,
          ),
          if (totalTokens > 0) ...[
            const SizedBox(width: 8),
            Tooltip(
              message: '上下文使用: $totalTokens / 128K tokens',
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: ctxColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.memory, size: 12, color: ctxColor),
                    const SizedBox(width: 3),
                    Text('${(contextPct * 100).toInt()}%', style: TextStyle(color: ctxColor, fontSize: 10)),
                  ],
                ),
              ),
            ),
          ],
          if (_sending) ...[
            const Spacer(),
            SizedBox(
              width: 14, height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    final shellHint = _shellMode ? '输入 shell 命令...' : '输入消息... (/ 查看命令)';
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              if (!_sending)
                IconButton(
                  onPressed: _pickAttachment,
                  icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                  tooltip: '添加附件',
                ),
              const SizedBox(width: 4),
              Expanded(
                child: TextField(
                  controller: _inputCtrl,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontFamily: _shellMode ? 'monospace' : null,
                  ),
                  decoration: InputDecoration(
                    hintText: shellHint,
                    hintStyle: TextStyle(color: AppColors.textTertiary, fontFamily: _shellMode ? 'monospace' : null),
                    filled: true,
                    fillColor: _shellMode ? AppColors.surfaceAlt : AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(color: _shellMode ? AppColors.success : AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(color: _shellMode ? AppColors.success : AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(color: AppColors.borderFocused),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  maxLines: 4,
                  minLines: 1,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sending ? null : _sendMessage(),
                  onEditingComplete: () {
                    if (!_sending) _sendMessage();
                  },
                ),
              ),
              const SizedBox(width: 8),
              if (_sending)
                IconButton(
                  onPressed: _abortRequest,
                  icon: const Icon(Icons.stop_circle, color: AppColors.danger),
                  tooltip: '停止',
                )
              else
                IconButton(
                  onPressed: _sendMessage,
                  icon: const Icon(Icons.send, color: AppColors.primary),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Syntax-highlighted Code Block ---
class _CodeBlockBuilder extends MarkdownElementBuilder {
  final void Function(String code, String? language, BuildContext ctx)? onApply;

  _CodeBlockBuilder({this.onApply});

  @override
  Widget? visitElementAfter(element, TextStyle? preferredStyle) {
    final code = element.textContent;
    final language = element.attributes['language'] ?? 'plaintext';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            color: AppColors.border,
            child: Row(
              children: [
                Text(
                  language,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontFamily: 'monospace'),
                ),
                const Spacer(),
                Builder(
                  builder: (ctx) => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (onApply != null)
                        GestureDetector(
                          onTap: () => onApply!(code, language, ctx),
                          child: Icon(Icons.smart_toy_outlined, size: 13, color: AppColors.textSecondary),
                        ),
                      if (onApply != null) const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: code));
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(content: Text('已复制'), duration: Duration(seconds: 1)),
                          );
                        },
                        child: Icon(Icons.content_copy, size: 13, color: AppColors.textSecondary),
                      ),
                      const SizedBox(width: 4),
                    ],
                  ),
                ),
              ],
            ),
          ),
          HighlightView(
            code,
            language: language,
            theme: githubTheme,
            padding: const EdgeInsets.all(12),
            textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 12, height: 1.5),
          ),
        ],
      ),
    );
  }
}

// --- Reasoning Block ---
class _ReasoningBlock extends StatefulWidget {
  final String content;
  final bool isLatest;

  const _ReasoningBlock({required this.content, required this.isLatest});

  @override
  State<_ReasoningBlock> createState() => _ReasoningBlockState();
}

class _ReasoningBlockState extends State<_ReasoningBlock> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.isLatest;
  }

  @override
  void didUpdateWidget(_ReasoningBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.isLatest && oldWidget.isLatest) {
      setState(() => _expanded = false);
    }
    if (widget.isLatest && !oldWidget.isLatest) {
      setState(() => _expanded = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.psychology, color: AppColors.warning, size: 16),
                  const SizedBox(width: 6),
                  Text('思考过程', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
                  const Spacer(),
                  Icon(
                    _expanded ? Icons.unfold_less : Icons.unfold_more,
                    color: AppColors.textTertiary,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Text(
                widget.content,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontFamily: 'monospace', height: 1.5),
              ),
            ),
        ],
      ),
    );
  }
}

// --- Message Bubble ---
class _MessageBubble extends StatelessWidget {
  final Message message;
  final bool isLatest;
  final String? streamingText;
  final VoidCallback? onLongPress;
  final VoidCallback? onToggleReasoning;
  final void Function(String code, String? language, BuildContext ctx)? onApplyCode;

  const _MessageBubble({
    required this.message,
    this.isLatest = false,
    this.streamingText,
    this.onLongPress,
    this.onToggleReasoning,
    this.onApplyCode,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    final timeStr = formatTime(message.createdAt);
    final displayContent = streamingText != null ? '${message.content}\n$streamingText' : message.content;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isUser && message.hasReasoning)
            _ReasoningBlock(content: message.reasoning!, isLatest: isLatest),
          if (!isUser && message.cost > 0)
            Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '\$' + message.cost.toStringAsFixed(4),
                style: TextStyle(color: AppColors.success, fontSize: 10, fontFamily: 'monospace'),
              ),
            ),
          _buildBubble(context, isUser, displayContent),
          if (message.parts.any((p) => p.type == 'file'))
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: _FilePartsRow(parts: message.parts.where((p) => p.type == 'file').toList()),
            ),
          ...message.parts.where((p) => p.type == 'tool').map((p) => _ToolPartWidget(
            part: p,
            isLatest: isLatest,
            streamingText: streamingText,
          )),
          const SizedBox(height: 2),
          Text(timeStr, style: TextStyle(color: AppColors.textTertiary, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildBubble(BuildContext context, bool isUser, String displayContent) {
    return GestureDetector(
      onLongPress: onLongPress,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
        padding: EdgeInsets.only(
          left: 14,
          right: 14,
          top: isUser ? 10 : 8,
          bottom: isUser ? 10 : 8,
        ),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomRight: isUser ? const Radius.circular(4) : null,
            bottomLeft: !isUser ? const Radius.circular(4) : null,
          ),
          boxShadow: isUser ? null : [BoxShadow(color: AppColors.shadow, blurRadius: 4, offset: const Offset(0, 1))],
        ),
        child: isUser
            ? Text(
                message.content,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              )
            : MarkdownBody(
                data: displayContent,
                selectable: true,
                builders: {
                  'code_block': _CodeBlockBuilder(onApply: onApplyCode),
                },
                styleSheet: MarkdownStyleSheet(
                  p: const TextStyle(color: AppColors.textPrimary, fontSize: 14, height: 1.5),
                  h1: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold, height: 1.4),
                  h2: TextStyle(color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.bold, height: 1.4),
                  h3: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600, height: 1.4),
                  code: TextStyle(color: AppColors.textPrimary, fontSize: 12, fontFamily: 'monospace', backgroundColor: AppColors.surfaceAlt),
                  codeblockDecoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  blockquoteDecoration: BoxDecoration(
                    border: Border(left: BorderSide(color: AppColors.primary, width: 3)),
                    color: AppColors.surfaceAlt,
                  ),
                  listBullet: TextStyle(color: AppColors.textSecondary),
                  horizontalRuleDecoration: BoxDecoration(
                    border: Border(top: BorderSide(color: AppColors.border)),
                  ),
                  a: const TextStyle(color: AppColors.primary, decoration: TextDecoration.underline),
                  strong: const TextStyle(fontWeight: FontWeight.bold),
                  em: const TextStyle(fontStyle: FontStyle.italic),
                  del: const TextStyle(decoration: TextDecoration.lineThrough),
                  blockSpacing: 8,
                  codeblockPadding: EdgeInsets.all(10),
                ),
              ),
      ),
    );
  }
}

// --- Tool Part Widget ---
class _ToolPartWidget extends StatefulWidget {
  final Part part;
  final bool isLatest;
  final String? streamingText;

  const _ToolPartWidget({
    required this.part,
    this.isLatest = false,
    this.streamingText,
  });

  @override
  State<_ToolPartWidget> createState() => _ToolPartWidgetState();
}

class _ToolPartWidgetState extends State<_ToolPartWidget> {
  bool _expanded = true;

  @override
  void initState() {
    super.initState();
    _expanded = widget.isLatest;
  }

  @override
  Widget build(BuildContext context) {
    final tool = widget.part.tool;
    if (tool == null) return const SizedBox.shrink();

    final isError = tool.isError;
    final isRunning = tool.isRunning;
    final isCompleted = tool.isCompleted;
    Color? statusColor;
    IconData statusIcon;
    String statusLabel;
    if (isError) {
      statusColor = AppColors.danger;
      statusIcon = Icons.error_outline;
      statusLabel = '失败';
    } else if (isRunning) {
      statusColor = AppColors.warning;
      statusIcon = Icons.hourglass_top;
      statusLabel = '进行中';
    } else if (isCompleted) {
      statusColor = AppColors.success;
      statusIcon = Icons.check_circle_outline;
      statusLabel = '完成';
    } else {
      statusColor = AppColors.textSecondary;
      statusIcon = Icons.schedule;
      statusLabel = '等待';
    }

    final toolName = tool.tool;
    final title = tool.title ?? toolName;
    final input = tool.input;
    final output = tool.output;
    final error = tool.error;

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isError ? AppColors.danger : AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(title, toolName, statusColor, statusIcon, statusLabel),
            if (_expanded) ...[
              _buildInput(input, toolName),
              _buildOutput(output, error, toolName),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String title, String toolName, Color statusColor, IconData statusIcon, String statusLabel) {
    return InkWell(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            _toolIcon(toolName),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(statusIcon, size: 12, color: statusColor),
                  const SizedBox(width: 3),
                  Text(statusLabel, style: TextStyle(color: statusColor, fontSize: 10)),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              _expanded ? Icons.unfold_less : Icons.unfold_more,
              color: AppColors.textTertiary,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _toolIcon(String toolName) {
    IconData icon;
    Color color;
    switch (toolName) {
      case 'write':
        icon = Icons.edit_note;
        color = AppColors.primary;
      case 'edit':
        icon = Icons.difference;
        color = AppColors.warning;
      case 'read':
        icon = Icons.visibility;
        color = AppColors.info;
      case 'bash':
        icon = Icons.terminal;
        color = AppColors.success;
      case 'grep':
        icon = Icons.search;
        color = AppColors.textSecondary;
      case 'glob':
        icon = Icons.folder_open;
        color = AppColors.textSecondary;
      case 'webfetch':
        icon = Icons.web;
        color = AppColors.info;
      case 'task':
        icon = Icons.subdirectory_arrow_right;
        color = AppColors.warning;
      default:
        icon = Icons.build;
        color = AppColors.textSecondary;
    }
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
      child: Icon(icon, size: 16, color: color),
    );
  }

  Widget _buildInput(Map<String, dynamic>? input, String toolName) {
    if (input == null || input.isEmpty) return const SizedBox.shrink();
    if (toolName == 'write') {
      final filePath = input['file_path'] as String? ?? input['filePath'] as String? ?? '';
      final content = input['content'] as String? ?? '';
      if (content.isEmpty) return const SizedBox.shrink();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (filePath.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              color: AppColors.surfaceAlt,
              child: Text(
                filePath,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontFamily: 'monospace'),
              ),
            ),
          _CodePreview(code: content, toolName: toolName, onApply: null),
          ..._buildDiagnostics(input),
        ],
      );
    }
    if (toolName == 'bash') {
      final command = input['command'] as String? ?? input['cmd'] as String? ?? '';
      if (command.isEmpty) return const SizedBox.shrink();
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        color: AppColors.surfaceAlt,
        child: Text(
          '\$ $command',
          style: TextStyle(color: AppColors.textPrimary, fontSize: 12, fontFamily: 'monospace'),
        ),
      );
    }
    if (toolName == 'read') {
      final filePath = input['file_path'] as String? ?? input['filePath'] as String? ?? '';
      if (filePath.isEmpty) return const SizedBox.shrink();
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        color: AppColors.surfaceAlt,
        child: Text(
          filePath,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontFamily: 'monospace'),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildOutput(String? output, String? error, String toolName) {
    if (output != null && output.isNotEmpty) {
      if (toolName == 'edit') {
        final lines = output.split('\n');
        final hunks = <DiffHunkView>[];
        int i = 0;
        while (i < lines.length) {
          if (lines[i].startsWith('@@')) {
            final match = RegExp(r'@@ -(\d+).*\+(\d+)').firstMatch(lines[i]);
            final oldStart = int.tryParse(match?.group(1) ?? '') ?? 0;
            final newStart = int.tryParse(match?.group(2) ?? '') ?? 0;
            final hunkLines = <String>[];
            i++;
            while (i < lines.length && !lines[i].startsWith('@@')) {
              hunkLines.add(lines[i]);
              i++;
            }
            hunks.add(DiffHunkView.fromContent(oldStart, newStart, hunkLines.join('\n')));
          } else {
            i++;
          }
        }
        if (hunks.isNotEmpty) {
          return DiffView(
            filePath: '',
            status: 'modified',
            hunks: hunks,
          );
        }
      }
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: SelectableText(
          output,
          style: TextStyle(color: AppColors.textPrimary, fontSize: 12, fontFamily: 'monospace', height: 1.4),
        ),
      );
    }
    if (error != null && error.isNotEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        color: AppColors.danger.withValues(alpha: 0.1),
        child: Text(
          error,
          style: TextStyle(color: AppColors.danger, fontSize: 12, fontFamily: 'monospace'),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  List<Widget> _buildDiagnostics(Map<String, dynamic> input) {
    final raw = input['diagnostics'];
    if (raw is! List) return [];
    final items = raw.take(3).whereType<Map<String, dynamic>>().toList();
    if (items.isEmpty) return [];
    return items.map((d) {
      final severity = d['severity'] as int? ?? 1;
      final message = d['message'] as String? ?? '';
      final line = d['line'] as int?;
      final label = line != null ? '行 $line' : '';
      final isError = severity >= 1;
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        color: (isError ? AppColors.danger : AppColors.warning).withValues(alpha: 0.1),
        child: Row(
          children: [
            Icon(
              isError ? Icons.error : Icons.warning_amber,
              size: 14,
              color: isError ? AppColors.danger : AppColors.warning,
            ),
            const SizedBox(width: 6),
            if (label.isNotEmpty)
              Text('$label: ', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: isError ? AppColors.danger : AppColors.warning, fontSize: 11),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}

// --- Tool Code Preview ---
class _CodePreview extends StatelessWidget {
  final String code;
  final String toolName;
  final void Function(String code, String? language, BuildContext ctx)? onApply;

  const _CodePreview({required this.code, required this.toolName, this.onApply});

  @override
  Widget build(BuildContext context) {
    final language = _detectLanguage();
    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          HighlightView(
            code,
            language: language,
            theme: githubTheme,
            textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 11, height: 1.5),
          ),
        ],
      ),
    );
  }

  String _detectLanguage() {
    if (onApply != null) return 'plaintext';
    switch (toolName) {
      case 'write':
        return _guessLanguage(code);
      default:
        return 'plaintext';
    }
  }

  String _guessLanguage(String code) {
    if (code.startsWith('import ') || code.startsWith('void ') || code.startsWith('#include')) return 'c';
    if (code.startsWith('package ') || code.startsWith('import "')) return 'go';
    if (code.startsWith('const ') || code.startsWith('let ') || code.startsWith('function ')) return 'javascript';
    if (code.startsWith('import ')) {
      if (code.contains('package:')) return 'dart';
      if (code.contains('from ')) return 'javascript';
    }
    return 'plaintext';
  }
}

// --- File Parts Row ---
class _FilePartsRow extends StatelessWidget {
  final List<Part> parts;

  const _FilePartsRow({required this.parts});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        shrinkWrap: true,
        itemCount: parts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (ctx, i) {
          final p = parts[i];
          final file = p.file;
          if (file == null) return const SizedBox.shrink();
          final isImage = file.mime.startsWith('image/');
          final shortName = file.filename ?? file.url.split('/').last;
          final displayName = shortName.length > 20 ? '${shortName.substring(0, 17)}...' : shortName;
          return Container(
            width: 140,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: isImage
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          file.url,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Center(
                            child: Icon(Icons.broken_image, color: AppColors.textSecondary, size: 28),
                          ),
                          loadingBuilder: (_, child, progress) {
                            if (progress == null) return child;
                            return Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary));
                          },
                        ),
                        Positioned(
                          bottom: 0, left: 0, right: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter, end: Alignment.topCenter,
                                colors: [Colors.black87, Colors.transparent],
                              ),
                            ),
                            child: Text(displayName, style: const TextStyle(color: Colors.white, fontSize: 10)),
                          ),
                        ),
                      ],
                    ),
                  )
                : Row(
                    children: [
                      const SizedBox(width: 8),
                      Icon(Icons.insert_drive_file, color: AppColors.textSecondary, size: 24),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(displayName, style: TextStyle(color: AppColors.textPrimary, fontSize: 11), overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
          );
        },
      ),
    );
  }
}

// --- Model Picker ---
class _ModelPickerSheet extends StatefulWidget {
  final List<Provider> providers;
  final String? selectedId;
  final String? defaultModel;
  final ValueChanged<String> onSelect;

  const _ModelPickerSheet({
    required this.providers,
    this.selectedId,
    this.defaultModel,
    required this.onSelect,
  });

  @override
  State<_ModelPickerSheet> createState() => _ModelPickerSheetState();
}

class _ModelPickerSheetState extends State<_ModelPickerSheet> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Provider> get _filtered {
    if (_query.isEmpty) return widget.providers;
    final q = _query.toLowerCase();
    return widget.providers.map((p) {
      final matched = p.models.where((m) =>
        m.name.toLowerCase().contains(q) ||
        m.id.toLowerCase().contains(q) ||
        p.name.toLowerCase().contains(q)
      ).toList();
      return Provider(id: p.id, name: p.name, models: matched);
    }).where((p) => p.models.isNotEmpty).toList();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.85,
          expand: false,
          builder: (ctx, scrollCtrl) => Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  children: [
                    Text('选择模型', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _searchCtrl,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: '搜索模型...',
                        hintStyle: TextStyle(color: AppColors.textTertiary),
                        prefixIcon: Icon(Icons.search, color: AppColors.textSecondary, size: 20),
                        suffixIcon: _query.isNotEmpty ? IconButton(
                          icon: Icon(Icons.clear, color: AppColors.textSecondary, size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _query = '');
                          },
                        ) : null,
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.borderFocused),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onChanged: (v) => setState(() => _query = v),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: _filtered.isEmpty
                  ? Center(child: Text('未找到匹配模型', style: TextStyle(color: AppColors.textTertiary)))
                  : ListView(
                      controller: scrollCtrl,
                      padding: const EdgeInsets.only(bottom: 16),
                      children: _filtered.map((p) => _ProviderGroup(
                        provider: p,
                        selectedId: widget.selectedId,
                        defaultModel: widget.defaultModel,
                        expanded: _query.isNotEmpty || p.models.any((m) => m.fullID == widget.selectedId),
                        onSelect: widget.onSelect,
                      )).toList(),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProviderGroup extends StatefulWidget {
  final Provider provider;
  final String? selectedId;
  final String? defaultModel;
  final bool expanded;
  final ValueChanged<String> onSelect;

  const _ProviderGroup({
    required this.provider,
    this.selectedId,
    this.defaultModel,
    required this.expanded,
    required this.onSelect,
  });

  @override
  State<_ProviderGroup> createState() => _ProviderGroupState();
}

class _ProviderGroupState extends State<_ProviderGroup> {
  late bool _open;

  @override
  void initState() {
    super.initState();
    _open = widget.expanded;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _open = !_open),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Icon(_open ? Icons.expand_less : Icons.expand_more, color: AppColors.textSecondary, size: 18),
                const SizedBox(width: 8),
                Icon(Icons.cloud, color: AppColors.primary, size: 16),
                const SizedBox(width: 8),
                Text(widget.provider.name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppColors.textTertiary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text('${widget.provider.models.length}', style: TextStyle(color: AppColors.textSecondary, fontSize: 10)),
                ),
              ],
            ),
          ),
        ),
        if (_open)
          ...widget.provider.models.map((m) => ListTile(
            dense: true,
            contentPadding: const EdgeInsets.only(left: 56, right: 16),
            title: Text(m.name, style: TextStyle(color: AppColors.textPrimary, fontSize: 13)),
            subtitle: Text(m.id, style: TextStyle(color: AppColors.textTertiary, fontSize: 10)),
            trailing: widget.selectedId == m.fullID ? const Icon(Icons.check, color: AppColors.primary, size: 18) : null,
            onTap: () => widget.onSelect(m.fullID),
          )),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _Chip({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500)),
            const SizedBox(width: 2),
            Icon(Icons.arrow_drop_down, color: color, size: 16),
          ],
        ),
      ),
    );
  }
}

Future<void> copyToClipboard(String text) async {
  await Clipboard.setData(ClipboardData(text: text));
}
