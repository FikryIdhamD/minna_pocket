// Baca/tulis <dokumen aplikasi>/user_data.json secara atomik. FILE INI DISEDIAKAN LENGKAP. JANGAN DIUBAH.

import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../../../shared/domain/models/models.dart';

class UserDataFile {
  UserDataFile(this.fileName);
  final String fileName; // 'user_data.json'

  Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$fileName');
  }

  Future<UserData> load() async {
    try {
      final f = await _file();
      if (!await f.exists()) return const UserData();
      return UserData.fromJson(jsonDecode(await f.readAsString()) as JsonMap);
    } catch (_) {
      // File rusak: simpan salinannya lalu mulai dari kosong.
      try {
        final f = await _file();
        if (await f.exists()) await f.copy('${f.path}.corrupt');
      } catch (_) {}
      return const UserData();
    }
  }

  Future<void> save(UserData data) async {
    final f = await _file();
    final tmp = File('${f.path}.tmp');
    await tmp.writeAsString(jsonEncode(data.toJson()), flush: true);
    await tmp.rename(f.path);
  }
}
