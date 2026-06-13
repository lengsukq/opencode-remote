import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../models.dart';
import '../theme.dart';
import '../services/storage_service.dart';
import 'launcher_screen.dart';

class WebViewScreen extends StatefulWidget {
  final ServerEntry entry;

  const WebViewScreen({super.key, required this.entry});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late WebViewController _controller;
  bool _loading = true;
  late ServerEntry _entry;

  @override
  void initState() {
    super.initState();
    _entry = widget.entry;
    _initWebView();
  }

  void _initWebView() {
    final url = _entry.url;
    final password = _entry.password;
    final username = _entry.username;

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) => setState(() => _loading = true),
        onPageFinished: (_) => setState(() => _loading = false),
        onWebResourceError: (error) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('加载失败: ${error.description}')),
            );
          }
        },
      ));

    if (password.isNotEmpty) {
      final bytes = utf8.encode('$username:$password');
      final auth = base64.encode(bytes);
      _controller.loadRequest(
        Uri.parse(url),
        headers: {'Authorization': 'Basic $auth'},
      );
    } else {
      _controller.loadRequest(Uri.parse(url));
    }
  }

  Future<void> _switchServer() async {
    final servers = await StorageService.loadServers();
    if (!mounted) return;

    final selected = await showModalBottomSheet<ServerEntry>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
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
            const Divider(),
            ListTile(
              leading: Icon(Icons.add, color: AppColors.textSecondary),
              title: const Text('添加新服务器', style: TextStyle(color: AppColors.textPrimary)),
              onTap: () {
                Navigator.pop(ctx);
                WidgetsBinding.instance.addPostFrameCallback((_) => _addNew());
              },
            ),
            const SizedBox(height: 8),
          ],
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
      _initWebView();
    }
  }

  Future<void> _addNew() async {
    final result = await showDialog<ServerEntry>(
      context: context,
      builder: (_) => _EditDialog(),
    );
    if (result != null) {
      result.lastUsed = DateTime.now().millisecondsSinceEpoch;
      await StorageService.addOrUpdate(result);
      await StorageService.setLastSelectedId(result.id);
      setState(() {
        _entry = result;
        _loading = true;
      });
      _initWebView();
    }
  }

  Future<void> _backToLauncher() async {
    await Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LauncherScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(_entry.name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 16)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textSecondary),
            onPressed: _backToLauncher,
          ),
          actions: [
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: SizedBox(
                  width: 18, height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                ),
              ),
            IconButton(
              icon: const Icon(Icons.swap_horiz, color: AppColors.textSecondary),
              tooltip: '切换服务器',
              onPressed: _switchServer,
            ),
            IconButton(
              icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
              onPressed: () => _controller.reload(),
            ),
          ],
        ),
        body: WebViewWidget(controller: _controller),
      ),
    );
  }
}

class _EditDialog extends StatefulWidget {
  @override
  State<_EditDialog> createState() => _EditDialogState();
}

class _EditDialogState extends State<_EditDialog> {
  final _nameCtrl = TextEditingController();
  final _hostCtrl = TextEditingController();
  final _portCtrl = TextEditingController(text: '4096');
  final _userCtrl = TextEditingController(text: 'opencode');
  final _passCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _hostCtrl.dispose();
    _portCtrl.dispose();
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text('添加服务器', style: TextStyle(color: AppColors.textPrimary)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _field('名称', '家里PC', _nameCtrl),
            const SizedBox(height: 12),
            _field('地址', '10.10.10.216', _hostCtrl, keyboardType: TextInputType.url),
            const SizedBox(height: 12),
            _field('端口', '4096', _portCtrl, keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            _field('用户名', 'opencode', _userCtrl),
            const SizedBox(height: 12),
            _field('密码', '', _passCtrl, obscure: true),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            FocusScope.of(context).unfocus();
            Navigator.pop(context);
          },
          child: const Text('取消', style: TextStyle(color: AppColors.textSecondary)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
          onPressed: () {
            final name = _nameCtrl.text.trim();
            final host = _hostCtrl.text.trim();
            final port = _portCtrl.text.trim();
            if (name.isEmpty || host.isEmpty) return;
            final url = 'http://$host${port.isNotEmpty ? ':$port' : ''}';
            Navigator.pop(context, ServerEntry(name: name, url: url, username: _userCtrl.text.trim(), password: _passCtrl.text));
          },
          child: const Text('保存'),
        ),
      ],
    );
  }

  Widget _field(String label, String hint, TextEditingController ctrl, {bool obscure = false, TextInputType? keyboardType}) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        hintStyle: TextStyle(color: AppColors.textTertiary),
        enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: AppColors.border)),
        focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: AppColors.borderFocused)),
      ),
    );
  }
}
