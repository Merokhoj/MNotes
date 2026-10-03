import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'theme/app_theme.dart';
import 'providers/settings_provider.dart';
import 'router/app_router.dart';

// Re-export screens for easy reference
export 'screens/onboarding_page.dart';
export 'screens/app_shell_page.dart';

/// Root application widget
class MindSparQApp extends ConsumerWidget {
  const MindSparQApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final router = ref.watch(appRouterProvider);
    
    return MaterialApp.router(
      title: 'MindSparQ Notes',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: settings.themeMode,
      routerConfig: router,
    );
  }
}
