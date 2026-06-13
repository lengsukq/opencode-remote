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

class _TreeNode {
  final FileNode node;
  final int depth;
  bool expanded;
  List<_TreeNode>? _children;
  bool loading = false;

  _TreeNode({required this.node, this.depth = 0, this.expanded = false});

  bool get isDirectory => node.type == 'directory';
  bool get hasChildren => _children != null && _children!.isNotEmpty;
  List<_TreeNode> get children => _children ?? [];
  bool get isLoaded => _children != null;

  void setChildren(List<_TreeNode> c) {
    _children = c;
  }

  void clearChildren() {
    _children = null;
  }
}

class _FileBrowserScreenState extends State<FileBrowserScreen> {
  List<_TreeNode> _roots = [];
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
    _loadRoot();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<_TreeNode> _flatten(List<_TreeNode> nodes) {
    final result = <_TreeNode>[];
    for (final n in nodes) {
      result.add(n);
      if (n.isDirectory && n.expanded && n.isLoaded) {
        result.addAll(_flatten(n.children));
      }
    }
    return result;
  }

  List<_TreeNode> get _visibleNodes => _flatten(_roots);

  Future<void> _loadRoot() async {
    setState(() => _loading = true);
    try {
      final files = await widget.api.listFiles('');
      final rootNode = _TreeNode(
        node: FileNode(name: '/', path: '', type: 'directory'),
        depth: -1,
        expanded: true,
      );
      rootNode.setChildren(files.where((f) => f.type == 'directory').map((f) => _TreeNode(node: f, depth: 0)).toList()
        ..addAll(files.where((f) => f.type != 'directory').map((f) => _TreeNode(node: f, depth: 0))));
      _roots = [rootNode];
      _currentPath = '';
      _loading = false;
      _error = null;
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _toggleNode(_TreeNode node) async {
    if (!node.isDirectory) return;
    if (node.expanded) {
      setState(() => node.expanded = false);
      return;
    }
    if (!node.isLoaded) {
      setState(() => node.loading = true);
      try {
        final files = await widget.api.listFiles(node.node.path);
        final children = files.map((f) => _TreeNode(
          node: f,
          depth: node.depth + 1,
        )).toList();
        setState(() {
          node.setChildren(children);
          node.expanded = true;
          node.loading = false;
        });
      } catch (e) {
        setState(() => node.loading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('加载失败: $e')));
        }
      }
    } else {
      setState(() => node.expanded = true);
    }
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

  bool _isImageFile(String name) {
    final ext = name.split('.').last.toLowerCase();
    return ['png', 'jpg', 'jpeg', 'gif', 'webp', 'bmp', 'svg'].contains(ext);
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
                  Text('图片预览需要在服务端配置后可用', style: TextStyle(color: AppColors.textSecondary, fontSize: 13), textAlign: TextAlign.center),
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
            _breadcrumbItem('root', () => _loadRoot(), isFirst: true),
            ...segments.map((seg) {
              return Row(
                children: [
                  Icon(Icons.chevron_right, size: 14, color: AppColors.textTertiary),
                  _breadcrumbItem(seg, () {}),
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
              onPressed: () {},
            )
          : null,
      title: Text(_currentPath.isEmpty ? '文件浏览' : _currentPath.split('/').last),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
          tooltip: '刷新',
          onPressed: _loadRoot,
        ),
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
    final visible = _visibleNodes;
    if (visible.isEmpty) {
      return Center(child: Text('空目录', style: TextStyle(color: AppColors.textTertiary)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(4),
      itemCount: visible.length,
      itemBuilder: (ctx, i) {
        final tn = visible[i];
        if (tn.depth < 0) return const SizedBox.shrink();
        return _TreeFileTile(
          node: tn,
          onTap: () {
            if (tn.isDirectory) {
              _toggleNode(tn);
            } else {
              _showFileContent(tn.node);
            }
          },
        );
      },
    );
  }
}

class _TreeFileTile extends StatelessWidget {
  final _TreeNode node;
  final VoidCallback onTap;

  const _TreeFileTile({required this.node, required this.onTap});

  IconData get _icon {
    if (node.isDirectory) return node.expanded ? Icons.folder_open : Icons.folder;
    final ext = node.node.name.split('.').lastOrNull ?? '';
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
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.only(
          left: 12.0 + node.depth * 20.0,
          right: 12,
          top: 6,
          bottom: 6,
        ),
        child: Row(
          children: [
            if (node.loading)
              const SizedBox(
                width: 16, height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(_icon, color: node.isDirectory ? AppColors.warning : AppColors.textSecondary, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                node.node.name,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
