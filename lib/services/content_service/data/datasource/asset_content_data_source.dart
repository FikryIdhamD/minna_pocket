// Membaca JSON konten dari assets. FILE INI DISEDIAKAN LENGKAP. JANGAN DIUBAH.

import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../../../../main/app_env.dart';

class AssetContentDataSource {
  const AssetContentDataSource(this.env);
  final AppEnv env;

  Future<dynamic> readJson(String relativePath) async {
    final raw = await rootBundle.loadString(env.asset(relativePath));
    return jsonDecode(raw);
  }
}
