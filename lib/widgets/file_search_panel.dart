import 'package:flutter/material.dart';
import '../models.dart';
import '../theme.dart';
import '../services/opencode_api.dart';
import 'app_snackbar.dart';
import '../strings.dart';
import 'app_states.dart';

/// A self-contained full-screen search panel for file, text content, and
/// symbol search.
///
/// Renders its own [Scaffold] with a search bar and tabbed results. The parent
/// toggles between this panel and the normal browser view via [onClose].
class FileSearchPanel extends StatefulWidget {
  final OpenCodeApi api;
  final void Function(String path) onOpenFile;
  final VoidCallback onClose;

  const FileSearchPanel({
    super.key,
    required this.api,
    required this.onOpenFile,
    required this.onClose,
  });

  @override
  State<FileSearchPanel> createState() => _FileSearchPanelState();
}

class _FileSearchPanelState extends State<FileSearchPanel> {
  final _searchCtrl = TextEditingController();
  List<SearchMatch> _searchResults = [];
  List<String> _fileResults = [];
  List<Symbol> _symbolResults = [];
  bool _isSearching = false;
  String _searchTabName = 'file';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _doSearch(String query) async {
    if (query.isEmpty) return;
    setState(() => _isSearching = true);
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
        AppSnackBar.error(context, '${S.searchFailed}: $e');
      }
    }
    if (mounted) setState(() => _isSearching = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _appBar(),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _appBar() {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.textSecondary),
        onPressed: widget.onClose,
      ),
      title: TextField(
        controller: _searchCtrl,
        autofocus: true,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
        decoration: const InputDecoration(
          hintText: S.searchFiles,
          hintStyle: TextStyle(color: AppColors.textTertiary),
          border: InputBorder.none,
          filled: false,
        ),
        onSubmitted: _doSearch,
      ),
      actions: [
        if (_isSearching)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        _searchTabBar(),
        Expanded(
          child: _isSearching
              ? const Center(child: AppLoadingIndicator())
              : _searchTabName == 'file'
              ? _fileResults.isNotEmpty
                    ? _buildFileResultList()
                    : _emptySearch()
              : _searchTabName == 'text'
              ? _searchResults.isNotEmpty
                    ? _buildTextResultList()
                    : _emptySearch()
              : _symbolResults.isNotEmpty
              ? _buildSymbolResultList()
              : _emptySearch(),
        ),
      ],
    );
  }

  Widget _buildFileResultList() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _fileResults.length,
      itemBuilder: (ctx, i) => ListTile(
        dense: true,
        leading: const Icon(
          Icons.insert_drive_file,
          color: AppColors.textSecondary,
          size: 18,
        ),
        title: Text(
          _fileResults[i],
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
        ),
        onTap: () => widget.onOpenFile(_fileResults[i]),
      ),
    );
  }

  Widget _buildTextResultList() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _searchResults.length,
      itemBuilder: (ctx, i) {
        final r = _searchResults[i];
        return ListTile(
          dense: true,
          leading: const Icon(
            Icons.text_snippet,
            color: AppColors.textSecondary,
            size: 18,
          ),
          title: Text(
            r.path.split('/').last,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '行 ${r.lineNumber}',
                style: const TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 10,
                ),
              ),
              Text(
                r.lines,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontFamily: 'monospace',
                ),
                maxLines: 2,
              ),
            ],
          ),
          onTap: () => widget.onOpenFile(r.path),
        );
      },
    );
  }

  Widget _buildSymbolResultList() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _symbolResults.length,
      itemBuilder: (ctx, i) {
        final s = _symbolResults[i];
        return ListTile(
          dense: true,
          leading: const Icon(Icons.code, color: AppColors.warning, size: 18),
          title: Text(
            s.name,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
          ),
          subtitle: Text(
            s.path,
            style: const TextStyle(color: AppColors.textTertiary, fontSize: 11),
          ),
          onTap: () {
            if (s.path.isNotEmpty) widget.onOpenFile(s.path);
          },
        );
      },
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
          _tabButton('file', S.fileName),
          _tabButton('text', S.content),
          _tabButton('symbol', S.symbol),
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
            border: Border(
              bottom: BorderSide(
                color: selected ? AppColors.primary : Colors.transparent,
                width: 2,
              ),
            ),
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
    return const Center(
      child: Text(
        S.searchKeyword,
        style: TextStyle(color: AppColors.textTertiary, fontSize: 14),
      ),
    );
  }
}
