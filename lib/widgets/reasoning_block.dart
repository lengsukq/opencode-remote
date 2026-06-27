import 'package:flutter/material.dart';
import '../../theme.dart';
import '../strings.dart';

/// A collapsible reasoning block displaying AI thought process.
class ReasoningBlock extends StatefulWidget {
  final String content;
  final bool isLatest;

  const ReasoningBlock({
    super.key,
    required this.content,
    required this.isLatest,
  });

  @override
  State<ReasoningBlock> createState() => _ReasoningBlockState();
}

class _ReasoningBlockState extends State<ReasoningBlock> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.isLatest;
  }

  @override
  void didUpdateWidget(ReasoningBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.isLatest && oldWidget.isLatest) {
      setState(() => _isExpanded = false);
    }
    if (widget.isLatest && !oldWidget.isLatest) {
      setState(() => _isExpanded = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppColors.kSmallBorderRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(AppColors.kSmallBorderRadius),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.psychology,
                    color: AppColors.warning,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    S.thinkingProcess,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _isExpanded ? Icons.unfold_less : Icons.unfold_more,
                    color: AppColors.textTertiary,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Text(
                widget.content,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontFamily: 'monospace',
                  height: 1.5,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
