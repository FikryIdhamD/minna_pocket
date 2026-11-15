// Cache jawaban AI di <dokumen aplikasi>/ai_cache.json. FILE INI DISEDIAKAN LENGKAP. JANGAN DIUBAH.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

class AiCache {
  Map<String, dynamic>? _data;

  Future<File> _file() async => File('${(await getApplicationDocumentsDirectory()).path}/ai_cache.json');

  Future<Map<String, dynamic>> _load() async {
    if (_data != null) return _data!;
    try {
      final f = await _file();
      _data = await f.exists() ? (jsonDecode(await f.readAsString()) as Map<String, dynamic>) : {};
    } catch (_) {
      _data = {};
    }
    return _data!;
  }

  Future<String?> get(String key) async => ((await _load())[key] as Map?)?['text'] as String?;

  Future<void> put(String key, String provider, String model, String text) async {
    final d = await _load();
    d[key] = {'provider': provider, 'model': model, 'at': DateTime.now().toIso8601String(), 'text': text};
    await (await _file()).writeAsString(jsonEncode(d));
  }

  Future<void> clear() async {
    _data = {};
    final f = await _file();
    if (await f.exists()) await f.delete();
  }
}

final aiCacheProvider = Provider<AiCache>((ref) => AiCache());
