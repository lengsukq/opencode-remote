import 'package:flutter/material.dart';
import '../../models.dart';
import '../../strings.dart';
import '../../theme.dart';
import '../../services/opencode_api.dart';

import '../../utils/responsive_values.dart';
import '../../utils/glass_effect.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/app_bottom_sheet.dart';
import '../../widgets/app_snackbar.dart';
import 'chat_screen.dart';
import '../../widgets/app_states.dart';
import '../../widgets/session_actions.dart';

class SessionListScreen extends StatefulWidget {
  final ServerEntry entry;
  final OpenCodeApi api;
  final Project? activeProject;

  const SessionListScreen({
    super.key,
    required this.entry,
    required this.api,
    this.activeProject,
  });

  @override
  State<SessionListScreen> createState() => _SessionListScreenState();
}

class _SessionListScreenState extends State<SessionListScreen> {
  List<Session> _sessions = [];
  bool _loading = true;
  String? _error;
  bool _searching = false;
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  List<Session> get _filteredSessions {
    if (!_searching || _searchQuery.isEmpty) return _sessions;
    final q = _searchQuery.toLowerCase();
    return _sessions
        .where(
          (s) =>
              s.title.toLowerCase().contains(q) ||
              s.id.toLowerCase().contains(q),
        )
        .toList();
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

  @override
  void didUpdateWidget(SessionListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeProject?.id != widget.activeProject?.id) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final sessions = await widget.api.getSessions();
      sessions.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      if (!mounted) return;
      setState(() {
        _sessions = sessions;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _createSession() async {
    final result = await AppDialog.showTextInput(
      context,
      title: S.newSession,
      hintText: S.sessionTitleHint,
      confirmLabel: S.createEmptySession,
    );
    if (result == null) return;
    try {
      await widget.api.createSession(
        title: result.trim().isNotEmpty ? result.trim() : null,
      );
      await _load();
    } catch (e) {
      if (mounted) {
        AppSnackBar.error(context, '${S.createFailed}: $e');
      }
    }
  }

  Future<void> _showSessionActions(Session session) async {
    final action = await AppBottomSheet.showOptions<String>(
      context,
      title: session.title.isNotEmpty ? session.title : S.unnamedSession,
      options: [
        const BottomSheetOption(
          icon: Icons.edit,
          label: '重命名',
          value: 'rename',
        ),
        const BottomSheetOption(
          icon: Icons.share,
          label: S.share,
          value: 'share',
        ),
        const BottomSheetOption(
          icon: Icons.stop,
          label: S.abort,
          value: 'abort',
        ),
        const BottomSheetOption(
          icon: Icons.block,
          label: S.stopSharing,
          value: 'unshare',
        ),
        const BottomSheetOption(
          icon: Icons.account_tree,
          label: S.childSessions,
          value: 'children',
        ),
        const BottomSheetOption(
          icon: Icons.checklist,
          label: S.todoList,
          value: 'todo',
        ),
        const BottomSheetOption(
          icon: Icons.difference,
          label: S.diff,
          value: 'diff',
        ),
        const BottomSheetOption(
          icon: Icons.summarize,
          label: S.summarize,
          value: 'summarize',
        ),
        const BottomSheetOption(
          icon: Icons.call_split,
          label: S.fork,
          value: 'fork',
        ),
        const BottomSheetOption(
          icon: Icons.delete,
          label: S.delete,
          value: 'delete',
          destructive: true,
        ),
      ],
    );
    if (action == null) return;
    if (!mounted) return;
    switch (action) {
      case 'rename':
        await SessionActions.rename(context, widget.api, session, _load);
      case 'share':
        await SessionActions.share(context, widget.api, session);
      case 'abort':
        await SessionActions.abort(context, widget.api, session, _load);
      case 'unshare':
        await SessionActions.unshare(context, widget.api, session, _load);
      case 'children':
        await SessionActions.showChildSessions(context, widget.api, session);
      case 'todo':
        await SessionActions.showTodoList(context, widget.api, session);
      case 'diff':
        await SessionActions.showDiff(context, widget.api, session);
      case 'summarize':
        await SessionActions.summarize(context, widget.api, session, _load);
      case 'fork':
        await SessionActions.fork(context, widget.api, session, _load);
      case 'delete':
        await SessionActions.delete(context, widget.api, session, _load);
    }
  }

  @override
  Widget build(BuildContext context) {
    final displaySessions = _filteredSessions;
    final searchPadding = R.edgeInsets(
      context,
      phone: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      tablet: const EdgeInsets.fromLTRB(16, 12, 16, 8),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.activeProject != null
              ? '${widget.activeProject!.name} / ${S.sessions}'
              : '${S.sessions}列表',
        ),
        actions: [
          IconButton(
            icon: Icon(
              _searching ? Icons.search_off : Icons.search,
              color: AppColors.textSecondary,
            ),
            tooltip: '搜索',
            onPressed: () => setState(() {
              _searching = !_searching;
              if (!_searching) _searchCtrl.clear();
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: _createSession,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          if (_searching)
            Container(
              padding: searchPadding,
              color: AppColors.surface,
              child: TextField(
                controller: _searchCtrl,
                autofocus: true,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: R.bodyFontSize(context),
                ),
                decoration: InputDecoration(
                  hintText: '搜索会话标题...',
                  hintStyle: const TextStyle(color: AppColors.textTertiary),
                  prefixIcon: Icon(
                    Icons.search,
                    color: AppColors.textSecondary,
                    size: R.smallIconSize(context),
                  ),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.clear,
                            color: AppColors.textSecondary,
                            size: R.smallIconSize(context),
                          ),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.background,
                  contentPadding: EdgeInsets.symmetric(
                    vertical: R.smallSpacing(context),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      AppColors.kSmallBorderRadius,
                    ),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      AppColors.kSmallBorderRadius,
                    ),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      AppColors.kSmallBorderRadius,
                    ),
                    borderSide: const BorderSide(
                      color: AppColors.borderFocused,
                      width: 1.5,
                    ),
                  ),
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _load,
              child: _loading
                  ? const AppLoadingIndicator()
                  : _error != null
                  ? AppErrorState(message: _error!, onRetry: _load)
                  : displaySessions.isEmpty
                  ? Center(
                      child: Padding(
                        padding: R.screenPadding(context),
                        child: Text(
                          _searching
                              ? S.noMatchingSessions
                              : widget.activeProject != null
                              ? "'${widget.activeProject!.name}' 中${S.noSessions}"
                              : S.noSessions,
                          style: TextStyle(
                            color: AppColors.textTertiary,
                            fontSize: R.bodyFontSize(context),
                          ),
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: R.listPadding(context),
                      itemCount: displaySessions.length,
                      itemBuilder: (ctx, i) => _SessionTile(
                        session: displaySessions[i],
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              session: displaySessions[i],
                              entry: widget.entry,
                              api: widget.api,
                            ),
                          ),
                        ),
                        onLongPress: () =>
                            _showSessionActions(displaySessions[i]),
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

  const _SessionTile({
    required this.session,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final dt = DateTime.fromMillisecondsSinceEpoch(session.updatedAt);
    final timeStr =
        '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: R.edgeInsets(
        context,
        phone: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        tablet: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      ),
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: GlassCard(
          padding: R.cardPadding(context),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(R.smallSpacing(context) + 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(
                    AppColors.kSmallBorderRadius,
                  ),
                ),
                child: Icon(
                  Icons.chat_outlined,
                  color: AppColors.primary,
                  size: R.iconSize(context),
                ),
              ),
              SizedBox(width: R.spacing(context)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.title.isNotEmpty ? session.title : '未命名会话',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: R.bodyFontSize(context),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: R.smallSpacing(context) / 2),
                    Text(
                      timeStr,
                      style: TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: R.labelFontSize(context),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: AppColors.textTertiary,
                size: R.smallIconSize(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
