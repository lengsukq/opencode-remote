import 'package:flutter/material.dart';
import '../models.dart';
import '../strings.dart';
import '../theme.dart';
import '../services/opencode_api.dart';
import '../utils/time_format.dart';
import '../utils/responsive.dart';
import '../utils/responsive_values.dart';
import '../widgets/app_card.dart';
import '../screens/native/session_list_screen.dart';
import '../screens/native/file_browser_screen.dart';
import '../screens/native/project_screen.dart';
import '../screens/native/config_screen.dart';
import '../screens/native/chat_screen.dart';

class DashboardStatusCard extends StatelessWidget {
  final HealthStatus? health;
  final String url;

  const DashboardStatusCard({
    super.key,
    required this.health,
    required this.url,
  });

  @override
  Widget build(BuildContext context) {
    final uri = Uri.tryParse(url);
    final host = uri != null && uri.host.isNotEmpty
        ? '${uri.host}:${uri.port}'
        : url;
    final isHealthy = health?.healthy ?? false;

    return Container(
      padding: R.screenPadding(context),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppColors.kDefaultBorderRadius),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.shadowLevel3,
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isHealthy ? AppColors.success : AppColors.danger,
              boxShadow: [
                BoxShadow(
                  color: (isHealthy ? AppColors.success : AppColors.danger)
                      .withValues(alpha: 0.4),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
          SizedBox(width: R.smallSpacing(context)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  host,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: R.bodyFontSize(context),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isHealthy
                      ? 'v${health?.version ?? "?"} \u00b7 ${S.connected}'
                      : S.unableToConnect,
                  style: TextStyle(
                    color: isHealthy ? AppColors.success : AppColors.danger,
                    fontSize: R.smallFontSize(context),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: R.smallSpacing(context),
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: isHealthy
                  ? AppColors.success.withValues(alpha: 0.1)
                  : AppColors.danger.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppColors.kChipBorderRadius),
            ),
            child: Text(
              isHealthy ? S.online : S.offline,
              style: TextStyle(
                color: isHealthy ? AppColors.success : AppColors.danger,
                fontSize: R.labelFontSize(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DashboardSessionCard extends StatelessWidget {
  final Session session;
  final OpenCodeApi api;
  final ServerEntry entry;
  final Project? activeProject;

  const DashboardSessionCard({
    super.key,
    required this.session,
    required this.api,
    required this.entry,
    this.activeProject,
  });

  @override
  Widget build(BuildContext context) {
    final timeStr = formatRelativeTime(session.updatedAt);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: AppCard(
        borderRadius: AppColors.kCardBorderRadius,
        padding: EdgeInsets.zero,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppColors.kCardBorderRadius),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    ChatScreen(session: session, entry: entry, api: api),
              ),
            );
          },
          child: Padding(
            padding: R.cardPadding(context),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(R.smallSpacing(context)),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(
                      AppColors.kSmallBorderRadius,
                    ),
                  ),
                  child: Icon(
                    Icons.chat,
                    color: AppColors.primary,
                    size: R.smallIconSize(context),
                  ),
                ),
                SizedBox(width: R.spacing(context)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.title.isNotEmpty ? session.title : '未命名会话',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: R.smallFontSize(context),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        timeStr,
                        style: TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: R.labelFontSize(context),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: AppColors.textTertiary,
                  size: R.smallIconSize(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DashboardQuickActions extends StatelessWidget {
  final OpenCodeApi api;
  final ServerEntry entry;
  final Project? activeProject;

  const DashboardQuickActions({
    super.key,
    required this.api,
    required this.entry,
    this.activeProject,
  });

  @override
  Widget build(BuildContext context) {
    final isPhone = ResponsiveUtils.isPhone(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          S.quickActions,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: R.smallFontSize(context),
          ),
        ),
        SizedBox(height: R.smallSpacing(context)),
        if (isPhone)
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: R.smallSpacing(context),
            crossAxisSpacing: R.smallSpacing(context),
            childAspectRatio: 1.5,
            children: [
              DashboardActionButton(
                icon: Icons.add,
                label: '新建会话',
                color: AppColors.primary,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SessionListScreen(
                        entry: entry,
                        api: api,
                        activeProject: activeProject,
                      ),
                    ),
                  );
                },
              ),
              DashboardActionButton(
                icon: Icons.folder,
                label: '文件浏览',
                color: AppColors.success,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FileBrowserScreen(
                        entry: entry,
                        api: api,
                        activeProject: activeProject,
                      ),
                    ),
                  );
                },
              ),
              DashboardActionButton(
                icon: Icons.swap_horiz,
                label: '切换项目',
                color: AppColors.warning,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProjectScreen(entry: entry, api: api),
                    ),
                  );
                },
              ),
              DashboardActionButton(
                icon: Icons.monitor_heart,
                label: '诊断',
                color: AppColors.primary,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ConfigScreen(entry: entry, api: api),
                    ),
                  );
                },
              ),
            ],
          )
        else
          Row(
            children: [
              Expanded(
                child: DashboardActionButton(
                  icon: Icons.add,
                  label: '新建会话',
                  color: AppColors.primary,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SessionListScreen(
                          entry: entry,
                          api: api,
                          activeProject: activeProject,
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(width: R.smallSpacing(context)),
              Expanded(
                child: DashboardActionButton(
                  icon: Icons.folder,
                  label: '文件浏览',
                  color: AppColors.success,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FileBrowserScreen(
                          entry: entry,
                          api: api,
                          activeProject: activeProject,
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(width: R.smallSpacing(context)),
              Expanded(
                child: DashboardActionButton(
                  icon: Icons.swap_horiz,
                  label: '切换项目',
                  color: AppColors.warning,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProjectScreen(entry: entry, api: api),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(width: R.smallSpacing(context)),
              Expanded(
                child: DashboardActionButton(
                  icon: Icons.monitor_heart,
                  label: '诊断',
                  color: AppColors.primary,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ConfigScreen(entry: entry, api: api),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class DashboardActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const DashboardActionButton({
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
        padding: EdgeInsets.symmetric(vertical: R.mediumSpacing(context)),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppColors.kCardBorderRadius),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: R.iconSize(context)),
            SizedBox(height: R.smallSpacing(context)),
            Text(
              label,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: R.labelFontSize(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardProjectContextCard extends StatelessWidget {
  final Project project;

  const DashboardProjectContextCard({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: R.screenPadding(context),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppColors.kDefaultBorderRadius),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.shadowLevel3,
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(R.spacing(context)),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(AppColors.kCardBorderRadius),
            ),
            child: const Icon(Icons.folder, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  project.name,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: R.subtitleFontSize(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  project.path,
                  style: TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: R.labelFontSize(context),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
