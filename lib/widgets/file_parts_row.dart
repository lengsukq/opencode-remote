import 'package:flutter/material.dart';
import '../../models.dart';
import '../../theme.dart';

/// A row of file thumbnails/attachments shown inline in messages.
class FilePartsRow extends StatelessWidget {
  final List<Part> parts;

  const FilePartsRow({super.key, required this.parts});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        shrinkWrap: true,
        itemCount: parts.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (ctx, i) {
          final p = parts[i];
          final file = p.file;
          if (file == null) return const SizedBox.shrink();
          final isImage = file.mime.startsWith('image/');
          final shortName = file.filename ?? file.url.split('/').last;
          final displayName = shortName.length > 20 ? '${shortName.substring(0, 17)}...' : shortName;
          return Container(
            width: 140,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: isImage
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          file.url,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Center(
                            child: Icon(Icons.broken_image, color: AppColors.textSecondary, size: 28),
                          ),
                          loadingBuilder: (_, child, progress) {
                            if (progress == null) return child;
                            return Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary));
                          },
                        ),
                        Positioned(
                          bottom: 0, left: 0, right: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter, end: Alignment.topCenter,
                                colors: [AppColors.overlayDark, Colors.transparent],
                              ),
                            ),
                            child: Text(displayName, style: const TextStyle(color: AppColors.surface, fontSize: 10)),
                          ),
                        ),
                      ],
                    ),
                  )
                : Row(
                    children: [
                      const SizedBox(width: 8),
                      Icon(Icons.insert_drive_file, color: AppColors.textSecondary, size: 24),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(displayName, style: TextStyle(color: AppColors.textPrimary, fontSize: 11), overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
          );
        },
      ),
    );
  }
}
