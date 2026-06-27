import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/opencode_api.dart';

/// A collapsible widget that displays VCS branch information.
///
/// Shows the current branch name and, when expanded, lists all available
/// branches fetched from the server. Degrades gracefully if the server
/// does not support branch listing.
class WorkspaceList extends StatefulWidget {
  final OpenCodeApi api;
  final String? currentBranch;

  const WorkspaceList({super.key, required this.api, this.currentBranch});

  @override
  State<WorkspaceList> createState() => _WorkspaceListState();
}

class _WorkspaceListState extends State<WorkspaceList> {
  bool _expanded = false;
  List<String> _branches = [];
  bool _loading = false;
  bool _listSupported = true;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _toggleExpanded() async {
    if (!_expanded && _branches.isEmpty && _listSupported) {
      await _loadBranches();
    }
    setState(() => _expanded = !_expanded);
  }

  Future<void> _loadBranches() async {
    setState(() => _loading = true);
    try {
      final vcs = await widget.api.getVcs();
      if (vcs != null) {
        final branch = vcs.branch;
        if (branch != null && branch.isNotEmpty) {
          setState(() {
            _branches = [branch];
            _loading = false;
          });
        } else {
          setState(() {
            _branches = [];
            _loading = false;
          });
        }
      } else {
        setState(() {
          _listSupported = false;
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _listSupported = false;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentBranch = widget.currentBranch ?? '';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppColors.kCardBorderRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(AppColors.kCardBorderRadius),
            onTap: _toggleExpanded,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.call_split, color: AppColors.primary, size: 18),
                  const SizedBox(width: 10),
                  Text(
                    '分支',
                    style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(AppColors.kChipBorderRadius),
                    ),
                    child: Text(
                      currentBranch.isNotEmpty ? currentBranch : 'unknown',
                      style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w500),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _expanded ? Icons.expand_more : Icons.chevron_right,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1, color: AppColors.border),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: SizedBox(
                  width: 18, height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                )),
              )
            else if (!_listSupported)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.textTertiary, size: 14),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '服务端不支持分支列表',
                        style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              )
            else if (_branches.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  '无分支信息',
                  style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
                ),
              )
            else
              ..._branches.map((b) => _BranchItem(
                name: b,
                isCurrent: b == currentBranch,
                onTap: () {
                  // Reserved for branch switch callback
                },
              )),
          ],
        ],
      ),
    );
  }
}

class _BranchItem extends StatelessWidget {
  final String name;
  final bool isCurrent;
  final VoidCallback? onTap;

  const _BranchItem({
    required this.name,
    required this.isCurrent,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Icon(
              isCurrent ? Icons.check_circle : Icons.call_split,
              color: isCurrent ? AppColors.primary : AppColors.textSecondary,
              size: 16,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  color: isCurrent ? AppColors.primary : AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            if (isCurrent)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(AppColors.kChipBorderRadius),
                ),
                child: const Text('当前', style: TextStyle(color: AppColors.primary, fontSize: 9)),
              ),
          ],
        ),
      ),
    );
  }
}
