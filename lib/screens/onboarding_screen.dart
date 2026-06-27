import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import '../models.dart';
import '../strings.dart';
import '../theme.dart';
import '../services/storage_service.dart';
import '../screens/launcher_screen.dart';

import '../utils/responsive_values.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.surfaceAlt, AppColors.avatarBg],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: R.largeSpacing(context)),
              child: _buildModeSelectionCard(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModeSelectionCard(BuildContext context) {
    return Container(
      padding: R.dialogPadding(context),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(R.borderRadius(context) * 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(R.borderRadius(context) * 2),
        child: BackdropFilter(
          filter: _blurFilter(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: R.mediumSpacing(context)),
              _buildHeader(context),
              SizedBox(height: R.largeSpacing(context)),
              _buildWebViewMode(context),
              SizedBox(height: R.spacing(context)),
              _buildNativeMode(context),
              SizedBox(height: R.mediumSpacing(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(R.mediumSpacing(context)),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(R.borderRadius(context)),
          ),
          child: Icon(Icons.code, color: AppColors.primary, size: R.iconSize(context) * 2),
        ),
        SizedBox(height: R.mediumSpacing(context)),
        Text(
          'OpenCode Remote',
          style: TextStyle(
            fontSize: R.titleFontSize(context) * 1.5,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: R.smallSpacing(context)),
        Text(
          S.chooseMode,
          style: TextStyle(
            fontSize: R.bodyFontSize(context),
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildWebViewMode(BuildContext context) {
    return _ModeOption(
      icon: Icons.public,
      title: S.webviewMode,
      subtitle: S.webviewDesc,
      onTap: () => _selectMode(context, AppMode.webview),
    );
  }

  Widget _buildNativeMode(BuildContext context) {
    return _ModeOption(
      icon: Icons.phone_android,
      title: S.nativeMode,
      subtitle: S.nativeDesc,
      onTap: () => _selectMode(context, AppMode.native),
    );
  }

  Future<void> _selectMode(BuildContext context, AppMode mode) async {
    await StorageService.setAppMode(mode);
    await StorageService.setHasLaunched();
    if (!context.mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => LauncherScreen(initialMode: mode)),
    );
  }
}

class _ModeOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ModeOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: R.cardPadding(context),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(R.borderRadius(context)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(R.spacing(context)),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(R.borderRadius(context)),
              ),
              child: Icon(icon, color: AppColors.primary, size: R.iconSize(context)),
            ),
            SizedBox(width: R.spacing(context)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: R.subtitleFontSize(context),
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: R.smallSpacing(context) / 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: R.smallFontSize(context), color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}

ImageFilter _blurFilter() => ImageFilter.blur(sigmaX: 30, sigmaY: 30);
