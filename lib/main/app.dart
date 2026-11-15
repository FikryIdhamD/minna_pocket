// Widget akar aplikasi. FILE INI DISEDIAKAN LENGKAP. JANGAN DIUBAH.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../routes/app_route.dart';
import '../services/content_service/domain/providers/content_providers.dart';
import '../shared/domain/providers/settings_provider.dart';
import '../shared/theme/app_theme.dart';

class MinnaPocketApp extends ConsumerWidget {
  const MinnaPocketApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final env = ref.watch(appEnvProvider);
    final themeMode = ref.watch(settingsProvider.select((s) => s.themeMode));
    return MaterialApp.router(
      title: env.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: ref.watch(routerProvider),
    );
  }
}
