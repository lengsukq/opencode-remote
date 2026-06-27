import 'package:flutter/material.dart';
import '../models.dart';
import '../theme.dart';
import '../strings.dart';
import '../services/opencode_api.dart';
import '../screens/native/dashboard_screen.dart';
import '../screens/native/session_list_screen.dart';
import '../screens/native/file_browser_screen.dart';
import '../screens/native/project_screen.dart';
import '../screens/native/config_screen.dart';
import '../screens/native/terminal_screen.dart';
import '../screens/settings_sheet.dart';
import 'project_avatar.dart';

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
  List<Project> _projects = [];
  Project? _activeProject;

  @override
  void initState() {
    super.initState();
    _api = OpenCodeApi(
      baseUrl: widget.entry.url,
      username: widget.entry.username,
      password: widget.entry.password,
    );
    _initProjects();
  }

  List<NavPage> get _navPages => NavPage.values.where((p) => p != NavPage.projects).toList();

  void _initProjects() async {
    try {
      final projects = await _api.getProjects();
      final current = await _api.getCurrentProject();
      if (mounted) {
        setState(() {
          _projects = projects;
          _activeProject = current;
        });
      }
      if (current != null) _api.directory = current.path;
    } catch (_) {}
  }

  void _switchProject(Project project) {
    _api.directory = project.path;
    setState(() {
      _activeProject = project;
      if (_currentPage == NavPage.projects) {
        _currentPage = NavPage.dashboard;
      }
    });
  }

  void _navigateTo(NavPage page) {
    setState(() => _currentPage = page);
  }

  void _openSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppColors.kDefaultBorderRadius)),
      ),
      builder: (_) => SettingsSheet(entry: widget.entry, currentMode: AppMode.native),
    );
  }

  Widget _buildPage() {
    switch (_currentPage) {
      case NavPage.dashboard:
        return DashboardScreen(entry: widget.entry, api: _api, activeProject: _activeProject);
      case NavPage.sessions:
        return SessionListScreen(entry: widget.entry, api: _api, activeProject: _activeProject);
      case NavPage.files:
        return FileBrowserScreen(entry: widget.entry, api: _api, activeProject: _activeProject);
      case NavPage.projects:
        return ProjectScreen(entry: widget.entry, api: _api);
      case NavPage.config:
        return ConfigScreen(entry: widget.entry, api: _api, activeProject: _activeProject);
      case NavPage.terminal:
        return TerminalScreen(entry: widget.entry, api: _api, activeProject: _activeProject);
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
              selectedIndex: _navPages.indexOf(_currentPage),
              onDestinationSelected: (i) => _navigateTo(_navPages[i]),
              backgroundColor: bgColor,
              indicatorColor: selectedColor.withValues(alpha: 0.15),
              labelType: NavigationRailLabelType.all,
              leading: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 16),
                    child: Icon(Icons.code, color: selectedColor, size: 28),
                  ),
                  if (_projects.isNotEmpty)
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 300),
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ..._projects.map((p) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: ProjectAvatar(
                                project: p,
                                isActive: _activeProject?.id == p.id,
                                onTap: () => _switchProject(p),
                              ),
                            )),
                            const SizedBox(height: 4),
                            IconButton(
                              icon: Icon(Icons.add_circle_outline, color: unselectedColor, size: 20),
                              onPressed: () {
                                // TODO: 对接 Agent B 的 AddProjectDialog
                                debugPrint('添加项目按钮被点击');
                              },
                              tooltip: S.addProject,
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (_projects.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: IconButton(
                        icon: Icon(Icons.add_circle_outline, color: unselectedColor, size: 20),
                        onPressed: () {
                          // TODO: 对接 Agent B 的 AddProjectDialog
                          debugPrint('添加项目按钮被点击');
                        },
                        tooltip: S.addProject,
                      ),
                    ),
                ],
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
                  label: Text(S.dashboard),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.chat_outlined),
                  selectedIcon: Icon(Icons.chat),
                  label: Text(S.sessions),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.folder_outlined),
                  selectedIcon: Icon(Icons.folder),
                  label: Text(S.files),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.monitor_heart_outlined),
                  selectedIcon: Icon(Icons.monitor_heart),
                  label: Text(S.diagnostics),
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
