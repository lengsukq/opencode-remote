import 'package:flutter/material.dart';
import 'models.dart';
import 'theme.dart';
import 'services/storage_service.dart';
import 'screens/onboarding_screen.dart';
import 'screens/launcher_screen.dart';
import 'screens/webview_screen.dart';
import 'screens/native/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final hasLaunched = await StorageService.hasLaunched();
  AppMode? mode;
  ServerEntry? entry;
  if (hasLaunched) {
    mode = await StorageService.getAppMode();
    entry = await StorageService.getLastSelected();
  }
  runApp(OpenCodeRemote(initialMode: mode, initialEntry: entry));
}

class OpenCodeRemote extends StatelessWidget {
  final AppMode? initialMode;
  final ServerEntry? initialEntry;

  const OpenCodeRemote({super.key, this.initialMode, this.initialEntry});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OpenCode Remote',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.light(
          primary: AppColors.primary,
          surface: AppColors.surface,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          scrolledUnderElevation: 0.5,
        ),
        cardTheme: CardThemeData(
          color: AppColors.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.border),
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.border,
        ),
      ),
      home: _buildHome(),
    );
  }

  Widget _buildHome() {
    if (initialMode == null) {
      return const OnboardingScreen();
    }
    if (initialEntry == null) {
      return LauncherScreen(initialMode: initialMode);
    }
    switch (initialMode!) {
      case AppMode.native:
        return DashboardScreen(entry: initialEntry!);
      case AppMode.webview:
        return WebViewScreen(entry: initialEntry!);
    }
  }
}
