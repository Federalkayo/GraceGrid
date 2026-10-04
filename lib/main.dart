import 'package:flutter/material.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import 'ui/core/theme/app_theme.dart';
import 'ui/features/main_navigation/main_navigation_view.dart';
import 'ui/features/auth/auth_notifier.dart';
import 'data/services/local_storage_service.dart';
import 'data/services/bible_data_service.dart';
import 'data/services/hive_service.dart';
import 'data/services/supabase_service.dart';
import 'data/services/stream_chat_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize all services in parallel where possible.
  // Supabase must init before AuthNotifier is created.
  final storage = LocalStorageService();
  await Future.wait([
    storage.init(),
    BibleDataService.initialize(),
    HiveService.init(),
    SupabaseService.init(),
  ]);

  // Initialize Stream Chat client (non-blocking)
  StreamChatService.instance.init();

  final savedThemeMode = await storage.getThemeMode();

  runApp(GraceGridApp(initialThemeMode: savedThemeMode));
}

class GraceGridApp extends StatefulWidget {
  final String? initialThemeMode;

  const GraceGridApp({super.key, required this.initialThemeMode});

  @override
  State<GraceGridApp> createState() => _GraceGridAppState();
}

class _GraceGridAppState extends State<GraceGridApp> {
  late ThemeMode _themeMode;
  late AuthNotifier _authNotifier;

  @override
  void initState() {
    super.initState();
    if (widget.initialThemeMode == 'light') {
      _themeMode = ThemeMode.light;
    } else if (widget.initialThemeMode == 'dark') {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.system;
    }
    _authNotifier = AuthNotifier();
  }

  @override
  void dispose() {
    _authNotifier.dispose();
    super.dispose();
  }

  void _toggleTheme() {
    setState(() {
      final isCurrentlyDark = _themeMode == ThemeMode.dark ||
          (_themeMode == ThemeMode.system &&
              View.of(context).platformDispatcher.platformBrightness == Brightness.dark);
      _themeMode = isCurrentlyDark ? ThemeMode.light : ThemeMode.dark;
    });
    LocalStorageService().saveThemeMode(_themeMode == ThemeMode.dark ? 'dark' : 'light');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _themeMode == ThemeMode.dark ||
        (_themeMode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);

    return MaterialApp(
      title: 'GraceGrid',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
      builder: (context, child) {
        return StreamChat(
          client: StreamChatService.instance.client,
          child: child!,
        );
      },
      home: MainNavigationView(
        onToggleTheme: _toggleTheme,
        isDarkMode: isDark,
        authNotifier: _authNotifier,
      ),
    );
  }
}
