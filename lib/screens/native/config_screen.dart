import 'package:flutter/material.dart';
import '../../models.dart';
import '../../theme.dart';
import '../../services/opencode_api.dart';

class ConfigScreen extends StatefulWidget {
  final ServerEntry entry;
  final OpenCodeApi api;

  const ConfigScreen({super.key, required this.entry, required this.api});

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
      final results = await Future.wait([
        _safeCall(() => widget.api.getConfig()),
        _safeCall(() => widget.api.getConfigProviders()),
        _safeCall(() => widget.api.getLspStatus()),
        _safeCall(() => widget.api.getFormatterStatus()),
        _safeCall(() => widget.api.getMcpStatus()),
        _safeCall(() => widget.api.getProviderAuth()),
      ]);
      setState(() {
        _config = results[0] as Config?;
        _configProviders = results[1] as Map<String, dynamic>?;
        _lsp = (results[2] as List<dynamic>?)?.map((e) => LSPStatus.fromJson(e as Map<String, dynamic>)).toList() ?? [];
        _formatters = (results[3] as List<dynamic>?)?.map((e) => FormatterStatus.fromJson(e as Map<String, dynamic>)).toList() ?? [];
        final mcpRaw = results[4] as Map<String, dynamic>? ?? {};
        _mcp = mcpRaw.map((k, v) => MapEntry(k, MCPStatus.fromJson(v as Map<String, dynamic>)));
        final authRaw = results[5] as Map<String, dynamic>? ?? {};
        _authMethods = authRaw.map((k, v) {
          final list = (v as List<dynamic>?)?.map((e) => ProviderAuthMethod.fromJson(e as Map<String, dynamic>)).toList() ?? [];
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
    } catch (_) {
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
        title: const Text('ÃÌº”/∏¸–¬≈‰÷√', style: TextStyle(color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: keyCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: '≈‰÷√º¸',
                hintStyle: TextStyle(color: AppColors.textTertiary),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.border)),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.borderFocused)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: valueCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: '≈‰÷√÷µ',
                hintStyle: TextStyle(color: AppColors.textTertiary),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.border)),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.borderFocused)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('»°œ˚', style: TextStyle(color: AppColors.textSecondary))),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('±£¥Ê'),
          ),
        ],
      ),
    );
    if (result != true || keyCtrl.text.isEmpty) return;
    try {
      await widget.api.patchConfig({keyCtrl.text.trim(): valueCtrl.text.trim()});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('≈‰÷√“—∏¸–¬')));
        _load();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('∏¸–¬ ß∞‹: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('ËØäÊñ≠‰∏éÈÖçÁΩ?),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? Center(child: Text(_error!, style: TextStyle(color: AppColors.textSecondary)))
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _sectionHeader('ÈÖçÁΩÆ'),
                      _configCard(),
                      const SizedBox(height: 20),
                      _sectionHeader('Êèê‰æõÂïÜ‰∏éÈªòËÆ§Ê®°Âûã'),
                      _providersCard(),
                      const SizedBox(height: 20),
                      _sectionHeader('Â∑•ÂÖ∑Áä∂ÊÄ?),
                      _toolsCard(),
                      const SizedBox(height: 20),
                      _sectionHeader('ËÆ§ËØÅÊñπÂºè'),
                      _authCard(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  Widget _configCard() {
    if (_config == null) return _card('Âä†ËΩΩÈÖçÁΩÆÂ§±Ë¥•', Icons.error, AppColors.danger);
    final data = _config!.data;
    final entries = data.entries.take(10).toList();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
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
              child: Text('... ËøòÊúâ ${data.length - 10} È°?, style: TextStyle(color: AppColors.textTertiary, fontSize: 11)),
            ),
        ],
      ),
    );
  }

  Widget _providersCard() {
    if (_configProviders == null) return _card('Âä†ËΩΩÂ§±Ë¥•', Icons.error, AppColors.danger);
    final providers = _configProviders!['providers'] as List<dynamic>? ?? [];
    final defaults = _configProviders!['default'] as Map<String, dynamic>? ?? {};
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ÈªòËÆ§Ê®°Âûã:', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 4),
          ...defaults.entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text('  ${e.key}: ${e.value}', style: TextStyle(color: AppColors.textPrimary, fontSize: 12, fontFamily: 'monospace')),
          )),
          if (defaults.isEmpty) Text('  Êó†ÈªòËÆ§Ê®°Âû?, style: TextStyle(color: AppColors.textTertiary, fontSize: 12)),
          if (providers.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Êèê‰æõÂï?(${providers.length}):', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 4),
            ...providers.take(10).map((p) {
              final pMap = p as Map<String, dynamic>;
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
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _toolGroup('LSP ÊúçÂä°Âô?, _lsp.map((l) => _toolEntry(l.name, l.state)).toList()),
          const SizedBox(height: 12),
          _toolGroup('Ê†ºÂºèÂåñÂô®', _formatters.map((f) => _toolEntry(f.name, f.state)).toList()),
          const SizedBox(height: 12),
          _toolGroup('MCP ÊúçÂä°Âô?, _mcp.entries.map((e) => _toolEntry(e.key, e.value.state)).toList()),
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
          Text('  Êó?, style: TextStyle(color: AppColors.textTertiary, fontSize: 12))
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
    if (_authMethods.isEmpty) return _card('Êó†ËÆ§ËØÅ‰ø°ÊÅ?, Icons.info_outline, AppColors.textSecondary);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
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
                child: Text('Á±ªÂûã: ${a.type}${a.url != null ? ', URL: ${a.url}' : ''}', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontFamily: 'monospace')),
              )),
            ],
          ),
        )).toList(),
      ),
    );
  }

  Widget _card(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
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
