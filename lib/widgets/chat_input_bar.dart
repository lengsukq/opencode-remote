import 'package:flutter/material.dart';
import '../../theme.dart';

/// Chat input bar with text field, attachment button and send/stop button.
class ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool shellMode;
  final bool sending;
  final VoidCallback onSend;
  final VoidCallback onAbort;
  final VoidCallback onPickAttachment;

  const ChatInputBar({
    super.key,
    required this.controller,
    required this.shellMode,
    required this.sending,
    required this.onSend,
    required this.onAbort,
    required this.onPickAttachment,
  });

  @override
  Widget build(BuildContext context) {
    final shellHint = shellMode
        ? 'Enter shell command...'
        : 'Enter message... (/ for commands)';
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              if (!sending)
                IconButton(
                  onPressed: onPickAttachment,
                  icon: const Icon(
                    Icons.add_circle_outline,
                    color: AppColors.primary,
                  ),
                  tooltip: 'Add attachment',
                ),
              const SizedBox(width: 4),
              Expanded(
                child: TextField(
                  controller: controller,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontFamily: shellMode ? 'monospace' : null,
                  ),
                  decoration: InputDecoration(
                    hintText: shellHint,
                    hintStyle: TextStyle(
                      color: AppColors.textTertiary,
                      fontFamily: shellMode ? 'monospace' : null,
                    ),
                    filled: true,
                    fillColor: shellMode
                        ? AppColors.surfaceAlt
                        : AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(
                        color: shellMode ? AppColors.success : AppColors.border,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(
                        color: shellMode ? AppColors.success : AppColors.border,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(
                        color: AppColors.borderFocused,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                  maxLines: 4,
                  minLines: 1,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => sending ? null : onSend(),
                  onEditingComplete: () {
                    if (!sending) onSend();
                  },
                ),
              ),
              const SizedBox(width: 8),
              if (sending)
                IconButton(
                  onPressed: onAbort,
                  icon: const Icon(Icons.stop_circle, color: AppColors.danger),
                  tooltip: 'Stop',
                )
              else
                IconButton(
                  onPressed: onSend,
                  icon: const Icon(Icons.send, color: AppColors.primary),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
