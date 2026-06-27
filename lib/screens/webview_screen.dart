import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../models.dart';
import '../theme.dart';
import '../services/storage_service.dart';
import '../widgets/server_edit_dialog.dart';
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
      builder: (_) => const AppServerEditDialog(),
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
