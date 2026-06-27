import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models.dart';
import '../../strings.dart';
import '../../theme.dart';
import '../../services/opencode_api.dart';
import '../../services/event_service.dart';

import '../../utils/responsive_values.dart';
import '../../widgets/agent_bar.dart';
import '../../widgets/attachment_preview.dart';
import '../../widgets/chat_input_bar.dart';
import '../../widgets/command_suggestions.dart';
import '../../widgets/revert_banner.dart';
import '../../widgets/todo_banner.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/app_bottom_sheet.dart';
import '../../widgets/app_states.dart';
import '../../widgets/chat_state.dart';
import '../../widgets/attachment_picker_sheet.dart';
import '../../widgets/follow_up_bar.dart';
import '../../widgets/shell_dialog.dart';
import '../../widgets/apply_code_dialog.dart';
import '../../widgets/agent_picker_sheet.dart';
import '../../widgets/message_detail_dialog.dart';
import 'message_bubble.dart';
import 'model_picker_sheet.dart';

class ChatScreen extends StatefulWidget {
  final Session session;
  final ServerEntry entry;
  final OpenCodeApi api;
  const ChatScreen({super.key, required this.session, required this.entry, required this.api});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<Message> _messages = [];
  List<Agent> _agents = [];
  List<Provider> _providers = [];
  late List<Command> _commands = [];
  bool _isLoading = true;
  String? _error;
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _isSending = false;
  bool _isShellMode = false;
  String? _selectedAgent;
  String? _selectedModel;
  final _cmdState = CommandState();
  EventService? _eventService;
  StreamSubscription<ServerEvent>? _eventSub;
  final _streamState = StreamState();
  List<Map<String, dynamic>> _attachments = [];
  final List<String> _inputHistory = [];
  List<Todo> _todos = [];
  String? _revertSnapshot;
  List<String> _followUps = [];

  @override
  void initState() { super.initState(); _load(); _connectEvents(); _inputCtrl.addListener(_onInputChanged); }

  @override
  void dispose() {
    _inputCtrl.removeListener(_onInputChanged);
    _inputCtrl.dispose(); _scrollCtrl.dispose();
    _eventSub?.cancel(); _eventService?.dispose();
    super.dispose();
  }

