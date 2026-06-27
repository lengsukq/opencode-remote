import 'dart:async';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../models.dart';
import '../../theme.dart';
import '../../services/opencode_api.dart';
import '../../services/event_service.dart';
import '../../widgets/agent_bar.dart';
import '../../widgets/attachment_preview.dart';
import '../../widgets/chat_input_bar.dart';
import '../../widgets/command_suggestions.dart';
import '../../widgets/revert_banner.dart';
import '../../widgets/todo_banner.dart';
import 'message_bubble.dart';
import 'model_picker_sheet.dart';

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
  bool _shellMode = false;
  final List<String> _inputHistory = [];
  List<Todo> _todos = [];
  String? _revertSnapshot;

  @override
  void initState() {
    super.initState();
    _load();
    _connectEvents();
    _inputCtrl.addListener(_onInputChanged);
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

  // --- Event handling ---

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
    setState(() {});
  }

  // --- Permission & Question dialogs ---

  void _handlePermission(Map<String, dynamic> data) {
    if (!mounted) return;
    final props = (data['payload'] is Map ? data['payload']['properties'] : data['properties']) as Map<String, dynamic>?;
    if (props == null) return;
    final permissionID = data['id'] as String?;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Permission Request', style: TextStyle(color: AppColors.textPrimary)),
        content: Text('${props['message'] ?? 'Allow this operation?'}', style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (permissionID != null) {
                widget.api.executeCommand(widget.session.id, command: 'permission', arguments: ['deny', permissionID]);
              }
            },
            child: Text('Deny', style: TextStyle(color: AppColors.danger)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (permissionID != null) {
                widget.api.executeCommand(widget.session.id, command: 'permission', arguments: ['approve', permissionID, '--remember']);
              }
            },
            child: Text('Always Allow', style: TextStyle(color: AppColors.warning)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              Navigator.pop(ctx);
              if (permissionID != null) {
                widget.api.executeCommand(widget.session.id, command: 'permission', arguments: ['approve', permissionID]);
              }
            },
            child: Text('Allow Once'),
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
        title: Text('Question', style: TextStyle(color: AppColors.textPrimary)),
        content: Text('${props['message'] ?? props['question'] ?? ''}', style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary))),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => Navigator.pop(ctx),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  // --- Input handling ---

  void _onInputChanged() {
    final text = _inputCtrl.text;
    final isShell = text.startsWith('!') && !text.startsWith('!/');
    if (isShell != _shellMode) setState(() => _shellMode = isShell);
    if (text.startsWith('/') && text.length > 1) {
      final query = text.substring(1).toLowerCase();
      setState(() {
        _showCommands = true;
        _filteredCommands = _commands.where((c) => c.id.toLowerCase().contains(query) || c.title.toLowerCase().contains(query)).toList();
      });
    } else if (text.isEmpty || !text.startsWith('/')) {
      setState(() => _showCommands = false);
    }
  }

  // --- Data loading ---

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    try {
      final data = await _loadAllData();
      if (!mounted) return;
      _applyLoadedData(data);
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  Future<_LoadData> _loadAllData() async {
    final msgs = await widget.api.getMessages(widget.session.id);
    final agents = await widget.api.getAgents();
    final providers = await widget.api.getProviders();
    final commands = await widget.api.getCommands();
    final configData = await widget.api.getConfigProviders();

    final rawDefaults = configData['default'];
    final defaults = (rawDefaults is Map)
        ? (rawDefaults as Map<String, dynamic>).map((k, v) => MapEntry(k, v?.toString() ?? ''))
        : <String, String>{};

    return _LoadData(msgs, agents, providers, commands, defaults);
  }

  void _applyLoadedData(_LoadData data) {
    String? autoModel;
    if (data.msgs.isNotEmpty) {
      final last = data.msgs.lastWhere((m) => m.model != null, orElse: () => data.msgs.last);
      autoModel = last.model;
    }
    autoModel ??= data.defaults['build'];

    setState(() {
      _messages = data.msgs;
      _agents = data.agents;
      _providers = data.providers;
      _commands = data.commands;
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
    } catch (e) {
      debugPrint('ChatScreen._loadTodos: $e');
    }
  }

  // --- Send message ---

  Future<void> _sendMessage() async {
    var text = _inputCtrl.text.trim();
    if (text.isEmpty) return;
    _inputCtrl.clear();
    setState(() { _sending = true; _showCommands = false; });

    final isShellCmd = _shellMode && text.startsWith('!');
    if (isShellCmd) text = text.substring(1).trim();

    try {
      if (isShellCmd) {
        await _sendShell(text);
      } else if (text.startsWith('/')) {
        await _sendCommand(text);
      } else {
        await _sendText(text);
      }
      _inputHistory.add(text);
      if (_inputHistory.length > 100) _inputHistory.removeAt(0);
      _attachments = [];
      await _refreshMessages();
    } catch (e) {
      if (mounted) _showError('Send Failed', '$e');
      setState(() => _sending = false);
    }
  }

  Future<void> _sendShell(String text) async {
    await widget.api.runShell(widget.session.id, command: text, agent: _selectedAgent, model: _selectedModel);
  }

  Future<void> _sendCommand(String text) async {
    final parts = text.substring(1).split(' ');
    final cmd = parts.first;
    final args = parts.skip(1).toList();
    await widget.api.executeCommand(widget.session.id, command: cmd, arguments: args, agent: _selectedAgent, model: _selectedModel);
  }

  Future<void> _sendText(String text) async {
    final allParts = <Map<String, dynamic>>[
      {'type': 'text', 'text': text},
      ..._attachments,
    ];
    try {
      await widget.api.sendMessageAsync(
        widget.session.id, content: text, parts: allParts,
        agent: _selectedAgent, model: _selectedModel,
      );
    } catch (e) {
      debugPrint('ChatScreen._sendMessage: async failed ($e), fallback to sync');
      await widget.api.sendMessage(
        widget.session.id, content: text, parts: allParts,
        agent: _selectedAgent, model: _selectedModel,
      );
    }
  }

  // --- Abort ---

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

  // --- Attachments ---

  Future<void> _pickAttachment() async {
    final source = await _showAttachmentPicker();
    if (source == null) return;
    try {
      switch (source) {
        case 'image':
          final xFile = await ImagePicker().pickImage(source: ImageSource.gallery);
          if (xFile != null) await _addImageAttachment(xFile);
        case 'camera':
          final xFile = await ImagePicker().pickImage(source: ImageSource.camera);
          if (xFile != null) await _addImageAttachment(xFile);
        case 'file':
          final result = await FilePicker.platform.pickFiles();
          if (result != null && result.files.isNotEmpty) {
            await _addFileAttachment(result.files.first);
          }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Attachment failed: $e')));
      }
    }
  }

  Future<String?> _showAttachmentPicker() {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Add Attachment', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
            ),
            const Divider(height: 1),
            _attachmentOption(ctx, Icons.image, 'Image', 'From Gallery', 'image'),
            _attachmentOption(ctx, Icons.camera_alt, 'Camera', 'Take a Photo', 'camera'),
            _attachmentOption(ctx, Icons.attach_file, 'File', 'From Local Storage', 'file'),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  ListTile _attachmentOption(BuildContext ctx, IconData icon, String title, String subtitle, String value) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title, style: TextStyle(color: AppColors.textPrimary)),
      subtitle: Text(subtitle, style: TextStyle(color: AppColors.textTertiary, fontSize: 12)),
      onTap: () => Navigator.pop(ctx, value),
    );
  }

  Future<void> _addImageAttachment(XFile xFile) async {
    final bytes = await xFile.readAsBytes();
    final b64 = base64Encode(bytes);
    final mime = _mimeFromExt(xFile.name.split('.').last.toLowerCase());
    if (mounted) {
      setState(() { _attachments.add({'type': 'file', 'mime': mime, 'url': 'data:$mime;base64,$b64', 'filename': xFile.name}); });
    }
  }

  Future<void> _addFileAttachment(PlatformFile file) async {
    final bytes = file.bytes;
    if (bytes == null) return;
    final b64 = base64Encode(bytes);
    final mime = _mimeFromExt(file.name.split('.').last.toLowerCase());
    if (mounted) {
      setState(() { _attachments.add({'type': 'file', 'mime': mime, 'url': 'data:$mime;base64,$b64', 'filename': file.name}); });
    }
  }

  static const _mimeMap = <String, String>{
    'png': 'image/png', 'jpg': 'image/jpeg', 'jpeg': 'image/jpeg',
    'gif': 'image/gif', 'webp': 'image/webp', 'svg': 'image/svg+xml',
    'pdf': 'application/pdf', 'md': 'text/markdown', 'json': 'application/json',
    'py': 'text/x-python', 'dart': 'text/x-dart', 'js': 'text/javascript',
    'ts': 'text/typescript', 'html': 'text/html', 'css': 'text/css',
    'yaml': 'text/yaml', 'yml': 'text/yaml', 'txt': 'text/plain',
  };

  String _mimeFromExt(String ext) => _mimeMap[ext.toLowerCase()] ?? 'application/octet-stream';

  // --- Shell & Code Apply ---

  Future<void> _runShell() async {
    final command = await _showShellDialog();
    if (command == null || command.isEmpty) return;
    setState(() => _sending = true);
    try {
      await widget.api.runShell(widget.session.id, command: command, agent: _selectedAgent, model: _selectedModel);
      await _refreshMessages();
      _waitForFirstReply();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Shell failed: $e')));
        setState(() => _sending = false);
      }
    }
  }

  Future<String?> _showShellDialog() {
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Run Shell Command', style: TextStyle(color: AppColors.textPrimary)),
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
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary))),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => Navigator.pop(ctx, ''),
            child: const Text('Run'),
          ),
        ],
      ),
    );
  }

  void _applyCode(String code, String? language, BuildContext ctx) {
    final pathCtrl = TextEditingController(
      text: language != null && language != 'plaintext' ? 'main.$language' : 'output.txt',
    );
    showDialog(
      context: ctx,
      builder: (ctx2) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Apply Code to File', style: TextStyle(color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Write the following code to file:', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(6),
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
                labelText: 'File Path', hintText: 'lib/main.dart',
                labelStyle: TextStyle(color: AppColors.textSecondary),
                hintStyle: TextStyle(color: AppColors.textTertiary),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.border)),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.borderFocused)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx2), child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary))),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () async {
              final path = pathCtrl.text.trim();
              if (path.isEmpty) return;
              Navigator.pop(ctx2);
              try {
                if (!mounted) return;
                final b64 = base64Encode(utf8.encode(code));
                await widget.api.runShell(widget.session.id,
                  command: 'echo $b64 | base64 -d > "$path"',
                  agent: _selectedAgent, model: _selectedModel,
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Code submitted to $path'), duration: Duration(seconds: 2)),
                  );
                }
                _refreshMessages();
                _waitForFirstReply();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Write failed: $e')));
                }
              }
            },
            child: const Text('Write'),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshMessages() async {
    try {
      final messages = await widget.api.getMessages(widget.session.id);
      if (mounted) {
        setState(() { _messages = messages; _error = null; });
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
      if (mounted && hasReply) setState(() => _sending = false);
    });
  }

  // --- Agent & Model Pickers ---

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
              child: Text('Select Agent', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
            ),
            const Divider(),
            ..._agents.map((a) => ListTile(
              leading: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(8)),
                child: Icon(Icons.smart_toy, color: AppColors.primary, size: 18),
              ),
              title: Text(a.name, style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
              subtitle: a.description != null ? Text(a.description!, style: TextStyle(color: AppColors.textTertiary, fontSize: 12)) : null,
              trailing: _selectedAgent == a.name ? const Icon(Icons.check, color: AppColors.primary) : null,
              onTap: () { setState(() => _selectedAgent = a.name); Navigator.pop(ctx); },
            )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showModelPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      isScrollControlled: true,
      builder: (ctx) => ModelPickerSheet(
        providers: _providers,
        selectedId: _selectedModel,
        defaultModel: _selectedModel,
        onSelect: (fullID) { setState(() => _selectedModel = fullID); Navigator.pop(ctx); },
      ),
    );
  }

  // --- Message Actions ---

  Future<void> _showMessageActions(Message msg) async {
    final result = await _showActionSheet(msg);
    if (result == null) return;
    switch (result) {
      case 'copy': await _copyToClipboard(msg.content);
      case 'revert': await _doRevert(msg);
      case 'unrevert': await _doUnrevert();
      case 'detail': _showMessageDetail(msg);
      case 'fork': await _doFork(msg);
    }
  }

  Future<String?> _showActionSheet(Message msg) {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(padding: const EdgeInsets.all(16), child: Text('Message Actions', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600))),
            const Divider(),
            ListTile(leading: const Icon(Icons.copy, color: AppColors.textSecondary), title: const Text('Copy Content', style: TextStyle(color: AppColors.textPrimary)), onTap: () => Navigator.pop(ctx, 'copy')),
            if (msg.role != 'user') ...[
              ListTile(leading: const Icon(Icons.undo, color: AppColors.textSecondary), title: const Text('Revert Message', style: TextStyle(color: AppColors.textPrimary)), onTap: () => Navigator.pop(ctx, 'revert')),
              ListTile(leading: const Icon(Icons.redo, color: AppColors.textSecondary), title: const Text('Restore Reverted', style: TextStyle(color: AppColors.textPrimary)), onTap: () => Navigator.pop(ctx, 'unrevert')),
              ListTile(leading: const Icon(Icons.info_outline, color: AppColors.textSecondary), title: const Text('View Details', style: TextStyle(color: AppColors.textPrimary)), onTap: () => Navigator.pop(ctx, 'detail')),
            ],
            ListTile(leading: const Icon(Icons.call_split, color: AppColors.textSecondary), title: const Text('Fork from Here', style: TextStyle(color: AppColors.textPrimary)), onTap: () => Navigator.pop(ctx, 'fork')),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  String _partSummary(Part p) => switch (p.type) {
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

  void _showMessageDetail(Message msg) async {
    try {
      final detail = await widget.api.getMessageDetail(widget.session.id, msg.id);
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => Dialog(
          backgroundColor: AppColors.surface,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: const Text('Message Details', style: TextStyle(color: AppColors.textPrimary, fontSize: 14)),
                leading: IconButton(icon: const Icon(Icons.close, color: AppColors.textSecondary), onPressed: () => Navigator.pop(ctx)),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildInfoRow('ID', detail.info.id),
                    _buildInfoRow('Role', detail.info.role),
                    _buildInfoRow('Parts', detail.parts.length.toString()),
                    const SizedBox(height: 12),
                    Text('Parts:', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    const SizedBox(height: 4),
                    ...detail.parts.take(10).map((p) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '  [${p.type}] ${_partSummary(p)}',
                        maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 11, fontFamily: 'monospace'),
                      ),
                    )),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Detail failed: $e')));
    }
  }

  Widget _buildInfoRow(String label, String value) {
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

  // --- Revert / Fork / Copy ---

  Future<void> _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Copied', style: TextStyle(color: AppColors.textPrimary)), backgroundColor: AppColors.surface),
      );
    }
  }

  Future<void> _doRevert(Message msg) async {
    try {
      await widget.api.revertMessage(widget.session.id, msg.id);
      if (mounted) await _refreshMessages();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Revert failed: $e')));
    }
  }

  Future<void> _doUnrevert() async {
    try {
      await widget.api.unrevertMessages(widget.session.id);
      if (mounted) await _refreshMessages();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Restore failed: $e')));
    }
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
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Fork failed: $e')));
    }
  }

  void _showError(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(title, style: TextStyle(color: AppColors.textPrimary)),
        content: Text(message, style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // --- Build ---

  @override
  Widget build(BuildContext context) {
    final agentName = _selectedAgent ?? 'build';
    final agentColor = _resolveAgentColor(agentName);

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
            title: Text(widget.session.title.isNotEmpty ? widget.session.title : 'Session'),
            actions: [
              IconButton(icon: const Icon(Icons.terminal, color: AppColors.textSecondary), tooltip: 'Shell Command', onPressed: _runShell),
              IconButton(icon: const Icon(Icons.refresh, color: AppColors.textSecondary), onPressed: _load),
            ],
          ),
          body: Column(
            children: [
              Expanded(child: _buildMessageList()),
              if (_revertSnapshot != null) RevertBanner(onRestore: _handleRestore),
              if (_showCommands && _filteredCommands.isNotEmpty) CommandSuggestions(commands: _filteredCommands, onSelect: _handleCommandSelect),
              if (_attachments.isNotEmpty) AttachmentPreview(attachments: _attachments, onRemove: (i) => setState(() => _attachments.removeAt(i))),
              AgentBar(
                agentName: agentName,
                agentColor: agentColor ?? AppColors.primary,
                selectedModel: _selectedModel,
                tokens: widget.session.tokens,
                sending: _sending,
                onAgentTap: _showAgentPicker,
                onModelTap: _showModelPicker,
              ),
              if (_todos.any((t) => !t.done))
                TodoBanner(done: _todos.where((t) => t.done).length, total: _todos.length),
              ChatInputBar(
                controller: _inputCtrl,
                shellMode: _shellMode,
                sending: _sending,
                onSend: _sendMessage,
                onAbort: _abortRequest,
                onPickAttachment: _pickAttachment,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleRestore() async {
    try {
      await widget.api.unrevertMessages(widget.session.id);
      setState(() => _revertSnapshot = null);
      if (mounted) await _refreshMessages();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Restore failed: $e')));
    }
  }

  void _handleCommandSelect(Command c) {
    _inputCtrl.text = '/${c.id} ';
    _inputCtrl.selection = TextSelection.collapsed(offset: _inputCtrl.text.length);
    setState(() => _showCommands = false);
  }

  Widget _buildMessageList() {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    if (_error != null) return Center(child: Text(_error!, style: TextStyle(color: AppColors.textSecondary)));
    if (_messages.isEmpty) return Center(child: Text('Start a conversation', style: TextStyle(color: AppColors.textTertiary)));

    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (ctx, i) {
        final isLatest = i == _messages.length - 1;
        final isSecondLatest = !isLatest && (_messages[i].role != 'user') && (i == _messages.length - 2);
        return MessageBubble(
          message: _messages[i],
          isLatest: isLatest || isSecondLatest,
          streamingText: _streamingDeltas.isNotEmpty && isLatest && !_messages[i].content.endsWith('\n') ? _streamingDeltas.values.last : null,
          onLongPress: () => _showMessageActions(_messages[i]),
          onApplyCode: _applyCode,
        );
      },
    );
  }

  Color? _resolveAgentColor(String agentName) {
    final colorStr = _agents.where((a) => a.name == agentName).firstOrNull?.color;
    if (colorStr != null && colorStr.startsWith('#')) {
      final parsed = int.tryParse(colorStr.replaceFirst('#', '0xFF'));
      if (parsed != null) return Color(parsed);
    }
    return null;
  }

  Future<void> _createNewSession() async {
    try {
      final session = await widget.api.createSession();
      if (!mounted) return;
      await Navigator.pushReplacement(context, MaterialPageRoute(
        builder: (_) => ChatScreen(session: session, entry: widget.entry, api: widget.api),
      ));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('create session failed: $e')));
    }
  }
}

/// Data holder for [_ChatScreenState._loadAllData] results.
class _LoadData {
  final List<Message> msgs;
  final List<Agent> agents;
  final List<Provider> providers;
  final List<Command> commands;
  final Map<String, String> defaults;

  _LoadData(this.msgs, this.agents, this.providers, this.commands, this.defaults);
}
