import 'package:flutter/material.dart';
import '../../models.dart';
import '../../theme.dart';
import '../../services/opencode_api.dart';

class FileBrowserScreen extends StatefulWidget {
  final ServerEntry entry;
  final OpenCodeApi api;

  const FileBrowserScreen({super.key, required this.entry, required this.api});

  @override
  State<FileBrowserScreen> createState() => _FileBrowserScreenState();
}

class _FileBrowserScreenState extends State<FileBrowserScreen> {
  List<FileNode> _files = [];
  bool _loading = true;
  String? _error;
  String _currentPath = '';
  final List<String> _history = [];

  @override
  void initState() {
    super.initState();
    _loadFiles('');
  }

  Future<void> _loadFiles(String path) async {
    setState(() => _loading = true);
    try {
      final files = await widget.api.listFiles(path);
      setState(() {
        _files = files;
        _currentPath = path;
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

  void _openEntry(FileNode node) {
    if (node.type == 'directory') {
      _history.add(_currentPath);
      _loadFiles(node.path);
    } else {
      _showFileContent(node);
    }
  }

  void _goBack() {
    if (_history.isNotEmpty) {
      final prev = _history.removeLast();
      _loadFiles(prev);
    }
  }

  void _showFileContent(FileNode node) async {
    try {
      final content = await widget.api.readFile(node.path);
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => Dialog(
          backgroundColor: AppColors.surface,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              AppBar(
                title: Text(node.name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
                leading: IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: SelectableText(
                    content.content,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontFamily: 'monospace'),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('读取失败: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: _history.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.textSecondary),
                onPressed: _goBack,
              )
            : null,
        title: Text(
          _currentPath.isEmpty ? '文件浏览' : _currentPath.split('/').last,
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? Center(child: Text(_error!, style: TextStyle(color: AppColors.textSecondary)))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _files.length,
                  itemBuilder: (ctx, i) => _FileTile(node: _files[i], onTap: () => _openEntry(_files[i])),
                ),
    );
  }
}

class _FileTile extends StatelessWidget {
  final FileNode node;
  final VoidCallback onTap;

  const _FileTile({required this.node, required this.onTap});

  IconData get _icon {
    if (node.type == 'directory') return Icons.folder;
    final ext = node.name.split('.').lastOrNull ?? '';
    switch (ext) {
      case 'dart': return Icons.code;
      case 'md': return Icons.description;
      case 'yaml': case 'yml': return Icons.settings;
      case 'json': return Icons.data_object;
      case 'png': case 'jpg': case 'svg': return Icons.image;
      default: return Icons.insert_drive_file;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(_icon, color: node.type == 'directory' ? AppColors.warning : AppColors.textSecondary, size: 18),
              const SizedBox(width: 12),
              Expanded(child: Text(node.name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13))),
              if (node.type == 'directory')
                Icon(Icons.chevron_right, color: AppColors.textTertiary, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
