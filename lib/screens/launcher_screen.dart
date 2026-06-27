import 'package:flutter/material.dart';
import '../models.dart';
import '../theme.dart';
import '../services/storage_service.dart';
import '../utils/time_format.dart';
import '../widgets/server_edit_dialog.dart';
import 'settings_sheet.dart';
import 'webview_screen.dart';
import '../widgets/main_scaffold.dart';
import '../strings.dart';
import '../widgets/app_bottom_sheet.dart';
import '../widgets/app_states.dart';
import '../widgets/app_card.dart';

class LauncherScreen extends StatefulWidget {
  final AppMode? initialMode;
  final ServerEntry? initialEntry;

  const LauncherScreen({super.key, this.initialMode, this.initialEntry});

  @override
  State<LauncherScreen> createState() => _LauncherScreenState();
}

class _LauncherScreenState extends State<LauncherScreen> {
  List<ServerEntry> _servers = [];
  bool _loading = true;
  late AppMode _mode;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode ?? AppMode.webview;
    if (widget.initialEntry != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openServerDirect(widget.initialEntry!);
      });
    }
    _reload();
  }

  Future<void> _reload() async {
    final servers = await StorageService.loadServers();
    if (!mounted) return;
    setState(() {
      _servers = servers;
      _loading = false;
    });
  }

  Future<void> _openServerDirect(ServerEntry entry) async {
    if (!mounted) return;
    final target = _mode == AppMode.native
        ? MainScaffold(entry: entry) as Widget
        : WebViewScreen(entry: entry) as Widget;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => target),
      (route) => false,
    );
  }

  Future<void> _openServer(ServerEntry entry) async {
    entry.lastUsed = DateTime.now().millisecondsSinceEpoch;
    await StorageService.addOrUpdate(entry);
    await StorageService.setLastSelectedId(entry.id);
    if (!mounted) return;
    await _openServerDirect(entry);
  }

  void _openSettings() {
    AppBottomSheet.show(
      context: context,
      child: SettingsSheet(
        entry: _servers.isNotEmpty ? _servers.first : ServerEntry(name: '', url: ''),
        currentMode: _mode,
      ),
    );
  }

  Future<void> _addServer({ServerEntry? existing}) async {
    final result = await showDialog<ServerEntry>(
      context: context,
      builder: (_) => AppServerEditDialog(existing: existing),
    );
    if (result == null) return;
    await StorageService.addOrUpdate(result);
    await _reload();
  }

  Future<void> _deleteServer(ServerEntry entry) async {
    await StorageService.delete(entry.id);
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            const Text('OpenCode Remote'),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _mode == AppMode.native
                    ? AppColors.primaryLight
                    : const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(AppColors.kChipBorderRadius),
              ),
              child: Text(
                _mode == AppMode.native ? S.nativeMode : S.webviewMode,
                style: TextStyle(
                  fontSize: 10,
                  color: _mode == AppMode.native ? AppColors.primary : AppColors.success,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: AppColors.textSecondary),
            tooltip: S.settings,
            onPressed: _openSettings,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(S.servers, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _loading
                  ? const AppLoadingIndicator()
                  : _servers.isEmpty
                      ? _emptyState()
                      : _serverList(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => _addServer(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.dns_outlined, size: 48, color: AppColors.textTertiary),
          const SizedBox(height: 16),
          Text(S.noServers, style: TextStyle(color: AppColors.textSecondary, fontSize: 15)),
          const SizedBox(height: 8),
          Text(S.clickToAdd, style: TextStyle(color: AppColors.textTertiary, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _serverList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: _servers.length,
      itemBuilder: (context, index) {
        final entry = _servers[index];
        return Dismissible(
          key: ValueKey(entry.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            margin: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.danger,
              borderRadius: BorderRadius.circular(AppColors.kCardBorderRadius),
            ),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          confirmDismiss: (_) async {
            await _deleteServer(entry);
            return false;
          },
          child: _ServerCard(
            entry: entry,
            timeStr: formatRelativeTime(entry.lastUsed),
            onTap: () => _openServer(entry),
            onLongPress: () => _addServer(existing: entry),
          ),
        );
      },
    );
  }
}

class _ServerCard extends StatelessWidget {
  final ServerEntry entry;
  final String timeStr;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _ServerCard({
    required this.entry,
    required this.timeStr,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final uri = Uri.tryParse(entry.url);
    final host = uri != null && uri.host.isNotEmpty ? '${uri.host}:${uri.port}' : entry.url;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: AppCard(
        child: InkWell(
        borderRadius: BorderRadius.circular(AppColors.kCardBorderRadius),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(AppColors.kSmallBorderRadius),
                ),
                child: const Icon(Icons.computer, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.name,
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 3),
                    Text(host,
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    const SizedBox(height: 2),
                    Text('${S.lastUsed} $timeStr',
                        style: TextStyle(color: AppColors.textTertiary, fontSize: 11)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: AppColors.textTertiary, size: 20),
            ],
          ),
        ),
      ),
      ),
    );
  }
}
