// Penyimpanan API key terenkripsi. FILE INI DISEDIAKAN LENGKAP. JANGAN DIUBAH.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../shared/domain/providers/settings_provider.dart';

class AiKeyStore {
  const AiKeyStore(this._s);
  final FlutterSecureStorage _s;
  String _k(AiProvider p) => 'ai_key_${p.name}';
  Future<String?> read(AiProvider p) => _s.read(key: _k(p));
  Future<void> write(AiProvider p, String key) => _s.write(key: _k(p), value: key.trim());
  Future<void> delete(AiProvider p) => _s.delete(key: _k(p));
}

final aiKeyStoreProvider = Provider<AiKeyStore>((ref) => const AiKeyStore(FlutterSecureStorage()));

/// true jika penyedia yang dipilih di Settings sudah punya API key → tombol ✨ ditampilkan.
final aiEnabledProvider = FutureProvider<bool>((ref) async {
  final p = ref.watch(settingsProvider.select((s) => s.aiProvider));
  ref.watch(aiKeyVersionProvider);
  final k = await ref.watch(aiKeyStoreProvider).read(p);
  return k != null && k.isNotEmpty;
});

/// Dinaikkan setiap kali key disimpan/dihapus agar [aiEnabledProvider] dihitung ulang.
class AiKeyVersion extends Notifier<int> {
  @override
  int build() => 0;
  void bump() => state++;
}

final aiKeyVersionProvider = NotifierProvider<AiKeyVersion, int>(AiKeyVersion.new);
