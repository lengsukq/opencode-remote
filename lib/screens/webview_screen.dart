import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../models.dart';
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
      backgroundColor: const Color(0xFF161B22),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('切换服务器', style: TextStyle(color: Colors.grey[300], fontSize: 16)),
            ),
            const Divider(color: Color(0xFF30363D)),
            ...servers.map((s) => ListTile(
                  leading: Icon(Icons.computer, color: s.id == _entry.id ? const Color(0xFF6366F1) : Colors.grey[500]),
                  title: Text(s.name, style: TextStyle(color: s.id == _entry.id ? const Color(0xFF6366F1) : const Color(0xFFE6EDF3))),
                  subtitle: Text(s.url, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  onTap: () => Navigator.pop(ctx, s),
                )),
            const Divider(color: Color(0xFF30363D)),
            ListTile(
              leading: Icon(Icons.add, color: Colors.grey[500]),
              title: const Text('添加新服务器', style: TextStyle(color: Color(0xFFE6EDF3))),
              onTap: () {
                Navigator.pop(ctx);
                _addNew();
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
        backgroundColor: const Color(0xFF0D1117),
        appBar: AppBar(
          backgroundColor: const Color(0xFF161B22),
          title: Text(_entry.name, style: const TextStyle(color: Color(0xFFE6EDF3), fontSize: 16)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF8B949E)),
            onPressed: _backToLauncher,
          ),
          actions: [
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: SizedBox(
                  width: 18, height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF6366F1)),
                ),
              ),
            IconButton(
              icon: const Icon(Icons.swap_horiz, color: Color(0xFF8B949E)),
              tooltip: '切换服务器',
              onPressed: _switchServer,
            ),
            IconButton(
              icon: const Icon(Icons.refresh, color: Color(0xFF8B949E)),
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
  final _urlCtrl = TextEditingController(text: 'http://');
  final _userCtrl = TextEditingController(text: 'opencode');
  final _passCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _urlCtrl.dispose();
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF161B22),
      title: const Text('添加服务器', style: TextStyle(color: Color(0xFFE6EDF3))),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _field('名称', '家里PC', _nameCtrl),
            const SizedBox(height: 12),
            _field('地址', 'http://10.10.10.216:4096', _urlCtrl),
            const SizedBox(height: 12),
            _field('用户名', 'opencode', _userCtrl),
            const SizedBox(height: 12),
            _field('密码', '', _passCtrl, obscure: true),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消', style: TextStyle(color: Colors.grey))),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
          onPressed: () {
            final name = _nameCtrl.text.trim();
            final url = _urlCtrl.text.trim();
            if (name.isEmpty || url.isEmpty) return;
            Navigator.pop(context, ServerEntry(name: name, url: url, username: _userCtrl.text.trim(), password: _passCtrl.text));
          },
          child: const Text('保存'),
        ),
      ],
    );
  }

  Widget _field(String label, String hint, TextEditingController ctrl, {bool obscure = false}) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      style: const TextStyle(color: Color(0xFFE6EDF3)),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: Color(0xFF8B949E)),
        hintStyle: const TextStyle(color: Color(0xFF30363D)),
        enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF30363D))),
        focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF6366F1))),
      ),
    );
  }
}
