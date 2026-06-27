import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../theme.dart';

/// Horizontal scrollable list of attachment chips with thumbnails.
class AttachmentPreview extends StatelessWidget {
  final List<Map<String, dynamic>> attachments;
  final ValueChanged<int> onRemove;

  const AttachmentPreview({
    super.key,
    required this.attachments,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: SizedBox(
        height: 48,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: attachments.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (ctx, i) {
            final att = attachments[i];
            final name = att['filename'] as String? ?? '';
            final mime = att['mime'] as String? ?? '';
            final isImage = mime.startsWith('image/');
            return Chip(
              avatar: isImage
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.memory(
                        _dataUriBytes(att['url'] as String? ?? ''),
                        width: 32,
                        height: 32,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const Icon(
                          Icons.image,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    )
                  : const Icon(
                      Icons.attach_file,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
              label: Text(
                name.length > 20 ? '${name.substring(0, 17)}...' : name,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                ),
              ),
              deleteIcon: const Icon(
                Icons.close,
                size: 14,
                color: AppColors.textTertiary,
              ),
              onDeleted: () => onRemove(i),
              backgroundColor: AppColors.background,
              side: const BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              visualDensity: VisualDensity.compact,
            );
          },
        ),
      ),
    );
  }

  static Uint8List _dataUriBytes(String dataUri) {
    final comma = dataUri.indexOf(',');
    if (comma < 0) return Uint8List(0);
    try {
      return base64Decode(dataUri.substring(comma + 1));
    } catch (e) {
      // ignore: use_debug_print_in_production
      debugPrint('AttachmentPreview._dataUriBytes: $e');
      return Uint8List(0);
    }
  }
}