  void _connectEvents() {
    _eventSub?.cancel(); _eventService?.dispose();
    _eventService = EventService(baseUrl: widget.entry.url, username: widget.entry.username, password: widget.entry.password);
    _eventService!.connect();
    _eventSub = _eventService!.events.listen(
      (event) {
        switch (event.type) {
          case EventType.messageNew: case EventType.sessionUpdated: _streamState.clear(); _refreshMessages();
          case EventType.messagePartDelta: _handleDelta(event.data);
          case EventType.permissionAsked: _handlePermission(event.data);
          case EventType.questionAsked: _handleQuestion(event.data);
          default: break;
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
      _streamState.deltas[partID] = (_streamState.deltas[partID] ?? '') + delta;
    } else if (field == 'state.status' && delta != null) {
      _streamState.toolStates[partID] = {...?_streamState.toolStates[partID], 'status': delta};
    } else if (field == 'state.output' && delta != null) {
      final existing = (_streamState.toolStates[partID]?['output'] as String? ?? '') + delta;
      _streamState.toolStates[partID] = {...?_streamState.toolStates[partID], 'output': existing};
    } else if (field == 'state.error' && delta != null) {
      _streamState.toolStates[partID] = {...?_streamState.toolStates[partID], 'error': delta};
    } else if (field == 'state.title' && delta != null) {
      _streamState.toolStates[partID] = {...?_streamState.toolStates[partID], 'title': delta};
    }
    setState(() {});
  }

  void _handlePermission(Map<String, dynamic> data) {
    if (!mounted) return;
    final props = (data['payload'] is Map ? data['payload']['properties'] : data['properties']) as Map<String, dynamic>?;
    if (props == null) return;
    final permissionID = data['id'] as String?;
    AppDialog.showCustom(context, title: S.permissionRequest, showDefaultCancel: false,
      content: Text('${props['message'] ?? 'Allow this operation?'}', style: const TextStyle(color: AppColors.textSecondary)),
      actions: [
        TextButton(onPressed: () { Navigator.pop(context); if (permissionID != null) widget.api.executeCommand(widget.session.id, command: 'permission', arguments: ['deny', permissionID]); },
          child: Text(S.deny, style: const TextStyle(color: AppColors.danger))),
        TextButton(onPressed: () { Navigator.pop(context); if (permissionID != null) widget.api.executeCommand(widget.session.id, command: 'permission', arguments: ['approve', permissionID, '--remember']); },
          child: Text(S.alwaysAllow, style: const TextStyle(color: AppColors.warning))),
        FilledButton(style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
          onPressed: () { Navigator.pop(context); if (permissionID != null) widget.api.executeCommand(widget.session.id, command: 'permission', arguments: ['approve', permissionID]); },
          child: Text(S.allowOnce)),
      ],
    );
  }

  void _handleQuestion(Map<String, dynamic> data) {
    if (!mounted) return;
    final props = (data['payload'] is Map ? data['payload']['properties'] : data['properties']) as Map<String, dynamic>?;
    if (props == null) return;
    AppDialog.showCustom(context, title: S.question, cancelLabel: S.cancel,
      content: Text('${props['message'] ?? props['question'] ?? ''}', style: const TextStyle(color: AppColors.textSecondary)),
      actions: [FilledButton(style: FilledButton.styleFrom(backgroundColor: AppColors.primary), onPressed: () => Navigator.pop(context), child: Text(S.ok))],
    );
  }

  void _onInputChanged() {
    final text = _inputCtrl.text;
    final isShell = text.startsWith('!') && !text.startsWith('!/');
    if (isShell != _isShellMode) {
      setState(() => _isShellMode = isShell);
    }
    if (text.startsWith('/') && text.length > 1) {
      final query = text.substring(1).toLowerCase();
      setState(() { _cmdState.show = true; _cmdState.filtered = _commands.where((c) => c.id.toLowerCase().contains(query) || c.title.toLowerCase().contains(query)).toList(); });
    } else if (text.isEmpty || !text.startsWith('/')) {
      setState(() => _cmdState.show = false);
    }
  }

  String _getProjectName() {
    final dir = widget.api.directory;
    if (dir == null || dir.isEmpty) return '';
    return dir.split(RegExp(r'[/\\]')).lastWhere((s) => s.isNotEmpty, orElse: () => '');
  }

  Widget _buildTitle() {
    final title = widget.session.title.isNotEmpty ? widget.session.title : 'Session';
    final pn = _getProjectName();
    if (pn.isEmpty) return Text(title);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontSize: 16)),
      Text(pn, style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
    ]);
  }

  Future<void> _load() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final data = await _loadAllData();
      if (!mounted) return;
      _applyLoadedData(data);
    } catch (e) {
      if (!mounted) return;
      setState(() { _isLoading = false; _error = e.toString(); });
    }
  }

  Future<_LoadData> _loadAllData() async {
    final msgs = await widget.api.getMessages(widget.session.id);
    final agents = await widget.api.getAgents();
    final providers = await widget.api.getProviders();
    final commands = await widget.api.getCommands();
    final configData = await widget.api.getConfigProviders();
    final rawDefaults = configData['default'];
    final defaults = (rawDefaults is Map) ? (rawDefaults as Map<String, dynamic>).map((k, v) => MapEntry(k, v?.toString() ?? '')) : <String, String>{};
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
      _messages = data.msgs; _agents = data.agents; _providers = data.providers; _commands = data.commands;
      _selectedModel ??= autoModel;
      if (_selectedAgent == null && _agents.isNotEmpty) {
        final buildAgent = _agents.where((a) => a.name == 'build').firstOrNull;
        _selectedAgent = buildAgent?.name ?? _agents.first.name;
      }
      _isLoading = false; _error = null;
    });
    _scrollToBottom(); _loadTodos(); _extractFollowUps(data.msgs);
  }

  void _extractFollowUps(List<Message> msgs) {
    if (msgs.isEmpty) { if (_followUps.isNotEmpty) setState(() => _followUps = []); return; }
    final raw = msgs.last.metadata?['followUp'];
    if (raw is List) {
      final suggestions = raw.whereType<String>().toList();
      if (!listEquals(suggestions, _followUps)) setState(() => _followUps = suggestions);
    } else if (_followUps.isNotEmpty) {
      setState(() => _followUps = []);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
    });
  }

  Future<void> _loadTodos() async {
    try { final todos = await widget.api.getSessionTodo(widget.session.id); if (mounted) setState(() => _todos = todos); }
    catch (e) { debugPrint('ChatScreen._loadTodos: $e'); }
  }

  Future<void> _sendMessage() async {
    var text = _inputCtrl.text.trim();
    if (text.isEmpty) return;
    _inputCtrl.clear();
    setState(() { _isSending = true; _cmdState.show = false; });
    final isShellCmd = _isShellMode && text.startsWith('!');
    if (isShellCmd) text = text.substring(1).trim();
    try {
      if (isShellCmd) { await _sendShell(text); }
      else if (text.startsWith('/')) { await _sendCommand(text); }
      else { await _sendText(text); }
      _inputHistory.add(text);
      if (_inputHistory.length > 100) _inputHistory.removeAt(0);
      _attachments = [];
      await _refreshMessages();
    } catch (e) {
      if (mounted) _showError(S.sendFailed, '$e');
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _sendShell(String text) async => widget.api.runShell(widget.session.id, command: text, agent: _selectedAgent, model: _selectedModel);

  Future<void> _sendCommand(String text) async {
    final parts = text.substring(1).split(' ');
    await widget.api.executeCommand(widget.session.id, command: parts.first, arguments: parts.skip(1).toList(), agent: _selectedAgent, model: _selectedModel);
  }

  Future<void> _sendText(String text) async {
    final allParts = <Map<String, dynamic>>[{'type': 'text', 'text': text}, ..._attachments];
    try { await widget.api.sendMessageAsync(widget.session.id, content: text, parts: allParts, agent: _selectedAgent, model: _selectedModel); }
    catch (e) {
      debugPrint('ChatScreen._sendMessage: async failed ($e), fallback to sync');
      await widget.api.sendMessage(widget.session.id, content: text, parts: allParts, agent: _selectedAgent, model: _selectedModel);
    }
  }

  Future<void> _abortRequest() async {
    try {
      await widget.api.abortSession(widget.session.id);
      if (!mounted) return;
      setState(() => _isSending = false);
      await _refreshMessages();
    } catch (e) {
      debugPrint('ChatScreen._abortRequest: $e');
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _pickAttachment() async {
    final source = await showAttachmentPicker(context);
    if (source == null) return;
    try {
      switch (source) {
        case 'image': final att = await pickImageAttachment(ImageSource.gallery); if (att != null && mounted) setState(() => _attachments.add(att));
        case 'camera': final att = await pickImageAttachment(ImageSource.camera); if (att != null && mounted) setState(() => _attachments.add(att));
        case 'file': final att = await pickFileAttachment(); if (att != null && mounted) setState(() => _attachments.add(att));
      }
    } catch (e) { if (mounted) AppSnackBar.error(context, S.attachmentFailed(e)); }
  }

  Future<void> _runShell() async {
    final command = await showShellDialog(context);
    if (command == null || command.isEmpty) return;
    if (!mounted) return;
    setState(() => _isSending = true);
    try {
      await widget.api.runShell(widget.session.id, command: command, agent: _selectedAgent, model: _selectedModel);
      await _refreshMessages();
      _waitForFirstReply();
    } catch (e) {
      if (mounted) { AppSnackBar.error(context, S.shellFailed(e)); setState(() => _isSending = false); }
    }
  }

  void _applyCode(String code, String? language, BuildContext ctx) async {
    final path = await showApplyCodeDialog(ctx, code: code, language: language);
    if (path == null) return;
    try {
      if (!mounted) return;
      final b64 = base64Encode(utf8.encode(code));
      await widget.api.runShell(widget.session.id, command: 'echo $b64 | base64 -d > "$path"', agent: _selectedAgent, model: _selectedModel);
      if (mounted) AppSnackBar.success(context, 'Code submitted to $path');
      _refreshMessages();
      _waitForFirstReply();
    } catch (e) { if (mounted) AppSnackBar.error(context, 'Write failed: $e'); }
  }

  Future<void> _refreshMessages() async {
    try {
      final messages = await widget.api.getMessages(widget.session.id);
      if (mounted) { setState(() { _messages = messages; _error = null; }); _scrollToBottom(); _extractFollowUps(messages); }
    } catch (e) { debugPrint('ChatScreen._refreshMessages: $e'); }
  }

  void _waitForFirstReply() {
    Future.delayed(const Duration(milliseconds: 800), () async {
      if (!mounted) return;
      await _refreshMessages();
      final lastMsg = _messages.isNotEmpty ? _messages.last : null;
      final hasReply = lastMsg != null && lastMsg.role != 'user' && lastMsg.content.isNotEmpty;
      if (mounted && hasReply) setState(() => _isSending = false);
    });
  }

  void _showAgentPicker() async {
    final result = await showAgentPicker(context, agents: _agents, selectedAgent: _selectedAgent);
    if (result != null) setState(() => _selectedAgent = result);
  }

  void _showModelPicker() {
    AppBottomSheet.show(context: context, child: ModelPickerSheet(
      providers: _providers, selectedId: _selectedModel, defaultModel: _selectedModel,
      onSelect: (fullID) { setState(() => _selectedModel = fullID); Navigator.pop(context); },
    ));
  }

  Future<void> _showMessageActions(Message msg) async {
    final result = await _showActionSheet(msg);
    if (result == null) return;
    switch (result) {
      case 'copy': await _copyToClipboard(msg.content);
      case 'revert': await _doRevert(msg);
      case 'unrevert': await _doUnrevert();
      case 'detail': await _showMessageDetailDialog(msg);
      case 'fork': await _doFork(msg);
    }
  }

  Future<String?> _showActionSheet(Message msg) {
    final options = <BottomSheetOption<String>>[
      BottomSheetOption(icon: Icons.copy, label: S.copyContent, value: 'copy'),
      if (msg.role != 'user') ...[
        BottomSheetOption(icon: Icons.undo, label: S.revertMessage, value: 'revert'),
        BottomSheetOption(icon: Icons.redo, label: S.restoreReverted, value: 'unrevert'),
        BottomSheetOption(icon: Icons.info_outline, label: S.viewDetails, value: 'detail'),
      ],
      BottomSheetOption(icon: Icons.call_split, label: S.forkFromHere, value: 'fork'),
    ];
    return AppBottomSheet.showOptions(context, title: S.messageActions, options: options);
  }

  Future<void> _showMessageDetailDialog(Message msg) async {
    try {
      final detail = await widget.api.getMessageDetail(widget.session.id, msg.id);
      if (mounted) showMessageDetail(context, detail);
    } catch (e) { if (mounted) AppSnackBar.error(context, 'Detail failed: $e'); }
  }

  Future<void> _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) AppSnackBar.success(context, S.copied);
  }

  Future<void> _doRevert(Message msg) async {
    try { await widget.api.revertMessage(widget.session.id, msg.id); if (mounted) await _refreshMessages(); }
    catch (e) { if (mounted) AppSnackBar.error(context, 'Revert failed: $e'); }
  }

  Future<void> _doUnrevert() async {
    try { await widget.api.unrevertMessages(widget.session.id); if (mounted) await _refreshMessages(); }
    catch (e) { if (mounted) AppSnackBar.error(context, 'Restore failed: $e'); }
  }

  Future<void> _doFork(Message msg) async {
    try {
      final session = await widget.api.forkSession(widget.session.id, messageID: msg.id);
      if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ChatScreen(session: session, entry: widget.entry, api: widget.api)));
    } catch (e) { if (mounted) AppSnackBar.error(context, 'Fork failed: $e'); }
  }

  void _showError(String title, String message) {
    AppDialog.showCustom(context, title: title, showDefaultCancel: false,
      content: Text(message, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
      actions: [FilledButton(style: FilledButton.styleFrom(backgroundColor: AppColors.primary), onPressed: () => Navigator.pop(context), child: Text(S.ok))],
    );
  }

  @override
  Widget build(BuildContext context) {
    final agentName = _selectedAgent ?? 'build';
    final agentColor = _resolveAgentColor(agentName);
    return CallbackShortcuts(bindings: {
      const SingleActivator(LogicalKeyboardKey.keyR, meta: true): _load,
      const SingleActivator(LogicalKeyboardKey.keyN, meta: true): _createNewSession,
      const SingleActivator(LogicalKeyboardKey.keyL, meta: true, shift: true): () { _inputCtrl.clear(); _inputCtrl.text = '/'; _inputCtrl.selection = TextSelection.collapsed(offset: 1); },
    }, child: Focus(autofocus: true, child: Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: _buildTitle(), actions: [
        IconButton(icon: Icon(Icons.terminal, color: AppColors.textSecondary, size: R.iconSize(context)), tooltip: S.shellCommand, onPressed: _runShell),
        IconButton(icon: Icon(Icons.refresh, color: AppColors.textSecondary, size: R.iconSize(context)), onPressed: _load),
      ]),
      body: Column(children: [
        Expanded(child: _buildMessageList()),
        if (_revertSnapshot != null) RevertBanner(onRestore: _handleRestore),
        if (_cmdState.show && _cmdState.filtered.isNotEmpty) CommandSuggestions(commands: _cmdState.filtered, onSelect: _handleCommandSelect),
        if (_attachments.isNotEmpty) AttachmentPreview(attachments: _attachments, onRemove: (i) => setState(() => _attachments.removeAt(i))),
        AgentBar(agentName: agentName, agentColor: agentColor ?? AppColors.primary, selectedModel: _selectedModel, tokens: widget.session.tokens, sending: _isSending, onAgentTap: _showAgentPicker, onModelTap: _showModelPicker),
        if (_todos.any((t) => !t.done)) TodoBanner(done: _todos.where((t) => t.done).length, total: _todos.length),
        if (_followUps.isNotEmpty) FollowUpBar(suggestions: _followUps, onSend: _sendFollowUp),
        ChatInputBar(controller: _inputCtrl, shellMode: _isShellMode, sending: _isSending, onSend: _sendMessage, onAbort: _abortRequest, onPickAttachment: _pickAttachment),
      ]),
    )));
  }

  void _sendFollowUp(String text) { _inputCtrl.text = text; _inputCtrl.selection = TextSelection.collapsed(offset: text.length); _sendMessage(); }

  void _handleRestore() async {
    try {
      await widget.api.unrevertMessages(widget.session.id);
      if (!mounted) return;
      setState(() => _revertSnapshot = null);
      if (mounted) await _refreshMessages();
    } catch (e) { if (mounted) AppSnackBar.error(context, 'Restore failed: $e'); }
  }

  void _handleCommandSelect(Command c) { _inputCtrl.text = '/${c.id} '; _inputCtrl.selection = TextSelection.collapsed(offset: _inputCtrl.text.length); setState(() => _cmdState.show = false); }

  Widget _buildMessageList() {
    if (_isLoading) return const AppLoadingIndicator();
    if (_error != null) return AppErrorState(message: _error!, onRetry: _load);
    if (_messages.isEmpty) return Center(child: Text(S.startConversation, style: TextStyle(color: AppColors.textTertiary, fontSize: R.bodyFontSize(context))));
    return ListView.builder(controller: _scrollCtrl, padding: R.screenPadding(context), itemCount: _messages.length, itemBuilder: (ctx, i) {
      final isLatest = i == _messages.length - 1;
      final isSecondLatest = !isLatest && (_messages[i].role != 'user') && (i == _messages.length - 2);
      return MessageBubble(
        message: _messages[i], isLatest: isLatest || isSecondLatest,
        streamingText: _streamState.deltas.isNotEmpty && isLatest && !_messages[i].content.endsWith('\n') ? _streamState.deltas.values.last : null,
        onLongPress: () => _showMessageActions(_messages[i]), onApplyCode: _applyCode,
      );
    });
  }

  Color? _resolveAgentColor(String agentName) {
    final colorStr = _agents.where((a) => a.name == agentName).firstOrNull?.color;
    if (colorStr != null && colorStr.startsWith('#')) { final p = int.tryParse(colorStr.replaceFirst('#', '0xFF')); if (p != null) return Color(p); }
    return null;
  }

  Future<void> _createNewSession() async {
    try {
      final session = await widget.api.createSession();
      if (!mounted) return;
      await Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ChatScreen(session: session, entry: widget.entry, api: widget.api)));
    } catch (e) { if (mounted) AppSnackBar.error(context, 'create session failed: $e'); }
  }
}

class _LoadData {
  final List<Message> msgs;
  final List<Agent> agents;
  final List<Provider> providers;
  final List<Command> commands;
  final Map<String, String> defaults;
  _LoadData(this.msgs, this.agents, this.providers, this.commands, this.defaults);
}


