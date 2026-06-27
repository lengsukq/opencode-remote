import 'package:flutter/material.dart';
import '../models.dart';
import '../strings.dart';
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
          _buildDragHandle(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Text(S.settings, style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const Divider(),
          _buildModeSection(),
          _buildThemeSection(),
          _buildAboutSection(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildDragHandle() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      width: 36, height: 4,
      decoration: BoxDecoration(
        color: AppColors.textTertiary,
        borderRadius: BorderRadius.circular(AppColors.kChipBorderRadius),
      ),
    );
  }

  Widget _buildModeSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(S.runMode),
          const SizedBox(height: 8),
          _ModeTile(
            icon: Icons.public,
            title: S.webviewMode,
            subtitle: S.webviewDesc,
            selected: _mode == AppMode.webview,
            onTap: () => _switchMode(context, AppMode.webview),
          ),
          const SizedBox(height: 4),
          _ModeTile(
            icon: Icons.phone_android,
            title: S.nativeMode,
            subtitle: S.nativeDesc,
            selected: _mode == AppMode.native,
            onTap: () => _switchMode(context, AppMode.native),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(S.theme),
          const SizedBox(height: 8),
          _ThemeTile(icon: Icons.light_mode, title: S.light,
            selected: _themeMode == ThemeMode.light,
            onTap: () => _setTheme(ThemeMode.light),
          ),
          const SizedBox(height: 4),
          _ThemeTile(icon: Icons.dark_mode, title: S.dark,
            selected: _themeMode == ThemeMode.dark,
            onTap: () => _setTheme(ThemeMode.dark),
          ),
          const SizedBox(height: 4),
          _ThemeTile(icon: Icons.settings_brightness, title: S.followSystem,
            selected: _themeMode == ThemeMode.system,
            onTap: () => _setTheme(ThemeMode.system),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(S.about),
          const SizedBox(height: 8),
          _buildAboutCard(),
        ],
      ),
    );
  }

  Widget _buildAboutCard() {
    return AppCard(
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
                Text(S.appTitle, style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
                Text(S.appVersion, style: TextStyle(color: AppColors.textTertiary, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _setTheme(ThemeMode mode) async {
    await StorageService.setThemeMode(mode);
    themeNotifier.value = mode;
    if (!mounted) return;
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
