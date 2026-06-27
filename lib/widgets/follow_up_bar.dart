import 'package:flutter/material.dart';
import '../theme.dart';

/// A bar showing follow-up suggestion chips.
class FollowUpBar extends StatelessWidget {
  final List<String> suggestions;
  final ValueChanged<String> onSend;

  const FollowUpBar({
    super.key,
    required this.suggestions,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '建议后续',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: suggestions.map((suggestion) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ActionChip(
                  label: Text(
                    suggestion,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                    ),
                  ),
                  backgroundColor: AppColors.surfaceAlt,
                  side: BorderSide(color: AppColors.border),
                  onPressed: () => onSend(suggestion),
                ),
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
