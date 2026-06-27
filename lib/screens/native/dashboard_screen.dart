import 'package:flutter/material.dart';
import '../../models.dart';
import '../../theme.dart';
import '../../services/storage_service.dart';
import '../../services/opencode_api.dart';
import '../../utils/time_format.dart';
import '../settings_sheet.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/app_bottom_sheet.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/app_states.dart';
import 'session_list_screen.dart';
import 'file_browser_screen.dart';
import 'project_screen.dart';
import 'config_screen.dart';
import 'chat_screen.dart';

class DashboardScreen extends StatefulWidget {
  final ServerEntry entry;
  final OpenCodeApi? api;

  const DashboardScreen({super.key, required this.entry, this.api});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late OpenCodeApi _api;
  late ServerEntry _entry;
  HealthStatus? _health;
  List<Session> _recentSessions = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _entry = widget.entry;
    _initApi();
    _load();
  }

  void _initApi() {
    if (widget.api != null) {
      _api = widget.api!;
      return;
    }
    _api = OpenCodeApi(
      baseUrl: _entry.url,
      username: _entry.username,
      password: _entry.password,
    );
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final health = await _api.getHealth();
      final sessions = await _api.getSessions();
      sessions.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      setState(() {
        _health = health;
        _recentSessions = sessions.take(5).toList();
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

  void _openSettings() {
    AppBottomSheet.show(
      context: context,
      child: SettingsSheet(entry: _entry, currentMode: AppMode.native),
    );
  }

  Future<void> _switchServer() async {
    final servers = await StorageService.loadServers();
    if (!mounted) return;

    final selected = await AppBottomSheet.show<ServerEntry>(
      context: context,
      child: Builder(
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text('切换服务器', style: TextStyle(color: AppColors.textPrimary, fontSize: 16)),
              ),
              const Divider(),
              ...servers.map((s) => ListTile(
                leading: Icon(Icons.computer, color: s.id == _entry.id ? AppColors.primary : AppColors.textSecondary),
                title: Text(s.name, style: TextStyle(color: s.id == _entry.id ? AppColors.primary : AppColors.textPrimary)),
                subtitle: Text(s.url, style: TextStyle(color: AppColors.textTertiary, fontSize: 12)),
                onTap: () => Navigator.pop(ctx, s),
              )),
            ],
          ),
        ),
      ),
    );

    if (selected != null && selected.id != _entry.id) {
      selected.lastUsed = DateTime.now().millisecondsSinceEpoch;
      await StorageService.addOrUpdate(selected);
      await StorageService.setLastSelectedId(selected.id);
      setState(() {
        _entry = selected;
        _loading = true;
      });
      _initApi();
      _load();
    }
  }

  Future<void> _showAuthDialog() async {
    final providerID = await AppDialog.showTextInput(
      context,
      title: '设置认证',
      hintText: 'provider ID (如 openai)',
    );
    if (providerID == null || providerID.isEmpty) return;
    final apiKey = await AppDialog.showTextInput(
      context,
      title: 'API Key',
      hintText: 'sk-...',
      obscureText: true,
    );
    if (apiKey == null || apiKey.isEmpty) return;
    try {
      await _api.setAuth(providerID, {'apiKey': apiKey});
      if (mounted) AppSnackBar.success(context, '认证已设置');
    } catch (e) {
      if (mounted) AppSnackBar.error(context, '设置认证失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz, color: AppColors.textSecondary),
            tooltip: '切换服务器',
            onPressed: _switchServer,
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: AppColors.textSecondary),
            onPressed: _openSettings,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
            onSelected: (v) async {
              if (v == 'dispose') {
                try {
                  await _api.disposeInstance();
                  if (mounted) AppSnackBar.show(context, '实例已销毁');
                } catch (e) {
                  if (mounted) AppSnackBar.error(context, '销毁失败: $e');
                }
              } else if (v == 'log') {
                await _api.writeLog('client', 'info', 'Dashboard health check from remote app', extra: {'url': _entry.url});
                if (mounted) AppSnackBar.show(context, '日志已写入');
              } else if (v == 'auth') {
                await _showAuthDialog();
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'dispose', child: ListTile(leading: Icon(Icons.power_settings_new, size: 18), title: Text('销毁实例', style: TextStyle(fontSize: 13)))),
              const PopupMenuItem(value: 'log', child: ListTile(leading: Icon(Icons.article, size: 18), title: Text('写入诊断日志', style: TextStyle(fontSize: 13)))),
              const PopupMenuItem(value: 'auth', child: ListTile(leading: Icon(Icons.key, size: 18), title: Text('设置认证', style: TextStyle(fontSize: 13)))),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _load,
        child: _loading
            ? const AppLoadingIndicator()
            : _error != null
                ? _errorView()
                : _buildContent(),
      ),
    );
  }

  Widget _errorView() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 40),
        Icon(Icons.cloud_off, size: 48, color: AppColors.textTertiary),
        const SizedBox(height: 12),
        Text('连接失败', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
        const SizedBox(height: 8),
        Text(_error!, style: TextStyle(color: AppColors.textTertiary, fontSize: 12), textAlign: TextAlign.center),
        const SizedBox(height: 20),
        FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
          onPressed: _load,
          icon: const Icon(Icons.refresh, size: 18),
          label: const Text('重试'),
        ),
      ],
    );
  }

  Widget _buildContent() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _StatusCard(health: _health, url: widget.entry.url),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('最近会话', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => SessionListScreen(entry: widget.entry, api: _api),
              )),
              child: const Text('查看全部', style: TextStyle(color: AppColors.primary, fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ..._recentSessions.map((s) => _SessionCard(session: s, api: _api, entry: widget.entry)),
        if (_recentSessions.isEmpty)
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text('暂无会话', style: TextStyle(color: AppColors.textTertiary, fontSize: 13)),
          ),
        const SizedBox(height: 20),
        _QuickActions(api: _api, entry: widget.entry),
      ],
    );
  }
}

