import 'package:flutter/material.dart';
import '../../theme.dart';

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
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.isLatest;
  }

  @override
  void didUpdateWidget(ReasoningBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.isLatest && oldWidget.isLatest) {
      setState(() => _expanded = false);
    }
    if (widget.isLatest && !oldWidget.isLatest) {
      setState(() => _expanded = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.psychology, color: AppColors.warning, size: 16),
                  const SizedBox(width: 6),
                  Text('思考过程', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
                  const Spacer(),
                  Icon(
                    _expanded ? Icons.unfold_less : Icons.unfold_more,
                    color: AppColors.textTertiary,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Text(
                widget.content,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontFamily: 'monospace', height: 1.5),
              ),
            ),
        ],
      ),
    );
  }
}
