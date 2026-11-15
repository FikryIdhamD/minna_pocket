// Inisialisasi bersama untuk semua flavor. FILE INI DISEDIAKAN LENGKAP. JANGAN DIUBAH.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/content_service/domain/providers/content_providers.dart';
import '../services/progress_service/data/datasource/user_data_file.dart';
import '../services/progress_service/domain/providers/user_data_provider.dart';
import '../shared/domain/providers/settings_provider.dart';
import 'app.dart';
import 'app_env.dart';
import 'observers.dart';

Future<void> bootstrap(AppEnv env) async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final prefs = await SharedPreferences.getInstance();
  final file = UserDataFile('user_data.json');
  final userData = await file.load();
  final container = ProviderContainer(overrides: [
    appEnvProvider.overrideWithValue(env),
    sharedPreferencesProvider.overrideWithValue(prefs),
    userDataFileProvider.overrideWithValue(file),
    initialUserDataProvider.overrideWithValue(userData),
  ]);
  WidgetsBinding.instance.addObserver(LifecycleObserver(container));
  runApp(UncontrolledProviderScope(container: container, child: const MinnaPocketApp()));
}
