import 'dart:async';
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
import '../utils/project_helpers.dart';

import '../utils/responsive.dart';
import '../utils/responsive_values.dart';
import 'project_avatar.dart';
import 'add_project_dialog.dart';
import 'app_snackbar.dart';

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
      _api.directory = current.path;
      // 后台持久化：不阻塞 UI
      unawaited(ProjectHelpers.saveProjects(widget.entry.id, projects));
    } catch (e) {
      debugPrint('MainScaffold._initProjects: $e');
    }
  }

  Future<void> _showAddProjectDialog() async {
    final project = await showDialog<Project>(
      context: context,
      builder: (_) => AddProjectDialog(api: _api),
    );
    if (project == null || !mounted) return;
    AppSnackBar.success(context, '${S.projectAdded}: ${project.name}');
    // 刷新项目列表并切换到新项目
    _initProjects();
    _switchProject(project);
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

  Future<void> _closeProject(Project project) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(S.closeProject, style: const TextStyle(color: AppColors.textPrimary)),
        content: Text('${S.confirmCloseProject}\n${project.name}', style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(S.cancel, style: TextStyle(color: AppColors.textSecondary))),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(S.closeProject),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    try {
      await _api.removeProject(project.id);
    } catch (e) {
      debugPrint('MainScaffold._closeProject: failed to remove project $e');
    }
    if (_activeProject?.id == project.id) {
      _activeProject = null;
      _api.directory = null;
    }
    _initProjects();
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
        return ProjectScreen(entry: widget.entry, api: _api, onProjectsChanged: _initProjects);
      case NavPage.config:
        return ConfigScreen(entry: widget.entry, api: _api, activeProject: _activeProject);
      case NavPage.terminal:
        return TerminalScreen(entry: widget.entry, api: _api, activeProject: _activeProject);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPhone = ResponsiveUtils.isPhone(context);

    return isPhone ? _buildPhoneLayout(context) : _buildTabletLayout(context);
  }

  /// 手机布局：使用 BottomNavigationBar
  Widget _buildPhoneLayout(BuildContext context) {
    final isDark = isDarkMode(context);
    final selectedColor = isDark ? DarkColors.primary : AppColors.primary;
    final unselectedColor = isDark ? DarkColors.textTertiary : AppColors.textTertiary;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_getPageTitle()),
        actions: [
          if (_activeProject != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(AppColors.kChipBorderRadius),
                  ),
                  child: Text(
                    _activeProject!.name,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          IconButton(
            icon: Icon(Icons.settings, color: unselectedColor, size: R.iconSize(context)),
            onPressed: _openSettings,
          ),
        ],
      ),
      body: _buildPage(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _navPages.indexOf(_currentPage),
        onTap: (i) => _navigateTo(_navPages[i]),
        type: BottomNavigationBarType.fixed,
        backgroundColor: isDark ? DarkColors.surface : AppColors.surface,
        selectedItemColor: selectedColor,
        unselectedItemColor: unselectedColor,
        selectedFontSize: R.labelFontSize(context),
        unselectedFontSize: R.labelFontSize(context),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: S.dashboard,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_outlined),
            activeIcon: Icon(Icons.chat),
            label: S.sessions,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.folder_outlined),
            activeIcon: Icon(Icons.folder),
            label: S.files,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.monitor_heart_outlined),
            activeIcon: Icon(Icons.monitor_heart),
            label: S.diagnostics,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.terminal_outlined),
            activeIcon: Icon(Icons.terminal),
            label: S.terminal,
          ),
        ],
      ),
    );
  }

  /// 平板布局：使用 NavigationRail
  Widget _buildTabletLayout(BuildContext context) {
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
                  if (_activeProject != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        _activeProject!.name,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
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
                                onLongPress: p.id == _activeProject?.id ? () => _closeProject(p) : null,
                              ),
                            )),
                            const SizedBox(height: 4),
                            IconButton(
                              icon: Icon(Icons.add_circle_outline, color: unselectedColor, size: 20),
                              onPressed: _showAddProjectDialog,
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
                        onPressed: _showAddProjectDialog,
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
                  label: Text(S.terminal),
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

  /// 获取页面标题
  String _getPageTitle() {
    switch (_currentPage) {
      case NavPage.dashboard:
        return S.dashboard;
      case NavPage.sessions:
        return S.sessions;
      case NavPage.files:
        return S.files;
      case NavPage.projects:
        return '项目';
      case NavPage.config:
        return S.diagnostics;
      case NavPage.terminal:
        return S.terminal;
    }
  }
}
