import 'package:flutter/material.dart';
import '../../models.dart';
import '../../theme.dart';
import '../../services/opencode_api.dart';

class ProjectScreen extends StatefulWidget {
  final ServerEntry entry;
  final OpenCodeApi api;

  const ProjectScreen({super.key, required this.entry, required this.api});

  @override
  State<ProjectScreen> createState() => _ProjectScreenState();
}

class _ProjectScreenState extends State<ProjectScreen> {
  List<Project> _projects = [];
  Project? _current;
  VcsInfo? _vcs;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final projects = await widget.api.getProjects();
      final current = await widget.api.getCurrentProject();
      final vcs = await widget.api.getVcs();
      setState(() {
        _projects = projects;
        _current = current;
        _vcs = vcs;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('项目'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? Center(child: Text(_error!, style: TextStyle(color: AppColors.textSecondary)))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (_current != null) ...[
                      Text('当前项目', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      const SizedBox(height: 8),
                      _ProjectCard(
                        project: _current!,
                        isCurrent: true,
                        vcs: _vcs,
                      ),
                      const SizedBox(height: 24),
                    ],
                    Text('所有项目', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    const SizedBox(height: 8),
                    ..._projects.map((p) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: _ProjectCard(
                        project: p,
                        isCurrent: _current?.id == p.id,
                        onTap: () => _showProjectDetail(p),
                      ),
                    )),
                    if (_projects.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text('暂无项目', style: TextStyle(color: AppColors.textTertiary)),
                      ),
                  ],
                ),
    );
  }

  void _showProjectDetail(Project project) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(project.name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              _detailRow(Icons.folder, '路径', project.path),
              if (project.id.isNotEmpty) ...[
                const SizedBox(height: 8),
                _detailRow(Icons.tag, 'ID', project.id),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                  icon: const Icon(Icons.check_circle, size: 18),
                  label: Text(project.id == _current?.id ? '当前项目' : '切换到该项目'),
                  onPressed: project.id == _current?.id ? null : () {
                    widget.api.directory = project.path;
                    Navigator.pop(ctx);
                    _load();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('已切换到: ${project.name}')),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
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

  const _ProjectCard({
    required this.project,
    required this.isCurrent,
    this.vcs,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCurrent ? AppColors.primary : AppColors.border,
            width: isCurrent ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(color: AppColors.shadow, blurRadius: 4, offset: const Offset(0, 1)),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isCurrent ? AppColors.primaryLight : AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isCurrent ? Icons.folder : Icons.folder_outlined,
                color: isCurrent ? AppColors.primary : AppColors.textSecondary,
                size: 20,
              ),
            ),
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
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: const Text('当前', style: TextStyle(color: AppColors.primary, fontSize: 9)),
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
                  borderRadius: BorderRadius.circular(4),
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
      ),
    );
  }
}
