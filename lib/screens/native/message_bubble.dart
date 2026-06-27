import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../models.dart';
import '../../theme.dart';
import '../../utils/glass_effect.dart';
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
  final void Function(String code, String? language, BuildContext ctx)?
  onApplyCode;

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
    final displayContent = streamingText != null
        ? '${message.content}\n$streamingText'
        : message.content;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: isUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          _buildReasoningBlock(),
          _buildCostBadge(context),
          _buildBubble(context, isUser, displayContent),
          _buildFileParts(),
          ..._buildToolParts(),
          const SizedBox(height: 2),
          Text(
            timeStr,
            style: const TextStyle(color: AppColors.textTertiary, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildReasoningBlock() {
    if (message.role == 'user' || !message.hasReasoning) {
      return const SizedBox.shrink();
    }
    return ReasoningBlock(content: message.reasoning!, isLatest: isLatest);
  }

  Widget _buildCostBadge(BuildContext context) {
    if (message.role == 'user' || message.cost <= 0) {
      return const SizedBox.shrink();
    }
    final isDark = isDarkMode(context);
    final successColor = isDark ? DarkColors.success : AppColors.success;
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: successColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '\$'
        '${message.cost.toStringAsFixed(4)}',
        style: TextStyle(
          color: successColor,
          fontSize: 10,
          fontFamily: 'monospace',
        ),
      ),
    );
  }

  Widget _buildFileParts() {
    final fileParts = message.parts.where((p) => p.type == 'file').toList();
    if (fileParts.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: FilePartsRow(parts: fileParts),
    );
  }

  List<Widget> _buildToolParts() {
    return message.parts
        .where((p) => p.type == 'tool')
        .map(
          (p) => ToolPartWidget(
            part: p,
            isLatest: isLatest,
            streamingText: streamingText,
          ),
        )
        .toList();
  }

  Widget _buildBubble(
    BuildContext context,
    bool isUser,
    String displayContent,
  ) {
    final shadows = ResponsiveTheme.getShadow(context, level: isUser ? 1 : 2);
    final bubbleRadius = BorderRadius.circular(isUser ? 16 : 14).copyWith(
      bottomRight: isUser ? const Radius.circular(4) : null,
      bottomLeft: !isUser ? const Radius.circular(4) : null,
    );

    Widget bubble;
    if (isUser) {
      bubble = Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
        ),
        padding: const EdgeInsets.only(
          left: 14,
          right: 14,
          top: 10,
          bottom: 10,
        ),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: bubbleRadius,
          boxShadow: shadows,
        ),
        child: _buildBubbleContent(isUser, displayContent),
      );
    } else {
      bubble = ClipRRect(
        borderRadius: bubbleRadius,
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(
            sigmaX: Glass.cardBlur,
            sigmaY: Glass.cardBlur,
          ),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.85,
            ),
            padding: const EdgeInsets.only(
              left: 14,
              right: 14,
              top: 8,
              bottom: 8,
            ),
            decoration: BoxDecoration(
              color: Glass.surface(context),
              borderRadius: bubbleRadius,
              border: Border.all(color: Glass.border(context), width: 0.5),
              boxShadow: shadows,
            ),
            child: _buildBubbleContent(isUser, displayContent),
          ),
        ),
      );
    }

    return GestureDetector(onLongPress: onLongPress, child: bubble);
  }

  Widget _buildBubbleContent(bool isUser, String displayContent) {
    if (isUser) {
      return Text(
        message.content,
        style: const TextStyle(color: AppColors.surface, fontSize: 14),
      );
    }
    return MarkdownBody(
      data: displayContent,
      selectable: true,
      builders: {'code_block': CodeBlockBuilder(onApply: onApplyCode)},
      styleSheet: _chatMarkdownStyle,
    );
  }

  static MarkdownStyleSheet get _chatMarkdownStyle => MarkdownStyleSheet(
    p: const TextStyle(color: AppColors.textPrimary, fontSize: 14, height: 1.5),
    h1: const TextStyle(
      color: AppColors.textPrimary,
      fontSize: 20,
      fontWeight: FontWeight.bold,
      height: 1.4,
    ),
    h2: const TextStyle(
      color: AppColors.textPrimary,
      fontSize: 17,
      fontWeight: FontWeight.bold,
      height: 1.4,
    ),
    h3: const TextStyle(
      color: AppColors.textPrimary,
      fontSize: 15,
      fontWeight: FontWeight.w600,
      height: 1.4,
    ),
    code: const TextStyle(
      color: AppColors.textPrimary,
      fontSize: 12,
      fontFamily: 'monospace',
      backgroundColor: AppColors.surfaceAlt,
    ),
    codeblockDecoration: BoxDecoration(
      color: AppColors.surfaceAlt,
      borderRadius: BorderRadius.circular(12),
    ),
    blockquoteDecoration: const BoxDecoration(
      border: Border(left: BorderSide(color: AppColors.primary, width: 3)),
      color: AppColors.surfaceAlt,
    ),
    listBullet: const TextStyle(color: AppColors.textSecondary),
    horizontalRuleDecoration: const BoxDecoration(
      border: Border(top: BorderSide(color: AppColors.border)),
    ),
    a: const TextStyle(
      color: AppColors.primary,
      decoration: TextDecoration.underline,
    ),
    strong: const TextStyle(fontWeight: FontWeight.bold),
    em: const TextStyle(fontStyle: FontStyle.italic),
    del: const TextStyle(decoration: TextDecoration.lineThrough),
    blockSpacing: 8,
    codeblockPadding: const EdgeInsets.all(10),
  );
}
