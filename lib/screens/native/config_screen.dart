import 'package:flutter/material.dart';
import '../../models.dart';
import '../../theme.dart';
import '../../services/opencode_api.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_input_decoration.dart';
import '../../widgets/app_section_header.dart';
import '../../widgets/app_snackbar.dart';
import '../../strings.dart';
import '../../widgets/app_states.dart';

class ConfigScreen extends StatefulWidget {
  final ServerEntry entry;
  final OpenCodeApi api;
  final Project? activeProject;

  const ConfigScreen({super.key, required this.entry, required this.api, this.activeProject});

  @override
  State<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen> {
  bool _loading = true;
  String? _error;

  Config? _config;
  Map<String, dynamic>? _configProviders;
  List<LSPStatus> _lsp = [];
  List<FormatterStatus> _formatters = [];
  Map<String, MCPStatus> _mcp = {};
  Map<String, List<ProviderAuthMethod>> _authMethods = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final config = await _safeCall(() => widget.api.getConfig());
      final configProviders = await _safeCall(() => widget.api.getConfigProviders());
      final lspRaw = await _safeCall(() => widget.api.getLspStatus());
      final formattersRaw = await _safeCall(() => widget.api.getFormatterStatus());
      final mcpRaw = await _safeCall(() => widget.api.getMcpStatus());
      final authRaw = await _safeCall(() => widget.api.getProviderAuth());
      setState(() {
        _config = config is Config ? config : null;
        _configProviders = configProviders is Map<String, dynamic> ? configProviders : null;
        _lsp = (lspRaw is List ? lspRaw.map((e) => LSPStatus.fromJson(e is Map<String, dynamic> ? e : {})).toList() : []);
        _formatters = (formattersRaw is List ? formattersRaw.map((e) => FormatterStatus.fromJson(e is Map<String, dynamic> ? e : {})).toList() : []);
        final mcpData = mcpRaw is Map<String, dynamic> ? mcpRaw : <String, dynamic>{};
        _mcp = mcpData.map((k, v) => MapEntry(k, MCPStatus.fromJson(v is Map<String, dynamic> ? v : {})));
        final authData = authRaw is Map<String, dynamic> ? authRaw : <String, dynamic>{};
        _authMethods = authData.map((k, v) {
          final list = v is List ? v.map((e) => ProviderAuthMethod.fromJson(e is Map<String, dynamic> ? e : {})).toList() : <ProviderAuthMethod>[];
          return MapEntry(k, list);
        });
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

  Future<dynamic> _safeCall(Future Function() fn) async {
    try {
      return await fn();
    } catch (e) {
      // ignore: use_debug_print_in_production
      debugPrint('ConfigScreen._safeCall: $e');
      return null;
    }
  }

  Future<void> _editConfig(Map<String, dynamic> currentData) async {
    final keyCtrl = TextEditingController();
    final valueCtrl = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(S.addUpdateConfig, style: TextStyle(color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: keyCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: AppInputDecoration.standard(hintText: S.configKey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: valueCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: AppInputDecoration.standard(hintText: S.configValue),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(S.cancel, style: TextStyle(color: AppColors.textSecondary))),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(S.save),
          ),
        ],
      ),
    );
    if (result != true || keyCtrl.text.isEmpty) return;
    try {
      await widget.api.patchConfig({keyCtrl.text.trim(): valueCtrl.text.trim()});
      if (mounted) {
        AppSnackBar.success(context, S.configUpdated);
        _load();
      }
    } catch (e) {
      if (mounted) AppSnackBar.error(context, '${S.updateFailed}: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(S.diagnosticsAndConfig),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? const AppLoadingIndicator()
          : _error != null
              ? Center(child: Text(_error!, style: TextStyle(color: AppColors.textSecondary)))
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _sectionHeader('配置'),
                      _configCard(),
                      const SizedBox(height: 20),
                      _sectionHeader('提供商与默认模型'),
                      _providersCard(),
                      const SizedBox(height: 20),
                      _sectionHeader('工具状态'),
                      _toolsCard(),
                      const SizedBox(height: 20),
                      _sectionHeader('认证方式'),
                      _authCard(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
    );
  }

  Widget _sectionHeader(String title) {
    return AppSectionHeader(title);
  }

  Widget _configCard() {
    if (_config == null) return _card('加载配置失败', Icons.error, AppColors.danger);
    final data = _config!.data;
    final entries = data.entries.take(10).toList();
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...entries.map((e) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 100,
                  child: Text('${e.key}:', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ),
                Expanded(
                  child: Text(
                    '${e.value}'.length > 80 ? '${'${e.value}'.substring(0, 80)}...' : '${e.value}',
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontFamily: 'monospace'),
                  ),
                ),
              ],
            ),
          )),
          if (data.length > 10)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('... 还有 ${data.length - 10} 项', style: TextStyle(color: AppColors.textTertiary, fontSize: 11)),
            ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              icon: const Icon(Icons.edit, size: 14),
              label: Text(S.edit, style: TextStyle(fontSize: 12)),
              onPressed: () => _editConfig(data),
            ),
          ),
        ],
      ),
    );
  }

  Widget _providersCard() {
    if (_configProviders == null) return _card('加载失败', Icons.error, AppColors.danger);
    final rawProviders = _configProviders!['providers'];
    final rawDefaults = _configProviders!['default'];
    final providers = rawProviders is List ? rawProviders : <dynamic>[];
    final defaults = rawDefaults is Map ? Map<String, dynamic>.from(rawDefaults) : <String, dynamic>{};
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(S.defaultModel, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 4),
          ...defaults.entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text('  ${e.key}: ${e.value}', style: TextStyle(color: AppColors.textPrimary, fontSize: 12, fontFamily: 'monospace')),
          )),
          if (defaults.isEmpty) Text('  ${S.noDefaultModel}', style: TextStyle(color: AppColors.textTertiary, fontSize: 12)),
          if (providers.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('提供商 (${providers.length}):', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 4),
            ...providers.take(10).map((p) {
              final pMap = p is Map<String, dynamic> ? p : <String, dynamic>{};
              return Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text('  ${pMap['id'] ?? pMap['name'] ?? '?'}', style: TextStyle(color: AppColors.textPrimary, fontSize: 12, fontFamily: 'monospace')),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _toolsCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _toolGroup(S.lspServer, _lsp.map((l) => _toolEntry(l.name, l.state)).toList()),
          const SizedBox(height: 12),
          _toolGroup(S.formatter, _formatters.map((f) => _toolEntry(f.name, f.enabled ? 'enabled' : 'disabled')).toList()),
          const SizedBox(height: 12),
          _toolGroup(S.mcpServer, _mcp.entries.map((e) => _toolEntry(e.key, e.value.status)).toList()),
        ],
      ),
    );
  }

  Widget _toolGroup(String title, List<Widget> entries) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        if (entries.isEmpty)
          Text('  无', style: TextStyle(color: AppColors.textTertiary, fontSize: 12))
        else
          ...entries,
      ],
    );
  }

  Widget _toolEntry(String name, String state) {
    final isRunning = state == 'running' || state == 'connected' || state == 'ready';
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isRunning ? AppColors.success : AppColors.danger,
            ),
          ),
          const SizedBox(width: 6),
          Text(name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontFamily: 'monospace')),
          const Spacer(),
          Text(state, style: TextStyle(color: isRunning ? AppColors.success : AppColors.textTertiary, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _authCard() {
    if (_authMethods.isEmpty) return _card(S.noAuthInfo, Icons.info_outline, AppColors.textSecondary);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _authMethods.entries.map((e) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(e.key, style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
              ...e.value.map((a) => Padding(
                padding: const EdgeInsets.only(left: 12, top: 2),
                child: Text('类型: ${a.type}${a.label.isNotEmpty ? ', 标签: ${a.label}' : ''}', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontFamily: 'monospace')),
              )),
            ],
          ),
        )).toList(),
      ),
    );
  }

  Widget _card(String text, IconData icon, Color color) {
    return AppCard(
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }
}
