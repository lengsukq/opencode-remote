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

  // Search mode
  bool _searchMode = false;
  final _searchCtrl = TextEditingController();
  List<SearchMatch> _searchResults = [];
  List<String> _fileResults = [];
  List<Symbol> _symbolResults = [];
  bool _searching = false;
  String _searchTabName = 'file'; // file | text | symbol

  @override
  void initState() {
    super.initState();
    _loadFiles('');
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
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

  bool _isImageFile(String name) {
    final ext = name.split('.').last.toLowerCase();
    return ['png', 'jpg', 'jpeg', 'gif', 'webp', 'bmp', 'svg'].contains(ext);
  }

  void _showFileContent(FileNode node) async {
    if (_isImageFile(node.name)) {
      _showImagePreview(node);
      return;
    }
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

  void _showImagePreview(FileNode node) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.surface,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: Text(node.name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
              leading: IconButton(
                icon: const Icon(Icons.close, color: AppColors.textSecondary),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(Icons.image, size: 64, color: AppColors.textTertiary),
                  const SizedBox(height: 12),
                  Text(node.name, style: TextStyle(color: AppColors.textPrimary, fontSize: 14)),
                  if (node.size != null) ...[
                    const SizedBox(height: 4),
                    Text('${node.size} bytes', style: TextStyle(color: AppColors.textTertiary, fontSize: 12)),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    '图片预览需要在服务端配置后可用',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _readFileByPath(String path) async {
    final name = path.split('/').last;
    final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';
    final isImage = ['png', 'jpg', 'jpeg', 'gif', 'webp', 'bmp', 'svg'].contains(ext);
    if (isImage) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => Dialog(
          backgroundColor: AppColors.surface,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: Text(name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
                leading: IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(Icons.image, size: 64, color: AppColors.textTertiary),
                    const SizedBox(height: 12),
                    Text(name, style: TextStyle(color: AppColors.textPrimary, fontSize: 14)),
                    const SizedBox(height: 16),
                    Text('图片预览需要在服务端配置后可用', style: TextStyle(color: AppColors.textSecondary, fontSize: 13), textAlign: TextAlign.center),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
      return;
    }
    try {
      final content = await widget.api.readFile(path);
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => Dialog(
          backgroundColor: AppColors.surface,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              AppBar(
                title: Text(name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
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

  // --- Search ---
  void _toggleSearch() {
    setState(() {
      _searchMode = !_searchMode;
      if (!_searchMode) {
        _searchResults = [];
        _fileResults = [];
        _symbolResults = [];
        _searchCtrl.clear();
      }
    });
  }

  Future<void> _doSearch(String query) async {
    if (query.isEmpty) return;
    setState(() => _searching = true);
    try {
      switch (_searchTabName) {
        case 'file':
          _fileResults = await widget.api.findFiles(query);
          break;
        case 'text':
          _searchResults = await widget.api.searchFiles(query);
          break;
        case 'symbol':
          _symbolResults = await widget.api.findSymbols(query);
          break;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('搜索失败: $e')));
      }
    }
    if (mounted) setState(() => _searching = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _searchMode ? _searchAppBar() : _browserAppBar(),
      body: _searchMode ? _buildSearchResults() : Column(
        children: [
          _buildBreadcrumb(),
          Expanded(child: _buildFileList()),
        ],
      ),
    );
  }

  Widget _buildBreadcrumb() {
    if (_currentPath.isEmpty) return const SizedBox.shrink();
    final segments = _currentPath.split('/');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: AppColors.surface,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _breadcrumbItem('root', () => _loadFiles(''), isFirst: true),
            ...segments.asMap().entries.map((entry) {
              final idx = entry.key;
              final seg = entry.value;
              final fullPath = segments.take(idx + 1).join('/');
              return Row(
                children: [
                  Icon(Icons.chevron_right, size: 14, color: AppColors.textTertiary),
                  _breadcrumbItem(seg, () => _loadFiles(fullPath)),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _breadcrumbItem(String label, VoidCallback onTap, {bool isFirst = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Text(
          label,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontFamily: 'monospace',
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _browserAppBar() {
    return AppBar(
      leading: _history.isNotEmpty
          ? IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.textSecondary),
              onPressed: _goBack,
            )
          : null,
      title: Text(_currentPath.isEmpty ? '文件浏览' : _currentPath.split('/').last),
      actions: [
        IconButton(
          icon: const Icon(Icons.search, color: AppColors.textSecondary),
          tooltip: '搜索',
          onPressed: _toggleSearch,
        ),
      ],
    );
  }

  PreferredSizeWidget _searchAppBar() {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.textSecondary),
        onPressed: _toggleSearch,
      ),
      title: TextField(
        controller: _searchCtrl,
        autofocus: true,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: '搜索文件、内容或符号',
          hintStyle: TextStyle(color: AppColors.textTertiary),
          border: InputBorder.none,
          filled: false,
        ),
        onSubmitted: _doSearch,
      ),
      actions: [
        if (_searching)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: SizedBox(
              width: 18, height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
            ),
          ),
      ],
    );
  }

  Widget _buildSearchResults() {
    return Column(
      children: [
        _searchTabBar(),
        Expanded(
          child: _searching
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : _searchTabName == 'file'
                  ? _fileResults.isNotEmpty
                      ? ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _fileResults.length,
                          itemBuilder: (ctx, i) => ListTile(
                            dense: true,
                            leading: Icon(Icons.insert_drive_file, color: AppColors.textSecondary, size: 18),
                            title: Text(_fileResults[i], style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
                            onTap: () => _readFileByPath(_fileResults[i]),
                          ),
                        )
                      : _emptySearch()
                  : _searchTabName == 'text'
                      ? _searchResults.isNotEmpty
                          ? ListView.builder(
                              padding: const EdgeInsets.all(12),
                              itemCount: _searchResults.length,
                              itemBuilder: (ctx, i) {
                                final r = _searchResults[i];
                                return ListTile(
                                  dense: true,
                                  leading: Icon(Icons.text_snippet, color: AppColors.textSecondary, size: 18),
                                  title: Text(r.path.split('/').last, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('行 ${r.lineNumber}', style: TextStyle(color: AppColors.textTertiary, fontSize: 10)),
                                      Text(r.lines, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontFamily: 'monospace'), maxLines: 2),
                                    ],
                                  ),
                                  onTap: () => _readFileByPath(r.path),
                                );
                              },
                            )
                          : _emptySearch()
                      : _symbolResults.isNotEmpty
                          ? ListView.builder(
                              padding: const EdgeInsets.all(12),
                              itemCount: _symbolResults.length,
                              itemBuilder: (ctx, i) {
                                final s = _symbolResults[i];
                                return ListTile(
                                  dense: true,
                                  leading: Icon(Icons.code, color: AppColors.warning, size: 18),
                                  title: Text(s.name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
                                  subtitle: Text(s.path, style: TextStyle(color: AppColors.textTertiary, fontSize: 11)),
                                  onTap: () {
                                    if (s.path.isNotEmpty) _readFileByPath(s.path);
                                  },
                                );
                              },
                            )
                          : _emptySearch(),
        ),
      ],
    );
  }

  Widget _searchTabBar() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          _tabButton('file', '文件名'),
          _tabButton('text', '内容'),
          _tabButton('symbol', '符号'),
        ],
      ),
    );
  }

  Widget _tabButton(String tab, String label) {
    final selected = _searchTabName == tab;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _searchTabName = tab);
          if (_searchCtrl.text.isNotEmpty) _doSearch(_searchCtrl.text);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: selected ? AppColors.primary : Colors.transparent, width: 2)),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? AppColors.primary : AppColors.textSecondary,
              fontSize: 12,
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _emptySearch() {
    return Center(
      child: Text('输入搜索关键词', style: TextStyle(color: AppColors.textTertiary, fontSize: 14)),
    );
  }

  Widget _buildFileList() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_error != null) {
      return Center(child: Text(_error!, style: TextStyle(color: AppColors.textSecondary)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _files.length,
      itemBuilder: (ctx, i) => _FileTile(node: _files[i], onTap: () => _openEntry(_files[i])),
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
