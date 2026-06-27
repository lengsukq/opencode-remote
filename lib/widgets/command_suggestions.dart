import 'package:flutter/material.dart';
import '../../models.dart';
import '../../theme.dart';

/// Filtered command suggestions list shown above the input bar.
class CommandSuggestions extends StatelessWidget {
  final List<Command> commands;
  final ValueChanged<Command> onSelect;

  const CommandSuggestions({
    super.key,
    required this.commands,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: ListView(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        children: commands.map((c) => ListTile(
          dense: true,
          leading: Icon(Icons.terminal, color: AppColors.primary, size: 18),
          title: Text('/${c.id}', style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontFamily: 'monospace')),
          subtitle: c.description != null ? Text(c.description!, style: TextStyle(color: AppColors.textTertiary, fontSize: 11)) : null,
          onTap: () => onSelect(c),
        )).toList(),
      ),
    );
  }
}
