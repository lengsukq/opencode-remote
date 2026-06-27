import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../theme.dart';
import '../strings.dart';

/// Markdown element builder for syntax-highlighted code blocks with copy/apply actions.
class CodeBlockBuilder extends MarkdownElementBuilder {
  final void Function(String code, String? language, BuildContext ctx)? onApply;

  CodeBlockBuilder({this.onApply});

  @override
  Widget? visitElementAfter(element, TextStyle? preferredStyle) {
    final code = element.textContent;
    final language = element.attributes['language'] ?? 'plaintext';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppColors.kSmallBorderRadius),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            color: AppColors.border,
            child: Row(
              children: [
                Text(
                  language,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                    fontFamily: 'monospace',
                  ),
                ),
                const Spacer(),
                Builder(
                  builder: (ctx) => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (onApply != null)
                        GestureDetector(
                          onTap: () => onApply!(code, language, ctx),
                          child: const Icon(
                            Icons.smart_toy_outlined,
                            size: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      if (onApply != null) const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: code));
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(
                              content: Text(S.copied),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                        child: const Icon(
                          Icons.content_copy,
                          size: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],
                  ),
                ),
              ],
            ),
          ),
          HighlightView(
            code,
            language: language,
            theme: githubTheme,
            padding: const EdgeInsets.all(12),
            textStyle: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
