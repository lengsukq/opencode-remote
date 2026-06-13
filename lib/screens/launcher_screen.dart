import 'package:flutter/material.dart';
import '../models.dart';
import '../services/storage_service.dart';
import 'webview_screen.dart';

class LauncherScreen extends StatefulWidget {
  const LauncherScreen({super.key});

  @override
  State<LauncherScreen> createState() => _LauncherScreenState();
}

class _LauncherScreenState extends State<LauncherScreen> {
  List<ServerEntry> _servers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final servers = await StorageService.loadServers();
    setState(() {
      _servers = servers;
      _loading = false;
    });
  }

  Future<void> _openServer(ServerEntry entry) async {
    entry.lastUsed = DateTime.now().millisecondsSinceEpoch;
    await StorageService.addOrUpdate(entry);
    await StorageService.setLastSelectedId(entry.id);
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => WebViewScreen(entry: entry)),
    );
  }

  Future<void> _addServer({ServerEntry? existing}) async {
    final result = await _showEditDialog(context, entry: existing);
    if (result == null) return;
    await StorageService.addOrUpdate(result);
    await _reload();
  }

  Future<void> _deleteServer(ServerEntry entry) async {
    await StorageService.delete(entry.id);
    await _reload();
  }

  String _formatTime(int ms) {
    final dt = DateTime.fromMillisecondsSinceEpoch(ms);
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inHours < 1) return '${diff.inMinutes} 分钟前';
    if (diff.inDays < 1) return '${diff.inHours} 小时前';
    return '${diff.inDays} 天前';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.code, color: Color(0xFF6366F1), size: 28),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('OpenCode',
                          style: TextStyle(
                              color: Colors.grey[100],
                              fontSize: 22,
                              fontWeight: FontWeight.w600)),
                      Text('远程控制',
                          style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text('服务器', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
                  : _servers.isEmpty
                      ? _emptyState()
                      : _serverList(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF6366F1),
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
          Icon(Icons.dns_outlined, size: 48, color: Colors.grey[700]),
          const SizedBox(height: 16),
          Text('还没有服务器', style: TextStyle(color: Colors.grey[500], fontSize: 15)),
          const SizedBox(height: 8),
          Text('点击 + 添加', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
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
              color: Colors.red.shade900,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          confirmDismiss: (_) async {
            await _deleteServer(entry);
            return false;
          },
          child: _ServerCard(
            entry: entry,
            timeStr: _formatTime(entry.lastUsed),
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

    return Card(
      color: const Color(0xFF161B22),
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFF30363D)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
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
                  color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.computer, color: Color(0xFF6366F1), size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.name,
                        style: const TextStyle(
                            color: Color(0xFFE6EDF3),
                            fontSize: 15,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 3),
                    Text(host,
                        style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                    const SizedBox(height: 2),
                    Text('最后使用: $timeStr',
                        style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[600], size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

Future<ServerEntry?> _showEditDialog(BuildContext context, {ServerEntry? entry}) async {
  final nameCtrl = TextEditingController(text: entry?.name ?? '');
  final urlCtrl = TextEditingController(text: entry?.url ?? 'http://');
  final userCtrl = TextEditingController(text: entry?.username ?? 'opencode');
  final passCtrl = TextEditingController(text: entry?.password ?? '');

  final result = await showDialog<ServerEntry>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF161B22),
      title: Text(entry == null ? '添加服务器' : '编辑服务器',
          style: const TextStyle(color: Color(0xFFE6EDF3))),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              style: const TextStyle(color: Color(0xFFE6EDF3)),
              decoration: _inputDec('名称', '家里PC'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: urlCtrl,
              style: const TextStyle(color: Color(0xFFE6EDF3)),
              decoration: _inputDec('地址', 'http://10.10.10.216:4096'),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: userCtrl,
              style: const TextStyle(color: Color(0xFFE6EDF3)),
              decoration: _inputDec('用户名', 'opencode'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passCtrl,
              style: const TextStyle(color: Color(0xFFE6EDF3)),
              decoration: _inputDec('密码', ''),
              obscureText: true,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('取消', style: TextStyle(color: Colors.grey)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
          onPressed: () {
            final name = nameCtrl.text.trim();
            final url = urlCtrl.text.trim();
            if (name.isEmpty || url.isEmpty) return;
            Navigator.pop(
              ctx,
              (entry ?? ServerEntry(name: name, url: url)).copyWith(
                name: name,
                url: url,
                username: userCtrl.text.trim(),
                password: passCtrl.text,
              ),
            );
          },
          child: const Text('保存'),
        ),
      ],
    ),
  );
  nameCtrl.dispose();
  urlCtrl.dispose();
  userCtrl.dispose();
  passCtrl.dispose();
  return result;
}

InputDecoration _inputDec(String label, String hint) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    labelStyle: const TextStyle(color: Color(0xFF8B949E)),
    hintStyle: const TextStyle(color: Color(0xFF30363D)),
    enabledBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Color(0xFF30363D))),
    focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Color(0xFF6366F1))),
  );
}