class _StatusCard extends StatelessWidget {
  final HealthStatus? health;
  final String url;

  const _StatusCard({required this.health, required this.url});

  @override
  Widget build(BuildContext context) {
    final uri = Uri.tryParse(url);
    final host = uri != null && uri.host.isNotEmpty ? '${uri.host}:${uri.port}' : url;
    final isHealthy = health?.healthy ?? false;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppColors.kDefaultBorderRadius),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(color: AppColors.shadow, blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 12, height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isHealthy ? AppColors.success : AppColors.danger,
              boxShadow: [
                BoxShadow(
                  color: (isHealthy ? AppColors.success : AppColors.danger).withValues(alpha: 0.4),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(host, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(
                  isHealthy ? 'v${health?.version ?? "?"} \u00b7 已连接' : '无法连接',
                  style: TextStyle(color: isHealthy ? AppColors.success : AppColors.danger, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isHealthy ? AppColors.success.withValues(alpha: 0.1) : AppColors.danger.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppColors.kChipBorderRadius),
            ),
            child: Text(
              isHealthy ? '在线' : '离线',
              style: TextStyle(
                color: isHealthy ? AppColors.success : AppColors.danger,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final Session session;
  final OpenCodeApi api;
  final ServerEntry entry;

  const _SessionCard({required this.session, required this.api, required this.entry});

  @override
  Widget build(BuildContext context) {
    final timeStr = formatRelativeTime(session.updatedAt);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: AppCard(
        borderRadius: AppColors.kCardBorderRadius,
        padding: EdgeInsets.zero,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppColors.kCardBorderRadius),
          onTap: () {
            Navigator.push(context, MaterialPageRoute(
              builder: (_) => ChatScreen(session: session, entry: entry, api: api),
            ));
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(AppColors.kSmallBorderRadius),
                  ),
                  child: const Icon(Icons.chat, color: AppColors.primary, size: 16),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(session.title.isNotEmpty ? session.title : '未命名会话',
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
                      const SizedBox(height: 2),
                      Text(timeStr, style: TextStyle(color: AppColors.textTertiary, fontSize: 11)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: AppColors.textTertiary, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  final OpenCodeApi api;
  final ServerEntry entry;

  const _QuickActions({required this.api, required this.entry});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('快捷操作', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _ActionButton(icon: Icons.add, label: '新建会话', color: AppColors.primary, onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => SessionListScreen(entry: entry, api: api)));
            })),
            const SizedBox(width: 8),
            Expanded(child: _ActionButton(icon: Icons.folder, label: '文件浏览', color: AppColors.success, onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => FileBrowserScreen(entry: entry, api: api)));
            })),
            const SizedBox(width: 8),
            Expanded(child: _ActionButton(icon: Icons.swap_horiz, label: '切换项目', color: AppColors.warning, onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => ProjectScreen(entry: entry, api: api)));
            })),
            const SizedBox(width: 8),
            Expanded(child: _ActionButton(icon: Icons.monitor_heart, label: '诊断', color: AppColors.primary, onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => ConfigScreen(entry: entry, api: api)));
            })),
          ],
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppColors.kCardBorderRadius),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

