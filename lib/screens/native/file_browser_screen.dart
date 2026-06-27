import 'package:flutter/material.dart';
import '../../models.dart';
import '../../theme.dart';
import '../../services/opencode_api.dart';
import '../../widgets/app_full_screen_dialog.dart';
import '../../widgets/app_snackbar.dart';
import '../../strings.dart';
import '../../widgets/app_states.dart';
import '../../widgets/file_search_panel.dart';

class FileBrowserScreen extends StatefulWidget {
  final ServerEntry entry;
  final OpenCodeApi api;
  final Project? activeProject;

  const FileBrowserScreen({super.key, required this.entry, required this.api, this.activeProject});

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
  bool _isSearchMode = false;

  @override
  void initState() {
    super.initState();
    _loadRoot();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void didUpdateWidget(FileBrowserScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeProject?.id != widget.activeProject?.id) {
      _loadRoot();
    }
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
      final initialPath = widget.activeProject?.path ?? '';
      final files = await widget.api.listFiles(initialPath);
      final rootNode = _TreeNode(
        node: FileNode(name: initialPath.isNotEmpty ? initialPath.split('/').last : '/', path: initialPath, type: 'directory'),
        depth: -1,
        expanded: true,
      );
      rootNode.setChildren(files.where((f) => f.type == 'directory').map((f) => _TreeNode(node: f, depth: 0)).toList()
        ..addAll(files.where((f) => f.type != 'directory').map((f) => _TreeNode(node: f, depth: 0))));
      setState(() {
        _roots = [rootNode];
        _currentPath = initialPath;
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
          AppSnackBar.error(context, '${S.loadFailed}: $e');
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
      await AppFullScreenDialog.show(
        context,
        title: node.name,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: SelectableText(
            content.content,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontFamily: 'monospace'),
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        AppSnackBar.error(context, '${S.readFailed}: $e');
      }
    }
  }

  bool _isImageFile(String name) {
    final ext = name.split('.').last.toLowerCase();
    return ['png', 'jpg', 'jpeg', 'gif', 'webp', 'bmp', 'svg'].contains(ext);
  }

  void _showImagePreview(FileNode node) {
    AppFullScreenDialog.show(
      context,
      title: node.name,
      expandContent: false,
      child: Padding(
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
            Text(S.imagePreviewHint, style: TextStyle(color: AppColors.textSecondary, fontSize: 13), textAlign: TextAlign.center),
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
      await AppFullScreenDialog.show(
        context,
        title: name,
        expandContent: false,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(Icons.image, size: 64, color: AppColors.textTertiary),
              const SizedBox(height: 12),
              Text(name, style: TextStyle(color: AppColors.textPrimary, fontSize: 14)),
              const SizedBox(height: 16),
              Text(S.imagePreviewHint, style: TextStyle(color: AppColors.textSecondary, fontSize: 13), textAlign: TextAlign.center),
            ],
          ),
        ),
      );
      return;
    }
    try {
      final content = await widget.api.readFile(path);
      if (!mounted) return;
      await AppFullScreenDialog.show(
        context,
        title: name,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: SelectableText(
            content.content,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontFamily: 'monospace'),
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        AppSnackBar.error(context, '${S.readFailed}: $e');
      }
    }
  }

  // --- Search ---
  void _toggleSearch() {
    setState(() => _isSearchMode = !_isSearchMode);
  }

  @override
  Widget build(BuildContext context) {
    if (_isSearchMode) {
      return FileSearchPanel(
        api: widget.api,
        onOpenFile: _readFileByPath,
        onClose: _toggleSearch,
      );
    }
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _browserAppBar(),
      body: Column(
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
      title: Text(_currentPath.isEmpty
          ? (widget.activeProject != null ? '${widget.activeProject!.name} / ${S.fileBrowser}' : S.fileBrowser)
          : _currentPath.split('/').last),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
          tooltip: S.refresh,
          onPressed: _loadRoot,
        ),
        IconButton(
          icon: const Icon(Icons.search, color: AppColors.textSecondary),
          tooltip: S.search,
          onPressed: _toggleSearch,
        ),
      ],
    );
  }

  Widget _buildFileList() {
    if (_loading) {
      return const Center(child: AppLoadingIndicator());
    }
    if (_error != null) {
      return Center(child: Text(_error!, style: TextStyle(color: AppColors.textSecondary)));
    }
    final visible = _visibleNodes;
    if (visible.isEmpty) {
      return Center(child: Text(S.emptyDir, style: TextStyle(color: AppColors.textTertiary)));
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
