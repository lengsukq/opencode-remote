import 'package:flutter/material.dart';
import '../../models.dart';
import '../../strings.dart';
import '../../theme.dart';
import '../../services/storage_service.dart';
import '../../services/opencode_api.dart';

import '../../utils/animations.dart';
import '../../utils/responsive_values.dart';
import '../../utils/glass_effect.dart';

import '../settings_sheet.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/app_bottom_sheet.dart';

import '../../widgets/app_snackbar.dart';
import '../../widgets/app_states.dart';
import 'session_list_screen.dart';
import '../../widgets/dashboard_cards.dart';

class DashboardScreen extends StatefulWidget {
  final ServerEntry entry;
  final OpenCodeApi api;
  final Project? activeProject;

  const DashboardScreen({
    super.key,
    required this.entry,
    required this.api,
    this.activeProject,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late ServerEntry _entry;
  HealthStatus? _health;
  List<Session> _recentSessions = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _entry = widget.entry;
    _load();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void didUpdateWidget(DashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeProject?.id != widget.activeProject?.id) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final health = await widget.api.getHealth();
      final sessions = await widget.api.getSessions();
      sessions.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      List<Session> filtered;
      if (widget.activeProject != null) {
        final projDir = widget.activeProject!.path;
        filtered = sessions
            .where(
              (s) =>
                  s.directory == projDir ||
                  s.projectId == widget.activeProject!.id,
            )
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
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  S.switchServer,
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
                ),
              ),
              const Divider(),
              ...servers.map(
                (s) => ListTile(
                  leading: Icon(
                    Icons.computer,
                    color: s.id == _entry.id
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                  title: Text(
                    s.name,
                    style: TextStyle(
                      color: s.id == _entry.id
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    s.url,
                    style: const TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 12,
                    ),
                  ),
                  onTap: () => Navigator.pop(ctx, s),
                ),
              ),
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
    if (!mounted) return;
    final apiKey = await AppDialog.showTextInput(
      context,
      title: S.apiKey,
      hintText: S.apiKeyHint,
      obscureText: true,
    );
    if (apiKey == null || apiKey.isEmpty) return;
    try {
      await widget.api.setAuth(providerID, {'apiKey': apiKey});
      if (mounted) AppSnackBar.success(context, S.authSet);
    } catch (e) {
      if (mounted) AppSnackBar.error(context, S.setAuthFailed(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.activeProject != null
              ? 'Dashboard - ${widget.activeProject!.name}'
              : S.dashboard,
        ),
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
                  await widget.api.disposeInstance();
                  if (mounted) {
                    AppSnackBar.show(context, S.instanceDisposed);
                  }
                } catch (e) {
                  if (mounted) {
                    AppSnackBar.error(context, S.disposeFailed(e));
                  }
                }
              } else if (v == 'log') {
                await widget.api.writeLog(
                  'client',
                  'info',
                  'Dashboard health check from remote app',
                  extra: {'url': _entry.url},
                );
                if (mounted) AppSnackBar.show(context, S.logWritten);
              } else if (v == 'auth') {
                await _showAuthDialog();
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'dispose',
                child: ListTile(
                  leading: Icon(Icons.power_settings_new, size: 18),
                  title: Text(
                    S.disposeInstance,
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ),
              const PopupMenuItem(
                value: 'log',
                child: ListTile(
                  leading: Icon(Icons.article, size: 18),
                  title: Text(
                    S.writeDiagnosticLog,
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ),
              const PopupMenuItem(
                value: 'auth',
                child: ListTile(
                  leading: Icon(Icons.key, size: 18),
                  title: Text(S.setAuth, style: TextStyle(fontSize: 13)),
                ),
              ),
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
      padding: R.screenPadding(context),
      children: [
        SizedBox(height: R.largeSpacing(context)),
        Icon(
          Icons.cloud_off,
          size: R.iconSize(context) * 2.4,
          color: AppColors.textTertiary,
        ),
        SizedBox(height: R.spacing(context)),
        Text(
          S.connectionFailed,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: R.bodyFontSize(context),
          ),
        ),
        SizedBox(height: R.smallSpacing(context)),
        Text(
          _error!,
          style: TextStyle(
            color: AppColors.textTertiary,
            fontSize: R.smallFontSize(context),
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: R.mediumSpacing(context)),
        FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
          onPressed: _load,
          icon: Icon(Icons.refresh, size: R.smallIconSize(context)),
          label: Text(
            S.retry,
            style: TextStyle(fontSize: R.bodyFontSize(context)),
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    return ListView(
      padding: R.screenPadding(context),
      children: [
        GlassCard(
          padding: EdgeInsets.zero,
          child: DashboardStatusCard(health: _health, url: widget.entry.url),
        ),
        if (widget.activeProject != null) ...[
          SizedBox(height: R.mediumSpacing(context)),
          GlassCard(
            padding: EdgeInsets.zero,
            child: DashboardProjectContextCard(project: widget.activeProject!),
          ),
        ],
        SizedBox(height: R.mediumSpacing(context)),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              S.recentSessions,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: R.smallFontSize(context),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                AppAnimations.slideInRoute(
                  SessionListScreen(
                    entry: widget.entry,
                    api: widget.api,
                    activeProject: widget.activeProject,
                  ),
                ),
              ),
              child: Text(
                S.viewAll,
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: R.smallFontSize(context),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: R.smallSpacing(context)),
        ..._recentSessions.asMap().entries.map(
          (entry) => AppAnimations.listItemAnimation(
            index: entry.key,
            child: DashboardSessionCard(
              session: entry.value,
              api: widget.api,
              entry: widget.entry,
              activeProject: widget.activeProject,
            ),
          ),
        ),
        if (_recentSessions.isEmpty)
          Padding(
            padding: R.screenPadding(context),
            child: Text(
              widget.activeProject != null
                  ? "'${widget.activeProject!.name}' ${S.noSessions}"
                  : S.noSessions,
              style: TextStyle(
                color: AppColors.textTertiary,
                fontSize: R.bodyFontSize(context),
              ),
            ),
          ),
        SizedBox(height: R.mediumSpacing(context)),
        GlassCard(
          padding: EdgeInsets.zero,
          child: DashboardQuickActions(
            api: widget.api,
            entry: widget.entry,
            activeProject: widget.activeProject,
          ),
        ),
      ],
    );
  }
}
