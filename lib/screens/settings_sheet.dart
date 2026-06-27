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

import '../utils/responsive_values.dart';
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
            padding: EdgeInsets.symmetric(horizontal: R.dialogPadding(context).left, vertical: R.smallSpacing(context)),
            child: Row(
              children: [
                Text(S.settings, style: TextStyle(color: AppColors.textPrimary, fontSize: R.titleFontSize(context), fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const Divider(),
          _buildModeSection(),
          _buildThemeSection(),
          _buildAboutSection(),
          SizedBox(height: R.mediumSpacing(context)),
        ],
      ),
    );
  }

  Widget _buildDragHandle() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: R.spacing(context)),
      width: 36, height: 4,
      decoration: BoxDecoration(
        color: AppColors.textTertiary,
        borderRadius: BorderRadius.circular(AppColors.kChipBorderRadius),
      ),
    );
  }

  Widget _buildModeSection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: R.dialogPadding(context).left, vertical: R.smallSpacing(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(S.runMode),
          SizedBox(height: R.smallSpacing(context)),
          _ModeTile(
            icon: Icons.public,
            title: S.webviewMode,
            subtitle: S.webviewDesc,
            selected: _mode == AppMode.webview,
            onTap: () => _switchMode(context, AppMode.webview),
          ),
          SizedBox(height: R.smallSpacing(context) / 2),
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
      padding: EdgeInsets.symmetric(horizontal: R.dialogPadding(context).left, vertical: R.smallSpacing(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(S.theme),
          SizedBox(height: R.smallSpacing(context)),
          _ThemeTile(icon: Icons.light_mode, title: S.light,
            selected: _themeMode == ThemeMode.light,
            onTap: () => _setTheme(ThemeMode.light),
          ),
          SizedBox(height: R.smallSpacing(context) / 2),
          _ThemeTile(icon: Icons.dark_mode, title: S.dark,
            selected: _themeMode == ThemeMode.dark,
            onTap: () => _setTheme(ThemeMode.dark),
          ),
          SizedBox(height: R.smallSpacing(context) / 2),
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
      padding: EdgeInsets.symmetric(horizontal: R.dialogPadding(context).left, vertical: R.smallSpacing(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(S.about),
          SizedBox(height: R.smallSpacing(context)),
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
            padding: EdgeInsets.all(R.smallSpacing(context)),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(AppColors.kSmallBorderRadius),
            ),
            child: Icon(Icons.code, color: AppColors.primary, size: R.iconSize(context)),
          ),
          SizedBox(width: R.spacing(context)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(S.appTitle, style: TextStyle(color: AppColors.textPrimary, fontSize: R.bodyFontSize(context), fontWeight: FontWeight.w500)),
                Text(S.appVersion, style: TextStyle(color: AppColors.textTertiary, fontSize: R.smallFontSize(context))),
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
      padding: EdgeInsets.only(bottom: R.smallSpacing(context)),
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
      padding: EdgeInsets.only(bottom: R.smallSpacing(context)),
      child: AppSelectableTile(
        icon: icon,
        title: title,
        selected: selected,
        onTap: onTap,
      ),
    );
  }
}
