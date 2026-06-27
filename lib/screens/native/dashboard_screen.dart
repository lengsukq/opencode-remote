import 'package:flutter/material.dart';
import '../../models.dart';
import '../../strings.dart';
import '../../theme.dart';
import '../../services/storage_service.dart';
import '../../services/opencode_api.dart';

import '../settings_sheet.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/app_bottom_sheet.dart';

import '../../widgets/app_snackbar.dart';
import '../../widgets/app_states.dart';
import 'session_list_screen.dart';
import '../../widgets/dashboard_cards.dart';

class DashboardScreen extends StatefulWidget {
  final ServerEntry entry;
  final OpenCodeApi? api;
  final Project? activeProject;

  const DashboardScreen({super.key, required this.entry, this.api, this.activeProject});

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

  @override
  void didUpdateWidget(DashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeProject?.id != widget.activeProject?.id) {
      _load();
    }
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
      List<Session> filtered;
      if (widget.activeProject != null) {
        final projDir = widget.activeProject!.path;
        filtered = sessions
            .where((s) => s.directory == projDir || s.projectId == widget.activeProject!.id)
            .take(5)
            .toList();
      } else {
        filtered = sessions.take(5).toList();
      }
      if (!mounted) return;
      setState(() {
        _health = health;
        _recentSessions = filtered;
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
      if (!mounted) return;
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
      title: S.setAuth,
      hintText: S.providerIdHint,
    );
    if (providerID == null || providerID.isEmpty) return;
    final apiKey = await AppDialog.showTextInput(
      context,
      title: S.apiKey,
      hintText: S.apiKeyHint,
      obscureText: true,
    );
    if (apiKey == null || apiKey.isEmpty) return;
    try {
      await _api.setAuth(providerID, {'apiKey': apiKey});
      if (mounted) AppSnackBar.success(context, '认证已设置');
    } catch (e) {
      if (mounted) AppSnackBar.error(context, S.setAuthFailed(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.activeProject != null ? 'Dashboard - ${widget.activeProject!.name}' : S.dashboard),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz, color: AppColors.textSecondary),
            tooltip: S.switchServer,
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
                  if (mounted) AppSnackBar.show(context, S.instanceDisposed);
                } catch (e) {
                  if (mounted) AppSnackBar.error(context, S.disposeFailed(e));
                }
              } else if (v == 'log') {
                await _api.writeLog('client', 'info', 'Dashboard health check from remote app', extra: {'url': _entry.url});
                if (mounted) AppSnackBar.show(context, S.logWritten);
              } else if (v == 'auth') {
                await _showAuthDialog();
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'dispose', child: ListTile(leading: Icon(Icons.power_settings_new, size: 18), title: Text(S.disposeInstance, style: TextStyle(fontSize: 13)))),
              const PopupMenuItem(value: 'log', child: ListTile(leading: Icon(Icons.article, size: 18), title: Text(S.writeDiagnosticLog, style: TextStyle(fontSize: 13)))),
              const PopupMenuItem(value: 'auth', child: ListTile(leading: Icon(Icons.key, size: 18), title: Text(S.setAuth, style: TextStyle(fontSize: 13)))),
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
        Text(S.connectionFailed, style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
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
        DashboardStatusCard(health: _health, url: widget.entry.url),
        if (widget.activeProject != null) ...[
          const SizedBox(height: 16),
          DashboardProjectContextCard(project: widget.activeProject!),
        ],
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(S.recentSessions, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => SessionListScreen(entry: widget.entry, api: _api, activeProject: widget.activeProject),
              )),
              child: const Text(S.viewAll, style: TextStyle(color: AppColors.primary, fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ..._recentSessions.map((s) => DashboardSessionCard(session: s, api: _api, entry: widget.entry, activeProject: widget.activeProject)),
        if (_recentSessions.isEmpty)
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              widget.activeProject != null ? "'${widget.activeProject!.name}' ${S.noSessions}" : S.noSessions,
              style: TextStyle(color: AppColors.textTertiary, fontSize: 13),
            ),
          ),
        const SizedBox(height: 20),
        DashboardQuickActions(api: _api, entry: widget.entry, activeProject: widget.activeProject),
      ],
    );
  }

}
