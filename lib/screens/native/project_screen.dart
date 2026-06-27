import 'dart:async';
import 'package:flutter/material.dart';
import '../../models.dart';
import '../../strings.dart';
import '../../theme.dart';
import '../../services/opencode_api.dart';
import '../../utils/project_helpers.dart';

import '../../utils/responsive_values.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_bottom_sheet.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/app_states.dart';
import '../../widgets/app_input_decoration.dart';
import '../../widgets/workspace_list.dart';

class ProjectScreen extends StatefulWidget {
  final ServerEntry entry;
  final OpenCodeApi api;
  final VoidCallback? onProjectsChanged;

  const ProjectScreen({
    super.key,
    required this.entry,
    required this.api,
    this.onProjectsChanged,
  });

  @override
  State<ProjectScreen> createState() => _ProjectScreenState();
}

class _ProjectScreenState extends State<ProjectScreen> {
  List<Project> _projects = [];
  List<Project> _filteredProjects = [];
  Project? _current;
  VcsInfo? _vcs;
  bool _loading = true;
  String? _error;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _applyFilter();
  }

  void _applyFilter() {
    final query = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredProjects = List.from(_projects);
      } else {
        _filteredProjects = _projects.where((p) =>
          p.name.toLowerCase().contains(query) ||
          p.path.toLowerCase().contains(query)
        ).toList();
      }
    });
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final projects = await widget.api.getProjects();
      if (!mounted) return;
      final current = await widget.api.getCurrentProject();
      if (!mounted) return;
      final vcs = await widget.api.getVcs();
      if (!mounted) return;
      setState(() {
        _projects = projects;
        _current = current;
        _vcs = vcs;
        _loading = false;
        _error = null;
      });
      _applyFilter();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _removeProject(Project project) async {
    try {
      await widget.api.removeProject(project.id);
    } catch (_) {
      // removeProject not available on server; do local removal
    }
    setState(() {
      _projects.removeWhere((p) => p.id == project.id);
      _filteredProjects.removeWhere((p) => p.id == project.id);
      if (_current?.id == project.id) {
        _current = null;
        widget.api.directory = null;
      }
    });
    widget.onProjectsChanged?.call();
  }

  Future<bool> _confirmRemoveProject(Project project) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(S.closeProject, style: const TextStyle(color: AppColors.textPrimary)),
        content: Text(S.confirmCloseProjectName(project.name), style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(S.cancel, style: TextStyle(color: AppColors.textSecondary)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(S.close),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(S.project),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? const AppLoadingIndicator()
          : _error != null
              ? AppErrorState(message: _error!, onRetry: _load)
              : Column(
                  children: [
                    _buildSearchBar(),
                    Expanded(child: _buildProjectList()),
                  ],
                ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      color: AppColors.background,
      child: TextField(
        controller: _searchCtrl,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
        decoration: AppInputDecoration.search(
          hintText: S.searchProjects,
          prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary, size: 20),
          suffixIcon: _searchCtrl.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: AppColors.textSecondary, size: 18),
                  onPressed: () {
                    _searchCtrl.clear();
                  },
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildProjectList() {
    return ListView(
      padding: R.screenPadding(context),
      children: [
        if (_current != null) ...[
          Text(S.currentProject, style: TextStyle(color: AppColors.textSecondary, fontSize: R.smallFontSize(context))),
          SizedBox(height: R.smallSpacing(context)),
          _ProjectCard(
            project: _current!,
            isCurrent: true,
            vcs: _vcs,
            onLongPress: () => _handleLongPress(_current!),
          ),
          SizedBox(height: R.mediumSpacing(context)),
        ],
        Text(S.allProjects, style: TextStyle(color: AppColors.textSecondary, fontSize: R.smallFontSize(context))),
        SizedBox(height: R.smallSpacing(context)),
        ..._buildProjectCards(),
        if (_filteredProjects.isEmpty && _searchCtrl.text.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(S.noMatchingProjects, style: TextStyle(color: AppColors.textTertiary)),
          ),
        if (_projects.isEmpty)
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(S.noProjects, style: TextStyle(color: AppColors.textTertiary)),
          ),
        if (_vcs != null) ...[
          const SizedBox(height: 24),
          WorkspaceList(api: widget.api, currentBranch: _vcs!.branch),
        ],
      ],
    );
  }

  List<Widget> _buildProjectCards() {
    final items = _filteredProjects
        .where((p) => _current?.id != p.id)
        .toList();
    if (items.length < 2) {
      return items.map((p) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: _ProjectCard(
          key: ValueKey(p.id),
          project: p,
          isCurrent: false,
          onTap: () => _showProjectDetail(p),
          onLongPress: () => _handleLongPress(p),
        ),
      )).toList();
    }
    // Use ReorderableListView for 2+ non-current projects
    return [
      ReorderableListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        buildDefaultDragHandles: false,
        itemCount: items.length,
        itemBuilder: (ctx, i) {
          final p = items[i];
          return _ProjectCard(
            key: ValueKey(p.id),
            project: p,
            isCurrent: false,
            onTap: () => _showProjectDetail(p),
            onLongPress: () => _handleLongPress(p),
            dragIndex: i,
          );
        },
        onReorder: (oldIndex, newIndex) {
          setState(() {
            if (oldIndex < newIndex) newIndex--;
            final item = items.removeAt(oldIndex);
            items.insert(newIndex, item);
            // Update the full _projects list preserving order
            final nonCurrent = _projects
                .where((p) => _current?.id != p.id)
                .toList();
            final updatedProjects = _projects
                .where((p) => _current?.id == p.id)
                .toList();
            updatedProjects.addAll(nonCurrent);
            _projects = updatedProjects;
            _applyFilter();
          });
          // 持久化排序顺序
          final ids = _projects.where((p) => _current?.id != p.id).map((p) => p.id).toList();
          unawaited(ProjectHelpers.saveOrder(widget.entry.id, ids));
        },
      ),
    ];
  }

  void _handleLongPress(Project project) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(S.projectDetail(project.name), style: const TextStyle(color: AppColors.textPrimary, fontSize: 16)),
        content: Text(S.closeProjectHint, style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(S.cancel, style: TextStyle(color: AppColors.textSecondary)),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            icon: const Icon(Icons.close, size: 16),
            label: Text(S.closeProject),
            onPressed: () {
              Navigator.pop(ctx);
              _confirmRemoveProject(project).then((confirmed) {
                if (confirmed) _removeProject(project);
              });
            },
          ),
        ],
      ),
    );
  }

  void _showProjectDetail(Project project) {
    AppBottomSheet.show(
      context: context,
      child: Builder(
        builder: (ctx) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(project.name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                _detailRow(Icons.folder, S.path, project.path),
                if (project.id.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _detailRow(Icons.tag, S.id, project.id),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                    icon: const Icon(Icons.check_circle, size: 18),
                    label: Text(project.id == _current?.id ? S.currentProject : S.switchToProject),
                    onPressed: project.id == _current?.id ? null : () {
                      widget.api.directory = project.path;
                      Navigator.pop(ctx);
                      _load();
                      AppSnackBar.success(context, '${S.switchedTo} ${project.name}');
                    },
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 16),
        const SizedBox(width: 8),
        Text('$label: ', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        Expanded(child: Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13))),
      ],
    );
  }
}

