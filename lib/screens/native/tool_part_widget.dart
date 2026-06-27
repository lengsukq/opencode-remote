import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../models.dart';
import '../../theme.dart';
import '../../utils/glass_effect.dart';
import '../../widgets/diff_view.dart';

/// A preview of code content within a tool part.
class CodePreview extends StatelessWidget {
  final String code;
  final String toolName;

  const CodePreview({super.key, required this.code, required this.toolName});

  @override
  Widget build(BuildContext context) {
    final textColor = isDarkMode(context)
        ? DarkColors.textPrimary
        : AppColors.textPrimary;
    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SelectableText(
            code,
            style: TextStyle(
              color: textColor,
              fontSize: 11,
              fontFamily: 'monospace',
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Displays a tool execution part (write, read, bash, edit, etc.)
class ToolPartWidget extends StatefulWidget {
  final Part part;
  final bool isLatest;
  final String? streamingText;

  const ToolPartWidget({
    super.key,
    required this.part,
    this.isLatest = false,
    this.streamingText,
  });

  @override
  State<ToolPartWidget> createState() => _ToolPartWidgetState();
}

class _ToolPartWidgetState extends State<ToolPartWidget> {
  bool _expanded = true;

  @override
  void initState() {
    super.initState();
    _expanded = widget.isLatest;
  }

  static const _kMaxDiagnosticCount = 3;
  static const _toolIconMap = <String, IconData>{
    'write': Icons.edit_note,
    'edit': Icons.difference,
    'read': Icons.visibility,
    'bash': Icons.terminal,
    'grep': Icons.search,
    'glob': Icons.folder_open,
    'webfetch': Icons.web,
    'task': Icons.subdirectory_arrow_right,
  };

  static const _toolColorMap = <String, Color>{
    'write': AppColors.primary,
    'edit': AppColors.warning,
    'read': AppColors.info,
    'bash': AppColors.success,
    'grep': AppColors.textSecondary,
    'glob': AppColors.textSecondary,
    'webfetch': AppColors.info,
    'task': AppColors.warning,
  };

  @override
  Widget build(BuildContext context) {
    final tool = widget.part.tool;
    if (tool == null) return const SizedBox.shrink();

    final statusInfo = _statusInfo(tool);
    final toolName = tool.tool;
    final title = tool.title ?? toolName;
    final input = tool.input;
    final output = tool.output;
    final error = tool.error;
    final isDark = isDarkMode(context);
    final surfaceColor = isDark ? DarkColors.surfaceAlt : AppColors.surfaceAlt;

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(
            sigmaX: Glass.cardBlur,
            sigmaY: Glass.cardBlur,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Glass.surface(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: tool.isError ? AppColors.danger : Glass.border(context),
              ),
              boxShadow: ResponsiveTheme.getShadow(context, level: 1),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(title, toolName, statusInfo),
                if (_expanded) ...[
                  _buildInput(input, toolName, surfaceColor),
                  _buildOutput(output, error, toolName),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  ({Color color, IconData icon, String label}) _statusInfo(ToolPartData tool) {
    if (tool.isError) {
      return (color: AppColors.danger, icon: Icons.error_outline, label: '失败');
    }
    if (tool.isRunning) {
      return (
        color: AppColors.warning,
        icon: Icons.hourglass_top,
        label: '进行中',
      );
    }
    if (tool.isCompleted) {
      return (
        color: AppColors.success,
        icon: Icons.check_circle_outline,
        label: '完成',
      );
    }
    return (color: AppColors.textSecondary, icon: Icons.schedule, label: '等待');
  }

  Widget _buildHeader(
    String title,
    String toolName,
    ({Color color, IconData icon, String label}) status,
  ) {
    return InkWell(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            _toolIconWidget(toolName),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: status.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(status.icon, size: 12, color: status.color),
                  const SizedBox(width: 3),
                  Text(
                    status.label,
                    style: TextStyle(color: status.color, fontSize: 10),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              _expanded ? Icons.unfold_less : Icons.unfold_more,
              color: AppColors.textTertiary,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _toolIconWidget(String toolName) {
    final icon = _toolIconMap[toolName] ?? Icons.build;
    final color = _toolColorMap[toolName] ?? AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 16, color: color),
    );
  }

  Widget _buildInput(
    Map<String, dynamic>? input,
    String toolName,
    Color surfaceColor,
  ) {
    if (input == null || input.isEmpty) return const SizedBox.shrink();
    if (toolName == 'write') {
      final filePath =
          input['file_path'] as String? ?? input['filePath'] as String? ?? '';
      final content = input['content'] as String? ?? '';
      if (content.isEmpty) return const SizedBox.shrink();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (filePath.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              color: surfaceColor,
              child: Text(
                filePath,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          CodePreview(code: content, toolName: toolName),
          ..._buildDiagnostics(input),
        ],
      );
    }
    if (toolName == 'bash') {
      final command =
          input['command'] as String? ?? input['cmd'] as String? ?? '';
      if (command.isEmpty) return const SizedBox.shrink();
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        color: surfaceColor,
        child: Text(
          '\$ $command',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 12,
            fontFamily: 'monospace',
          ),
        ),
      );
    }
    if (toolName == 'read') {
      final filePath =
          input['file_path'] as String? ?? input['filePath'] as String? ?? '';
      if (filePath.isEmpty) return const SizedBox.shrink();
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        color: surfaceColor,
        child: Text(
          filePath,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
            fontFamily: 'monospace',
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildOutput(String? output, String? error, String toolName) {
    if (output != null && output.isNotEmpty) {
      if (toolName == 'edit') {
        final hunks = _parseDiffHunks(output);
        if (hunks.isNotEmpty) {
          return DiffView(filePath: '', status: 'modified', hunks: hunks);
        }
      }
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: SelectableText(
          output,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 12,
            fontFamily: 'monospace',
            height: 1.4,
          ),
        ),
      );
    }
    if (error != null && error.isNotEmpty) {
      final isDark = isDarkMode(context);
      final dangerColor = isDark ? DarkColors.danger : AppColors.danger;
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        color: dangerColor.withValues(alpha: 0.1),
        child: Text(
          error,
          style: TextStyle(
            color: dangerColor,
            fontSize: 12,
            fontFamily: 'monospace',
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  List<DiffHunkView> _parseDiffHunks(String output) {
    final lines = output.split('\n');
    final hunks = <DiffHunkView>[];
    int i = 0;
    while (i < lines.length) {
      if (lines[i].startsWith('@@')) {
        final match = RegExp(r'@@ -(\d+).*\+(\d+)').firstMatch(lines[i]);
        final oldStart = int.tryParse(match?.group(1) ?? '') ?? 0;
        final newStart = int.tryParse(match?.group(2) ?? '') ?? 0;
        final hunkLines = <String>[];
        i++;
        while (i < lines.length && !lines[i].startsWith('@@')) {
          hunkLines.add(lines[i]);
          i++;
        }
        hunks.add(
          DiffHunkView.fromContent(oldStart, newStart, hunkLines.join('\n')),
        );
      } else {
        i++;
      }
    }
    return hunks;
  }

  List<Widget> _buildDiagnostics(Map<String, dynamic> input) {
    final raw = input['diagnostics'];
    if (raw is! List) return [];
    final items = raw
        .take(_kMaxDiagnosticCount)
        .whereType<Map<String, dynamic>>()
        .toList();
    if (items.isEmpty) return [];
    return items.map((d) {
      final severity = d['severity'] as int? ?? 1;
      final message = d['message'] as String? ?? '';
      final line = d['line'] as int?;
      final label = line != null ? '行 $line' : '';
      final isError = severity >= 1;
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        color: (isError ? AppColors.danger : AppColors.warning).withValues(
          alpha: 0.1,
        ),
        child: Row(
          children: [
            Icon(
              isError ? Icons.error : Icons.warning_amber,
              size: 14,
              color: isError ? AppColors.danger : AppColors.warning,
            ),
            const SizedBox(width: 6),
            if (label.isNotEmpty)
              Text(
                '$label: ',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: isError ? AppColors.danger : AppColors.warning,
                  fontSize: 11,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}
