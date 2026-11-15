// Menyimpan data pengguna saat aplikasi ke latar belakang. FILE INI DISEDIAKAN LENGKAP. JANGAN DIUBAH.

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/progress_service/domain/providers/user_data_provider.dart';

class LifecycleObserver extends WidgetsBindingObserver {
  LifecycleObserver(this.container);
  final ProviderContainer container;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      container.read(userDataProvider.notifier).flush();
    }
  }
}
