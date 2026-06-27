import 'dart:convert';
export 'package:image_picker/image_picker.dart' show ImageSource;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../strings.dart';
import '../theme.dart';
import 'app_bottom_sheet.dart';

const _mimeMap = <String, String>{
  'png': 'image/png', 'jpg': 'image/jpeg', 'jpeg': 'image/jpeg',
  'gif': 'image/gif', 'webp': 'image/webp', 'svg': 'image/svg+xml',
  'pdf': 'application/pdf', 'md': 'text/markdown', 'json': 'application/json',
  'py': 'text/x-python', 'dart': 'text/x-dart', 'js': 'text/javascript',
  'ts': 'text/typescript', 'html': 'text/html', 'css': 'text/css',
  'yaml': 'text/yaml', 'yml': 'text/yaml', 'txt': 'text/plain',
};

/// Returns the MIME type for a file extension.
String mimeFromExt(String ext) => _mimeMap[ext.toLowerCase()] ?? 'application/octet-stream';

/// Creates an attachment map from raw bytes and a filename.
Map<String, dynamic> createAttachment(String filename, List<int> bytes) {
  final b64 = base64Encode(bytes);
  final mime = mimeFromExt(filename.split('.').last.toLowerCase());
  return {'type': 'file', 'mime': mime, 'url': 'data:$mime;base64,$b64', 'filename': filename};
}

/// Shows a bottom sheet for picking an attachment type (image/camera/file).
///
/// Returns one of `'image'`, `'camera'`, `'file'`, or `null` if dismissed.
Future<String?> showAttachmentPicker(BuildContext context) {
  return AppBottomSheet.show<String>(
    context: context,
    child: SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(S.addAttachment, style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
          ),
          const Divider(height: 1),
          _attachmentOption(context, Icons.image, S.image, S.fromGallery, 'image'),
          _attachmentOption(context, Icons.camera_alt, S.camera, S.takeAPhoto, 'camera'),
          _attachmentOption(context, Icons.attach_file, S.file, S.fromLocalStorage, 'file'),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

Widget _attachmentOption(BuildContext ctx, IconData icon, String title, String subtitle, String value) {
  return ListTile(
    leading: Icon(icon, color: AppColors.primary),
    title: Text(title, style: const TextStyle(color: AppColors.textPrimary)),
    subtitle: Text(subtitle, style: const TextStyle(color: AppColors.textTertiary, fontSize: 12)),
    onTap: () => Navigator.pop(ctx, value),
  );
}

/// Picks an image from the gallery or camera and returns attachment data.
Future<Map<String, dynamic>?> pickImageAttachment(ImageSource source) async {
  final xFile = await ImagePicker().pickImage(source: source);
  if (xFile == null) return null;
  final bytes = await xFile.readAsBytes();
  return createAttachment(xFile.name, bytes);
}

/// Picks a file from local storage and returns attachment data.
Future<Map<String, dynamic>?> pickFileAttachment() async {
  final result = await FilePicker.platform.pickFiles();
  if (result == null || result.files.isEmpty) return null;
  final file = result.files.first;
  if (file.bytes == null) return null;
  return createAttachment(file.name, file.bytes!);
}
