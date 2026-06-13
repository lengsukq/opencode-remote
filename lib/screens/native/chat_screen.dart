import 'package:flutter/material.dart';
import '../../models.dart';
import '../../theme.dart';
import '../../services/opencode_api.dart';

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
  bool _loading = true;
  String? _error;
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _sending = false;
  String? _selectedAgent;
  String? _selectedModel;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        widget.api.getMessages(widget.session.id),
        widget.api.getAgents(),
        widget.api.getProviders(),
      ]);
      setState(() {
        _messages = results[0] as List<Message>;
        _agents = results[1] as List<Agent>;
        _providers = results[2] as List<Provider>;
        if (_selectedAgent == null && _agents.isNotEmpty) {
          final buildAgent = _agents.where((a) => a.name == 'build').firstOrNull;
          _selectedAgent = buildAgent?.name ?? _agents.first.name;
        }
        _loading = false;
        _error = null;
      });
      _scrollToBottom();
    } catch (e) {
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

  Future<void> _sendMessage() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;
    _inputCtrl.clear();
    setState(() => _sending = true);
    try {
      await widget.api.sendMessageAsync(widget.session.id, text, agent: _selectedAgent, model: _selectedModel);
      await _refreshMessages();
      _pollForNewMessages();
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
    } catch (_) {}
  }

  void _pollForNewMessages() {
    Future.delayed(const Duration(seconds: 2), () async {
      if (!mounted) return;
      await _refreshMessages();
      final lastMsg = _messages.isNotEmpty ? _messages.last : null;
      final hasReply = lastMsg != null && lastMsg.role != 'user' && lastMsg.content.isNotEmpty;
      if (mounted && hasReply) {
        setState(() => _sending = false);
      } else if (mounted && _sending) {
        _pollForNewMessages();
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
        onSelect: (fullID) {
          setState(() => _selectedModel = fullID);
          Navigator.pop(ctx);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final agentName = _selectedAgent ?? 'build';
    final agentColorStr = _agents.where((a) => a.name == agentName).firstOrNull?.color;
    Color? agentColor;
    if (agentColorStr != null && agentColorStr.startsWith('#')) {
      try {
        agentColor = Color(int.parse(agentColorStr.replaceFirst('#', '0xFF')));
      } catch (_) {}
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.session.title.isNotEmpty ? widget.session.title : '会话'),
        actions: [
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
                            itemBuilder: (ctx, i) => _MessageBubble(message: _messages[i]),
                          ),
          ),
          _agentBar(agentName, agentColor ?? AppColors.primary),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _agentBar(String agentName, Color agentColor) {
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
              Expanded(
                child: TextField(
                  controller: _inputCtrl,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: '输入消息...',
                    hintStyle: TextStyle(color: AppColors.textTertiary),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(color: AppColors.borderFocused),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  maxLines: 4,
                  minLines: 1,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 8),
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

class _ModelPickerSheet extends StatefulWidget {
  final List<Provider> providers;
  final String? selectedId;
  final ValueChanged<String> onSelect;

  const _ModelPickerSheet({
    required this.providers,
    this.selectedId,
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
  final bool expanded;
  final ValueChanged<String> onSelect;

  const _ProviderGroup({
    required this.provider,
    this.selectedId,
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

class _MessageBubble extends StatelessWidget {
  final Message message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    final timeStr = _formatTime(message.createdAt);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isUser ? AppColors.primary : AppColors.surface,
              borderRadius: BorderRadius.circular(16).copyWith(
                bottomRight: isUser ? const Radius.circular(4) : null,
                bottomLeft: !isUser ? const Radius.circular(4) : null,
              ),
              boxShadow: isUser ? null : [BoxShadow(color: AppColors.shadow, blurRadius: 4, offset: const Offset(0, 1))],
            ),
            child: Text(
              message.content,
              style: TextStyle(color: isUser ? Colors.white : AppColors.textPrimary, fontSize: 14),
            ),
          ),
          const SizedBox(height: 2),
          Text(timeStr, style: TextStyle(color: AppColors.textTertiary, fontSize: 10)),
        ],
      ),
    );
  }

  String _formatTime(int ms) {
    final dt = DateTime.fromMillisecondsSinceEpoch(ms);
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