class _ProjectCard extends StatelessWidget {
  final Project project;
  final bool isCurrent;
  final VcsInfo? vcs;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final int? dragIndex;

  const _ProjectCard({
    super.key,
    required this.project,
    required this.isCurrent,
    this.vcs,
    this.onTap,
    this.onLongPress,
    this.dragIndex,
  });

  @override
  Widget build(BuildContext context) {
    final iconWidget = Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isCurrent ? AppColors.primaryLight : AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppColors.kCardBorderRadius),
      ),
      child: Icon(
        isCurrent ? Icons.folder : Icons.folder_outlined,
        color: isCurrent ? AppColors.primary : AppColors.textSecondary,
        size: 20,
      ),
    );

    final card = AppCard(
      borderColor: isCurrent ? AppColors.primary : null,
      boxShadow: [
        BoxShadow(color: AppColors.shadow, blurRadius: 4, offset: const Offset(0, 1)),
      ],
      child: Row(
        children: [
          if (dragIndex != null)
            ReorderableDragStartListener(
              index: dragIndex!,
              child: Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Icon(Icons.drag_handle, color: AppColors.textTertiary, size: 20),
              ),
            ),
          if (dragIndex != null)
            ReorderableDragStartListener(index: dragIndex!, child: iconWidget)
          else
            iconWidget,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        project.name,
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isCurrent) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(AppColors.kCardBorderRadius),
                        ),
                        child: const Text(S.current, style: TextStyle(color: AppColors.primary, fontSize: 9)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  project.path,
                  style: TextStyle(color: AppColors.textTertiary, fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (vcs != null && isCurrent)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppColors.kCardBorderRadius),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.call_split, color: AppColors.success, size: 10),
                  const SizedBox(width: 3),
                  Text(vcs!.branch ?? 'main', style: const TextStyle(color: AppColors.success, fontSize: 10)),
                ],
              ),
            ),
          if (onTap != null)
            Icon(Icons.chevron_right, color: AppColors.textTertiary, size: 18),
        ],
      ),
    );

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: card,
    );
  }
}
