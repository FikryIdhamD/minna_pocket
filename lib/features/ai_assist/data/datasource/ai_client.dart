// Klien AI streaming untuk 3 penyedia (docs/07_Fitur_AI.md §3). FILE INI DISEDIAKAN LENGKAP. JANGAN DIUBAH.

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../shared/domain/providers/settings_provider.dart';

class AiMessage {
  const AiMessage(this.role, this.text); // role: 'user' | 'assistant'
  final String role;
  final String text;
}

class AiException implements Exception {
  const AiException(this.message);
  final String message; // pesan siap tampil (Bahasa Indonesia)
  @override
  String toString() => message;
}

/// Model default bila pengguna tidak mengisi nama model. Periksa nama terbaru di situs penyedia.
const kDefaultModels = {
  AiProvider.anthropic: 'claude-haiku-5-5',
  AiProvider.gemini: 'gemini-2.5-flash',
  AiProvider.openai: 'gpt-4.1-mini',
};

const kMaxTokens = 900;

class AiClient {
  AiClient({http.Client? client}) : _http = client ?? http.Client();
  final http.Client _http;

  /// Mengalirkan potongan teks jawaban. Melempar [AiException] untuk semua kegagalan.
  Stream<String> stream({
    required AiProvider provider,
    required String model,
    required String apiKey,
    required String system,
    required List<AiMessage> messages,
  }) async* {
    final m = model.trim().isEmpty ? kDefaultModels[provider]! : model.trim();
    final req = switch (provider) {
      AiProvider.anthropic => _anthropic(m, apiKey, system, messages),
      AiProvider.openai => _openai(m, apiKey, system, messages),
      AiProvider.gemini => _gemini(m, apiKey, system, messages),
    };
    http.StreamedResponse res;
    try {
      res = await _http.send(req).timeout(const Duration(seconds: 30));
    } catch (_) {
      throw const AiException('Tidak bisa terhubung. Periksa koneksi internet.');
    }
    if (res.statusCode != 200) {
      final body = await res.stream.bytesToString();
      throw AiException(_errorMessage(res.statusCode, body));
    }
    final lines = res.stream.transform(utf8.decoder).transform(const LineSplitter());
    await for (final line in lines) {
      if (!line.startsWith('data:')) continue;
      final data = line.substring(5).trim();
      if (data.isEmpty || data == '[DONE]') continue;
      final Map<String, dynamic> j;
      try {
        j = jsonDecode(data) as Map<String, dynamic>;
      } catch (_) {
        continue;
      }
      final t = _extract(provider, j);
      if (t != null && t.isNotEmpty) yield t;
    }
  }

  String? _extract(AiProvider p, Map<String, dynamic> j) {
    switch (p) {
      case AiProvider.anthropic:
        if (j['type'] == 'content_block_delta') {
          final d = j['delta'] as Map<String, dynamic>?;
          return d?['text'] as String?;
        }
        if (j['type'] == 'error') throw AiException('Penyedia AI mengembalikan error: ${(j['error'] as Map?)?['message'] ?? ''}');
        return null;
      case AiProvider.openai:
        final ch = j['choices'] as List?;
        if (ch == null || ch.isEmpty) return null;
        return ((ch.first as Map)['delta'] as Map?)?['content'] as String?;
      case AiProvider.gemini:
        final c = j['candidates'] as List?;
        if (c == null || c.isEmpty) return null;
        final parts = (((c.first as Map)['content'] as Map?)?['parts'] as List?) ?? const [];
        return parts.map((e) => (e as Map)['text'] as String? ?? '').join();
    }
  }

  http.Request _anthropic(String model, String key, String system, List<AiMessage> msgs) =>
      http.Request('POST', Uri.parse('https://api.anthropic.com/v1/messages'))
        ..headers.addAll({'x-api-key': key, 'anthropic-version': '2023-06-01', 'content-type': 'application/json'})
        ..body = jsonEncode({
          'model': model,
          'max_tokens': kMaxTokens,
          'system': system,
          'stream': true,
          'messages': [for (final m in msgs) {'role': m.role, 'content': m.text}],
        });

  http.Request _openai(String model, String key, String system, List<AiMessage> msgs) =>
      http.Request('POST', Uri.parse('https://api.openai.com/v1/chat/completions'))
        ..headers.addAll({'authorization': 'Bearer $key', 'content-type': 'application/json'})
        ..body = jsonEncode({
          'model': model,
          'stream': true,
          'messages': [
            {'role': 'system', 'content': system},
            for (final m in msgs) {'role': m.role, 'content': m.text},
          ],
        });

  http.Request _gemini(String model, String key, String system, List<AiMessage> msgs) => http.Request(
        'POST',
        Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/$model:streamGenerateContent?alt=sse'),
      )
        ..headers.addAll({'x-goog-api-key': key, 'content-type': 'application/json'})
        ..body = jsonEncode({
          'systemInstruction': {
            'parts': [
              {'text': system}
            ]
          },
          'contents': [
            for (final m in msgs)
              {
                'role': m.role == 'assistant' ? 'model' : 'user',
                'parts': [
                  {'text': m.text}
                ]
              }
          ],
          'generationConfig': {'maxOutputTokens': kMaxTokens},
        });

  String _errorMessage(int code, String body) {
    if (code == 401 || code == 403) return 'API key ditolak. Periksa kembali key di Settings → AI.';
    if (code == 404) return 'Nama model tidak ditemukan. Periksa nama model di Settings → AI.';
    if (code == 429) return 'Batas pemakaian/kuota tercapai. Coba lagi nanti.';
    if (code >= 500) return 'Server penyedia AI sedang bermasalah. Coba lagi nanti.';
    return 'Permintaan gagal (kode $code).';
  }
}
