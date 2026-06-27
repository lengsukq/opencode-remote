import 'package:flutter/material.dart';
import '../../models.dart';
import '../../theme.dart';

/// Bar above input showing selected agent, model, token usage and sending indicator.
class AgentBar extends StatelessWidget {
  final String agentName;
  final Color agentColor;
  final String? selectedModel;
  final SessionTokens? tokens;
  final bool sending;
  final VoidCallback onAgentTap;
  final VoidCallback onModelTap;

  static const _kContextWindowTokens = 128000;

  const AgentBar({
    super.key,
    required this.agentName,
    required this.agentColor,
    this.selectedModel,
    this.tokens,
    this.sending = false,
    required this.onAgentTap,
    required this.onModelTap,
  });

  @override
  Widget build(BuildContext context) {
    final totalTokens = tokens != null ? tokens!.input + tokens!.output + tokens!.reasoning : 0;
    final contextPct = totalTokens > 0 ? (totalTokens / _kContextWindowTokens).clamp(0.0, 1.0) : 0.0;
    final ctxColor = contextPct < 0.5 ? AppColors.success : (contextPct < 0.8 ? AppColors.warning : AppColors.danger);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          AgentRowChip(
            icon: Icons.smart_toy,
            label: agentName,
            color: agentColor,
            onTap: onAgentTap,
          ),
          const SizedBox(width: 8),
          AgentRowChip(
            icon: Icons.model_training,
            label: selectedModel != null ? selectedModel!.split('/').last : 'Model',
            color: selectedModel != null ? AppColors.primary : AppColors.textSecondary,
            onTap: onModelTap,
          ),
          if (totalTokens > 0) ...[
            const SizedBox(width: 8),
            Tooltip(
              message: 'Context: $totalTokens / ${_kContextWindowTokens ~/ 1000}K tokens',
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: ctxColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.memory, size: 12, color: ctxColor),
                    const SizedBox(width: 3),
                    Text('${(contextPct * 100).toInt()}%', style: TextStyle(color: ctxColor, fontSize: 10)),
                  ],
                ),
              ),
            ),
          ],
          if (sending) ...[
            const Spacer(),
            SizedBox(
              width: 14, height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
            ),
          ],
        ],
      ),
    );
  }
}

/// Small clickable chip used inside [AgentBar].
class AgentRowChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const AgentRowChip({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500)),
            const SizedBox(width: 2),
            Icon(Icons.arrow_drop_down, color: color, size: 16),
          ],
        ),
      ),
    );
  }
}
