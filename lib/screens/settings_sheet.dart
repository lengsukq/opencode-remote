import 'package:flutter/material.dart';
import '../models.dart';
import '../theme.dart';
import '../services/storage_service.dart';
import '../main.dart' show themeNotifier;
import 'native/dashboard_screen.dart';
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
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 36, height: 4,
            decoration: BoxDecoration(
              color: AppColors.textTertiary,
              borderRadius: BorderRadius.circular(2),
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
                Text('运行模式', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
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
                Text('主题', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
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
          const SizedBox(height: 8),
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
            ? DashboardScreen(entry: widget.entry)
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryLight : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? AppColors.primary : AppColors.textSecondary, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(
                    color: selected ? AppColors.primary : AppColors.textPrimary,
                    fontSize: 14, fontWeight: FontWeight.w500,
                  )),
                  Text(subtitle, style: TextStyle(color: AppColors.textTertiary, fontSize: 11)),
                ],
              ),
            ),
            if (selected)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 12),
              ),
          ],
        ),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryLight : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? AppColors.primary : AppColors.textSecondary, size: 20),
            const SizedBox(width: 10),
            Text(title, style: TextStyle(
              color: selected ? AppColors.primary : AppColors.textPrimary,
              fontSize: 13, fontWeight: FontWeight.w500,
            )),
            const Spacer(),
            if (selected)
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 10),
              ),
          ],
        ),
      ),
    );
  }
}
