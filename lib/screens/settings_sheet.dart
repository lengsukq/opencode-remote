import 'package:flutter/material.dart';
import '../models.dart';
import '../theme.dart';
import '../services/storage_service.dart';
import '../main.dart' show themeNotifier;
import '../widgets/main_scaffold.dart';
import '../widgets/app_card.dart';
import '../widgets/app_section_header.dart';
import '../widgets/app_selectable_tile.dart';
import 'launcher_screen.dart';
class SettingsSheet extends StatefulWidget {
  final ServerEntry entry;
  final AppMode currentMode;

  const SettingsSheet({
    super.key,
    required this.entry,
    required this.currentMode,
  });

  @override
  State<SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<SettingsSheet> {
  late AppMode _mode;
  late ThemeMode _themeMode;

  @override
  void initState() {
    super.initState();
    _mode = widget.currentMode;
    _themeMode = themeNotifier.value;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppColors.kDefaultBorderRadius)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 36, height: 4,
            decoration: BoxDecoration(
              color: AppColors.textTertiary,
              borderRadius: BorderRadius.circular(AppColors.kChipBorderRadius),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Text('设置', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppSectionHeader('运行模式'),
                const SizedBox(height: 8),
                _ModeTile(
                  icon: Icons.public,
                  title: 'WebView 模式',
                  subtitle: '通过浏览器界面远程控制',
                  selected: _mode == AppMode.webview,
                  onTap: () => _switchMode(context, AppMode.webview),
                ),
                const SizedBox(height: 4),
                _ModeTile(
                  icon: Icons.phone_android,
                  title: '原生模式',
                  subtitle: '使用原生 Flutter 界面',
                  selected: _mode == AppMode.native,
                  onTap: () => _switchMode(context, AppMode.native),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppSectionHeader('主题'),
                const SizedBox(height: 8),
                _ThemeTile(
                  icon: Icons.light_mode,
                  title: '浅色',
                  selected: _themeMode == ThemeMode.light,
                  onTap: () => _setTheme(ThemeMode.light),
                ),
                const SizedBox(height: 4),
                _ThemeTile(
                  icon: Icons.dark_mode,
                  title: '深色',
                  selected: _themeMode == ThemeMode.dark,
                  onTap: () => _setTheme(ThemeMode.dark),
                ),
                const SizedBox(height: 4),
                _ThemeTile(
                  icon: Icons.settings_brightness,
                  title: '跟随系统',
                  selected: _themeMode == ThemeMode.system,
                  onTap: () => _setTheme(ThemeMode.system),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppSectionHeader('关于'),
                const SizedBox(height: 8),
                AppCard(
                  color: Colors.transparent,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(AppColors.kSmallBorderRadius),
                        ),
                        child: const Icon(Icons.code, color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('OpenCode Remote', style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
                            Text('v1.0.0', style: TextStyle(color: AppColors.textTertiary, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Future<void> _setTheme(ThemeMode mode) async {
    await StorageService.setThemeMode(mode);
    themeNotifier.value = mode;
    setState(() => _themeMode = mode);
  }

  Future<void> _switchMode(BuildContext context, AppMode mode) async {
    await StorageService.setAppMode(mode);
    if (!context.mounted) return;
    Navigator.pop(context);
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => mode == AppMode.native
            ? MainScaffold(entry: widget.entry) as Widget
            : LauncherScreen(initialMode: AppMode.webview, initialEntry: widget.entry),
      ),
      (route) => false,
    );
  }
}

class _ModeTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _ModeTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppSelectableTile(
        icon: icon,
        title: title,
        subtitle: subtitle,
        selected: selected,
        onTap: onTap,
      ),
    );
  }
}

class _ThemeTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeTile({required this.icon, required this.title, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppSelectableTile(
        icon: icon,
        title: title,
        selected: selected,
        onTap: onTap,
      ),
    );
  }
}
