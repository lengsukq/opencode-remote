import 'package:flutter/material.dart';
import '../models/part.dart';
import '../models/session.dart';
import '../strings.dart';
import '../theme.dart';

/// Shows a dialog with detailed information about a message.
void showMessageDetail(BuildContext context, SessionMessageResponse detail) {
  showDialog(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: AppColors.surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppBar(
            title: const Text(
              S.messageDetails,
              style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
            ),
            leading: IconButton(
              icon: const Icon(Icons.close, color: AppColors.textSecondary),
              onPressed: () => Navigator.pop(ctx),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildInfoRow(S.id, detail.info.id),
                _buildInfoRow(S.role, detail.info.role),
                _buildInfoRow('Parts', detail.parts.length.toString()),
                const SizedBox(height: 12),
                const Text(
                  'Parts:',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                ...detail.parts
                    .take(10)
                    .map(
                      (p) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '  [${p.type}] ${_partSummary(p)}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 11,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildInfoRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
          ),
        ),
      ],
    ),
  );
}

String _partSummary(Part p) => switch (p.type) {
  'text' => p.text ?? '',
  'reasoning' => p.reasoningText ?? '',
  'tool' => '${p.tool?.tool ?? ''}: ${p.tool?.stateStatus ?? ''}',
  'file' => p.file?.filename ?? p.file?.url ?? '',
  'subtask' => '${p.subtask?.agent ?? ''}: ${p.subtask?.description ?? ''}',
  'step-start' => '',
  'step-finish' => p.stepFinish?.reason ?? '',
  'snapshot' => '',
  'patch' => '${p.patch?.files.length ?? 0} files',
  'agent' => p.agent?.name ?? '',
  'retry' => 'attempt ${p.retry?.attempt}',
  'compaction' => p.compaction?.auto == true ? 'auto' : '',
  _ => '',
};
