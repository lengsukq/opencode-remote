import 'package:flutter/material.dart';
import '../models.dart';
import '../theme.dart';
import '../services/opencode_api.dart';
import '../screens/native/dashboard_screen.dart';
import '../screens/native/session_list_screen.dart';
import '../screens/native/file_browser_screen.dart';
import '../screens/native/project_screen.dart';
import '../screens/native/config_screen.dart';
import '../screens/native/terminal_screen.dart';
import '../screens/settings_sheet.dart';

enum NavPage { dashboard, sessions, files, projects, config, terminal }

class MainScaffold extends StatefulWidget {
  final ServerEntry entry;

  const MainScaffold({super.key, required this.entry});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  NavPage _currentPage = NavPage.dashboard;
  late final OpenCodeApi _api;

  @override
  void initState() {
    super.initState();
    _api = OpenCodeApi(
      baseUrl: widget.entry.url,
      username: widget.entry.username,
      password: widget.entry.password,
    );
  }

  void _navigateTo(NavPage page) {
    setState(() => _currentPage = page);
  }

  void _openSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SettingsSheet(entry: widget.entry, currentMode: AppMode.native),
    );
  }

  Widget _buildPage() {
    switch (_currentPage) {
      case NavPage.dashboard:
        return DashboardScreen(entry: widget.entry, api: _api);
      case NavPage.sessions:
        return SessionListScreen(entry: widget.entry, api: _api);
      case NavPage.files:
        return FileBrowserScreen(entry: widget.entry, api: _api);
      case NavPage.projects:
        return ProjectScreen(entry: widget.entry, api: _api);
      case NavPage.config:
        return ConfigScreen(entry: widget.entry, api: _api);
      case NavPage.terminal:
        return TerminalScreen(entry: widget.entry, api: _api);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = isDarkMode(context);
    final bgColor = isDark ? DarkColors.surface : AppColors.surface;
    final selectedColor = isDark ? DarkColors.primary : AppColors.primary;
    final unselectedColor = isDark ? DarkColors.textTertiary : AppColors.textTertiary;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Row(
          children: [
            NavigationRail(
              selectedIndex: _currentPage.index,
              onDestinationSelected: (i) => _navigateTo(NavPage.values[i]),
              backgroundColor: bgColor,
              indicatorColor: selectedColor.withValues(alpha: 0.15),
              labelType: NavigationRailLabelType.all,
              leading: Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 16),
                child: Icon(Icons.code, color: selectedColor, size: 28),
              ),
              trailing: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: IconButton(
                  icon: Icon(Icons.settings, color: unselectedColor, size: 20),
                  onPressed: _openSettings,
                ),
              ),
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard),
                  label: Text('仪表'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.chat_outlined),
                  selectedIcon: Icon(Icons.chat),
                  label: Text('会话'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.folder_outlined),
                  selectedIcon: Icon(Icons.folder),
                  label: Text('文件'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.folder_special_outlined),
                  selectedIcon: Icon(Icons.folder_special),
                  label: Text('项目'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.monitor_heart_outlined),
                  selectedIcon: Icon(Icons.monitor_heart),
                  label: Text('诊断'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.terminal_outlined),
                  selectedIcon: Icon(Icons.terminal),
                  label: Text('终端'),
                ),
              ],
            ),
            const VerticalDivider(width: 1, thickness: 1),
            Expanded(child: _buildPage()),
          ],
        ),
      ),
    );
  }
}
