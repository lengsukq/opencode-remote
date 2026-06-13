import 'package:flutter/material.dart';
import 'services/storage_service.dart';
import 'screens/launcher_screen.dart';
import 'screens/webview_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final entry = await StorageService.getLastSelected();
  runApp(OpenCodeRemote(initialEntry: entry));
}

class OpenCodeRemote extends StatelessWidget {
  final dynamic initialEntry;

  const OpenCodeRemote({super.key, this.initialEntry});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OpenCode Remote',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0D1117),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF6366F1),
          surface: Color(0xFF161B22),
        ),
      ),
      home: initialEntry != null
          ? WebViewScreen(entry: initialEntry)
          : const LauncherScreen(),
    );
  }
}
