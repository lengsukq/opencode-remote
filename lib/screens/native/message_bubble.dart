import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../models.dart';
import '../../theme.dart';
import '../../utils/time_format.dart';
import '../../widgets/code_block_builder.dart';
import '../../widgets/file_parts_row.dart';
import '../../widgets/reasoning_block.dart';
import 'tool_part_widget.dart';

/// A bubble widget displaying a single chat message (user or AI).
class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isLatest;
  final String? streamingText;
  final VoidCallback? onLongPress;
  final void Function(String code, String? language, BuildContext ctx)? onApplyCode;

  const MessageBubble({
    super.key,
    required this.message,
    this.isLatest = false,
    this.streamingText,
    this.onLongPress,
    this.onApplyCode,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    final timeStr = formatTime(message.createdAt);
    final displayContent = streamingText != null ? '${message.content}\n$streamingText' : message.content;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isUser && message.hasReasoning)
            ReasoningBlock(content: message.reasoning!, isLatest: isLatest),
          if (!isUser && message.cost > 0)
            Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '\$${message.cost.toStringAsFixed(4)}',
                style: TextStyle(color: AppColors.success, fontSize: 10, fontFamily: 'monospace'),
              ),
            ),
          _buildBubble(context, isUser, displayContent),
          if (message.parts.any((p) => p.type == 'file'))
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: FilePartsRow(
                parts: message.parts.where((p) => p.type == 'file').toList(),
              ),
            ),
          ...message.parts.where((p) => p.type == 'tool').map((p) => ToolPartWidget(
            part: p,
            isLatest: isLatest,
            streamingText: streamingText,
          )),
          const SizedBox(height: 2),
          Text(timeStr, style: TextStyle(color: AppColors.textTertiary, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildBubble(BuildContext context, bool isUser, String displayContent) {
    return GestureDetector(
      onLongPress: onLongPress,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
        padding: EdgeInsets.only(
          left: 14,
          right: 14,
          top: isUser ? 10 : 8,
          bottom: isUser ? 10 : 8,
        ),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomRight: isUser ? const Radius.circular(4) : null,
            bottomLeft: !isUser ? const Radius.circular(4) : null,
          ),
          boxShadow: isUser ? null : [BoxShadow(color: AppColors.shadow, blurRadius: 4, offset: const Offset(0, 1))],
        ),
        child: isUser
            ? Text(
                message.content,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              )
            : MarkdownBody(
                data: displayContent,
                selectable: true,
                builders: {
                  'code_block': CodeBlockBuilder(onApply: onApplyCode),
                },
                styleSheet: MarkdownStyleSheet(
                  p: const TextStyle(color: AppColors.textPrimary, fontSize: 14, height: 1.5),
                  h1: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold, height: 1.4),
                  h2: TextStyle(color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.bold, height: 1.4),
                  h3: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600, height: 1.4),
                  code: TextStyle(color: AppColors.textPrimary, fontSize: 12, fontFamily: 'monospace', backgroundColor: AppColors.surfaceAlt),
                  codeblockDecoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  blockquoteDecoration: BoxDecoration(
                    border: Border(left: BorderSide(color: AppColors.primary, width: 3)),
                    color: AppColors.surfaceAlt,
                  ),
                  listBullet: TextStyle(color: AppColors.textSecondary),
                  horizontalRuleDecoration: BoxDecoration(
                    border: Border(top: BorderSide(color: AppColors.border)),
                  ),
                  a: const TextStyle(color: AppColors.primary, decoration: TextDecoration.underline),
                  strong: const TextStyle(fontWeight: FontWeight.bold),
                  em: const TextStyle(fontStyle: FontStyle.italic),
                  del: const TextStyle(decoration: TextDecoration.lineThrough),
                  blockSpacing: 8,
                  codeblockPadding: EdgeInsets.all(10),
                ),
              ),
      ),
    );
  }
}
