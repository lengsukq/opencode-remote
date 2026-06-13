import 'package:flutter/material.dart';
import '../../models.dart';
import '../../theme.dart';
import '../../services/opencode_api.dart';
import '../../widgets/diff_view.dart';
import 'chat_screen.dart';

class SessionListScreen extends StatefulWidget {
  final ServerEntry entry;
  final OpenCodeApi api;

  const SessionListScreen({super.key, required this.entry, required this.api});

  @override
  State<SessionListScreen> createState() => _SessionListScreenState();
}

class _SessionListScreenState extends State<SessionListScreen> {
  List<Session> _sessions = [];
  bool _loading = true;
  String? _error;
  bool _searching = false;
  final _searchCtrl = TextEditingController();

  List<Session> get _filteredSessions {
    if (!_searching || _searchCtrl.text.isEmpty) return _sessions;
    final q = _searchCtrl.text.toLowerCase();
    return _sessions.where((s) =>
      s.title.toLowerCase().contains(q) || s.id.toLowerCase().contains(q)
    ).toList();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final sessions = await widget.api.getSessions();
      sessions.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      setState(() {
        _sessions = sessions;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _createSession() async {
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('新建会话', style: TextStyle(color: AppColors.textPrimary)),
        content: TextField(
          autofocus: true,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            hintText: '会话标题（可选）',
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
            child: const Text('创建空会话'),
          ),
        ],
      ),
    );
    if (result == null) return;
    try {
      await widget.api.createSession(title: result.trim().isNotEmpty ? result.trim() : null);
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('创建失败: $e')));
      }
    }
  }

  Future<void> _showSessionActions(Session session) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(session.title.isNotEmpty ? session.title : '未命名会话', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.edit, color: AppColors.textSecondary),
              title: const Text('重命名', style: TextStyle(color: AppColors.textPrimary)),
              onTap: () => Navigator.pop(ctx, 'rename'),
            ),
            ListTile(
              leading: const Icon(Icons.share, color: AppColors.textSecondary),
              title: const Text('分享', style: TextStyle(color: AppColors.textPrimary)),
              onTap: () => Navigator.pop(ctx, 'share'),
            ),
            ListTile(
              leading: const Icon(Icons.stop, color: AppColors.textSecondary),
              title: const Text('中止', style: TextStyle(color: AppColors.textPrimary)),
              onTap: () => Navigator.pop(ctx, 'abort'),
            ),
            ListTile(
              leading: const Icon(Icons.block, color: AppColors.textSecondary),
              title: const Text('停止分享', style: TextStyle(color: AppColors.textPrimary)),
              onTap: () => Navigator.pop(ctx, 'unshare'),
            ),
            ListTile(
              leading: const Icon(Icons.account_tree, color: AppColors.textSecondary),
              title: const Text('子会话', style: TextStyle(color: AppColors.textPrimary)),
              onTap: () => Navigator.pop(ctx, 'children'),
            ),
            ListTile(
              leading: const Icon(Icons.checklist, color: AppColors.textSecondary),
              title: const Text('待办列表', style: TextStyle(color: AppColors.textPrimary)),
              onTap: () => Navigator.pop(ctx, 'todo'),
            ),
            ListTile(
              leading: const Icon(Icons.difference, color: AppColors.textSecondary),
              title: const Text('查看差异', style: TextStyle(color: AppColors.textPrimary)),
              onTap: () => Navigator.pop(ctx, 'diff'),
            ),
            ListTile(
              leading: const Icon(Icons.summarize, color: AppColors.textSecondary),
              title: const Text('总结', style: TextStyle(color: AppColors.textPrimary)),
              onTap: () => Navigator.pop(ctx, 'summarize'),
            ),
            ListTile(
              leading: const Icon(Icons.call_split, color: AppColors.textSecondary),
              title: const Text('分叉', style: TextStyle(color: AppColors.textPrimary)),
              onTap: () => Navigator.pop(ctx, 'fork'),
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: AppColors.danger),
              title: const Text('删除', style: TextStyle(color: AppColors.danger)),
              onTap: () => Navigator.pop(ctx, 'delete'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (action == null) return;
    switch (action) {
      case 'rename':
        await _renameSession(session);
      case 'share':
        await _shareSession(session);
      case 'abort':
        await _abortSession(session);
      case 'unshare':
        await _unshareSession(session);
      case 'children':
        await _showChildSessions(session);
      case 'todo':
        await _showTodoList(session);
      case 'diff':
        await _showDiff(session);
      case 'summarize':
        await _summarizeSession(session);
      case 'fork':
        await _forkSession(session);
      case 'delete':
        await _deleteSession(session);
    }
  }

  Future<void> _abortSession(Session session) async {
    try {
      await widget.api.abortSession(session.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('会话已中止')));
        await _load();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('中止失败: $e')));
    }
  }

  Future<void> _unshareSession(Session session) async {
    try {
      await widget.api.unshareSession(session.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已取消分享')));
        await _load();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('取消失败: $e')));
    }
  }

  Future<void> _showChildSessions(Session session) async {
    try {
      final children = await widget.api.getChildSessions(session.id);
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => Dialog(
          backgroundColor: AppColors.surface,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: const Text('子会话', style: TextStyle(color: AppColors.textPrimary, fontSize: 14)),
                leading: IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
              if (children.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('无子会话', style: TextStyle(color: AppColors.textTertiary)),
                )
              else
                ...children.map((c) => ListTile(
                  title: Text(c.title.isNotEmpty ? c.title : '未命名', style: TextStyle(color: AppColors.textPrimary, fontSize: 13)),
                  subtitle: Text('${c.status}', style: TextStyle(color: AppColors.textTertiary, fontSize: 11)),
                )),
            ],
          ),
        ),
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('获取子会话失败: $e')));
    }
  }

  Future<void> _showTodoList(Session session) async {
    try {
      final todos = await widget.api.getSessionTodo(session.id);
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => Dialog(
          backgroundColor: AppColors.surface,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: const Text('待办列表', style: TextStyle(color: AppColors.textPrimary, fontSize: 14)),
                leading: IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
              if (todos.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('无待办事项', style: TextStyle(color: AppColors.textTertiary)),
                )
              else
                Expanded(
                  child: ListView(
                    children: todos.map((t) => ListTile(
                      dense: true,
                      leading: Icon(
                        t.done ? Icons.check_circle : Icons.radio_button_unchecked,
                        color: t.done ? AppColors.success : AppColors.textSecondary,
                        size: 18,
                      ),
                      title: Text(
                        t.task,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          decoration: t.done ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    )).toList(),
                  ),
                ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('获取待办失败: $e')));
    }
  }

  Future<void> _renameSession(Session session) async {
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('重命名', style: TextStyle(color: AppColors.textPrimary)),
        content: TextField(
          autofocus: true,
          controller: TextEditingController(text: session.title),
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            hintText: '新标题',
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
            child: const Text('确定'),
          ),
        ],
      ),
    );
    if (result == null || result.isEmpty) return;
    try {
      await widget.api.updateSession(session.id, title: result.trim());
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('重命名失败: $e')));
      }
    }
  }

  Future<void> _shareSession(Session session) async {
    try {
      await widget.api.shareSession(session.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('会话已分享', style: TextStyle(color: AppColors.textPrimary)),
          backgroundColor: AppColors.surface,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('分享失败: $e')));
      }
    }
  }

  Future<void> _showDiff(Session session) async {
    try {
      final diffs = await widget.api.getSessionDiff(session.id);
      if (!mounted) return;
      if (diffs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('暂无差异')));
        return;
      }
      showDialog(
        context: context,
        builder: (ctx) => Dialog(
          backgroundColor: AppColors.background,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              AppBar(
                title: Text('差异: ${session.title}', style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
                leading: IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(12),
                  children: diffs.map((d) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: DiffView(
                      filePath: d.filePath,
                      status: d.status,
                      hunks: d.hunks.map((h) => DiffHunkView.fromContent(
                        h.oldStart, h.newStart, h.content,
                      )).toList(),
                    ),
                  )).toList(),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('获取差异失败: $e')));
      }
    }
  }

  Future<void> _summarizeSession(Session session) async {
    try {
      final success = await widget.api.summarizeSession(session.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(success ? '总结完成' : '总结失败', style: TextStyle(color: AppColors.textPrimary)),
          backgroundColor: AppColors.surface,
        ));
        if (success) await _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('总结失败: $e')));
      }
    }
  }

  Future<void> _forkSession(Session session) async {
    final messageID = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('分叉会话', style: TextStyle(color: AppColors.textPrimary)),
        content: const Text('从最新消息分叉一个新会话？', style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消', style: TextStyle(color: AppColors.textSecondary))),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('分叉'),
          ),
        ],
      ),
    );
    if (messageID == null) return;
    try {
      await widget.api.forkSession(session.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('已分叉为新会话', style: TextStyle(color: AppColors.textPrimary)),
          backgroundColor: AppColors.surface,
        ));
        await _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('分叉失败: $e')));
      }
    }
  }

  Future<void> _deleteSession(Session session) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('删除会话', style: TextStyle(color: AppColors.textPrimary)),
        content: Text('确定删除"${session.title}"？', style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消', style: TextStyle(color: AppColors.textSecondary))),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await widget.api.deleteSession(session.id);
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('删除失败: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final displaySessions = _filteredSessions;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('会话列表'),
        actions: [
          IconButton(
            icon: Icon(_searching ? Icons.search_off : Icons.search, color: AppColors.textSecondary),
            tooltip: '搜索',
            onPressed: () => setState(() {
              _searching = !_searching;
              if (!_searching) _searchCtrl.clear();
            }),
          ),
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.textSecondary),
            tooltip: '新建会话',
            onPressed: _createSession,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_searching)
            Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              color: AppColors.surface,
              child: TextField(
                controller: _searchCtrl,
                autofocus: true,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: '搜索会话标题...',
                  hintStyle: TextStyle(color: AppColors.textTertiary),
                  prefixIcon: Icon(Icons.search, color: AppColors.textSecondary, size: 20),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: AppColors.textSecondary, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() {});
                        },
                      )
                    : null,
                  filled: true,
                  fillColor: AppColors.background,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.border)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.borderFocused)),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _load,
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : _error != null
                      ? Center(child: Text(_error!, style: TextStyle(color: AppColors.textSecondary)))
                      : displaySessions.isEmpty
                          ? Center(child: Text(_searching ? '无匹配会话' : '暂无会话', style: TextStyle(color: AppColors.textTertiary)))
                          : ListView.builder(
                              padding: const EdgeInsets.all(12),
                              itemCount: displaySessions.length,
                              itemBuilder: (ctx, i) => _SessionTile(
                                session: displaySessions[i],
                                onTap: () => Navigator.push(context, MaterialPageRoute(
                                  builder: (_) => ChatScreen(session: displaySessions[i], entry: widget.entry, api: widget.api),
                                )),
                                onLongPress: () => _showSessionActions(displaySessions[i]),
                              ),
                            ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  final Session session;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _SessionTile({required this.session, required this.onTap, this.onLongPress});

  @override
  Widget build(BuildContext context) {
    final dt = DateTime.fromMillisecondsSinceEpoch(session.updatedAt);
    final timeStr = '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.chat_outlined, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(session.title.isNotEmpty ? session.title : '未命名会话',
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 3),
                    Text(timeStr, style: TextStyle(color: AppColors.textTertiary, fontSize: 11)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: AppColors.textTertiary, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
