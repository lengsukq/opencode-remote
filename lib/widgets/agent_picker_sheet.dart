import 'package:flutter/material.dart';
import '../models/agent.dart';
import '../strings.dart';
import '../theme.dart';
import 'app_bottom_sheet.dart';

/// Shows a bottom sheet for selecting an agent.
///
/// Returns the selected agent name, or `null` if dismissed.
Future<String?> showAgentPicker(
  BuildContext context, {
  required List<Agent> agents,
  String? selectedAgent,
}) {
  return AppBottomSheet.show<String>(
    context: context,
    child: SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              S.selectAgent,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Divider(),
          ...agents.map(
            (a) => ListTile(
              leading: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.smart_toy,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
              title: Text(
                a.name,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: a.description != null
                  ? Text(
                      a.description!,
                      style: const TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 12,
                      ),
                    )
                  : null,
              trailing: selectedAgent == a.name
                  ? const Icon(Icons.check, color: AppColors.primary)
                  : null,
              onTap: () => Navigator.pop(context, a.name),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}
