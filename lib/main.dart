import 'package:flutter/material.dart';
import 'models.dart';
import 'theme.dart';
import 'services/storage_service.dart';
import 'screens/onboarding_screen.dart';
import 'screens/launcher_screen.dart';
import 'screens/webview_screen.dart';
import 'screens/native/dashboard_screen.dart';

final themeNotifier = ValueNotifier<ThemeMode>(ThemeMode.system);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final hasLaunched = await StorageService.hasLaunched();
  final themeMode = await StorageService.getThemeMode();
  themeNotifier.value = themeMode;
  AppMode? mode;
  ServerEntry? entry;
  if (hasLaunched) {
    mode = await StorageService.getAppMode();
    entry = await StorageService.getLastSelected();
  }
  runApp(OpenCodeRemote(initialMode: mode, initialEntry: entry));
}

class OpenCodeRemote extends StatefulWidget {
  final AppMode? initialMode;
  final ServerEntry? initialEntry;

  const OpenCodeRemote({super.key, this.initialMode, this.initialEntry});

  @override
  State<OpenCodeRemote> createState() => _OpenCodeRemoteState();
}

class _OpenCodeRemoteState extends State<OpenCodeRemote> {
  @override
  void initState() {
    super.initState();
    themeNotifier.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    themeNotifier.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() => setState(() {});

  ThemeData _lightTheme() => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: ColorScheme.light(
      primary: AppColors.primary,
      surface: AppColors.surface,
    ),
    appBarTheme: AppBarTheme(
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
        side: BorderSide(color: AppColors.border),
      ),
    ),
    dividerTheme: DividerThemeData(color: AppColors.border),
    dialogTheme: DialogThemeData(backgroundColor: AppColors.surface),
    bottomSheetTheme: BottomSheetThemeData(backgroundColor: AppColors.surface),
  );

  ThemeData _darkTheme() => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: DarkColors.background,
    colorScheme: ColorScheme.dark(
      primary: DarkColors.primary,
      surface: DarkColors.surface,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: DarkColors.surface,
      foregroundColor: DarkColors.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0.5,
    ),
    cardTheme: CardThemeData(
      color: DarkColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: DarkColors.border),
      ),
    ),
    dividerTheme: DividerThemeData(color: DarkColors.border),
    dialogTheme: DialogThemeData(backgroundColor: DarkColors.surface),
    bottomSheetTheme: BottomSheetThemeData(backgroundColor: DarkColors.surface),
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OpenCode Remote',
      debugShowCheckedModeBanner: false,
      theme: _lightTheme(),
      darkTheme: _darkTheme(),
      themeMode: themeNotifier.value,
      home: _buildHome(),
    );
  }

  Widget _buildHome() {
    if (widget.initialMode == null) {
      return const OnboardingScreen();
    }
    if (widget.initialEntry == null) {
      return LauncherScreen(initialMode: widget.initialMode);
    }
    switch (widget.initialMode!) {
      case AppMode.native:
        return DashboardScreen(entry: widget.initialEntry!);
      case AppMode.webview:
        return WebViewScreen(entry: widget.initialEntry!);
    }
  }
}
