import 'package:flutter/material.dart';
import 'models.dart';
import 'theme.dart';
import 'services/storage_service.dart';
import 'screens/onboarding_screen.dart';
import 'screens/launcher_screen.dart';
import 'screens/webview_screen.dart';
import 'widgets/main_scaffold.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:opencode_remote/src/platform/webview_platform.dart';

final themeNotifier = ValueNotifier<ThemeMode>(ThemeMode.system);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    setupWebViewPlatform();
  }

  await StorageService.migrateToSecureStorage();
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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OpenCode Remote',
      debugShowCheckedModeBanner: false,
      theme: IOSTheme.light,
      darkTheme: IOSTheme.dark,
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
        return MainScaffold(entry: widget.initialEntry!);
      case AppMode.webview:
        return WebViewScreen(entry: widget.initialEntry!);
    }
  }
}
