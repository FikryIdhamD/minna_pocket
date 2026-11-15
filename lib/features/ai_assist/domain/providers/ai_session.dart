// State panel ✨ AI (satu percakapan per panel). FILE INI DISEDIAKAN LENGKAP. JANGAN DIUBAH.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/domain/providers/settings_provider.dart';
import '../../data/datasource/ai_cache.dart';
import '../../data/datasource/ai_client.dart';
import '../../data/datasource/ai_key_store.dart';
import '../repositories/ai_prompts.dart';

@immutable
class AiRequest {
  const AiRequest({
    required this.action,
    required this.lesson,
    required this.refId,
    required this.target,
    required this.bookContext,
    this.userAnswer,
    this.keyAnswer,
  });
  final AiAction action;
  final int lesson;
  final String refId; // ID item (untuk kunci cache)
  final String target;
  final String bookContext;
  final String? userAnswer;
  final String? keyAnswer;
  String get cacheKey => '${action.name}|$refId|${userAnswer ?? ''}';
}

@immutable
class AiSessionState {
  const AiSessionState({this.messages = const [], this.streaming = '', this.loading = false, this.error, this.fromCache = false});
  final List<AiMessage> messages; // pesan pertama (user) TIDAK ditampilkan; tampilkan mulai indeks 1
  final String streaming; // teks yang sedang mengalir
  final bool loading;
  final String? error;
  final bool fromCache;
}

class AiSession extends AutoDisposeNotifier<AiSessionState> {
  AiRequest? _req;

  @override
  AiSessionState build() => const AiSessionState();

  Future<void> start(AiRequest req, {bool forceRefresh = false}) async {
    _req = req;
    final prompt = buildUserPrompt(
      action: req.action,
      lesson: req.lesson,
      target: req.target,
      bookContext: req.bookContext,
      userAnswer: req.userAnswer,
      keyAnswer: req.keyAnswer,
    );
    if (!forceRefresh) {
      final cached = await ref.read(aiCacheProvider).get(req.cacheKey);
      if (cached != null) {
        state = AiSessionState(messages: [AiMessage('user', prompt), AiMessage('assistant', cached)], fromCache: true);
        return;
      }
    }
    await _run([AiMessage('user', prompt)], cacheKey: req.cacheKey);
  }

  Future<void> followUp(String text) async {
    if (text.trim().isEmpty || state.loading) return;
    await _run([...state.messages, AiMessage('user', text.trim())]);
  }

  Future<void> refresh() async {
    final r = _req;
    if (r != null) await start(r, forceRefresh: true);
  }

  Future<void> _run(List<AiMessage> msgs, {String? cacheKey}) async {
    state = AiSessionState(messages: msgs, loading: true);
    final s = ref.read(settingsProvider);
    final key = await ref.read(aiKeyStoreProvider).read(s.aiProvider);
    if (key == null || key.isEmpty) {
      state = AiSessionState(messages: msgs, error: 'API key belum diisi. Buka Settings → AI.');
      return;
    }
    final buf = StringBuffer();
    try {
      await for (final chunk in AiClient().stream(
        provider: s.aiProvider,
        model: s.aiModel,
        apiKey: key,
        system: kAiSystemPrompt,
        messages: msgs,
      )) {
        buf.write(chunk);
        state = AiSessionState(messages: msgs, streaming: buf.toString(), loading: true);
      }
      final text = buf.toString().trim();
      state = AiSessionState(messages: [...msgs, AiMessage('assistant', text)]);
      if (cacheKey != null && text.isNotEmpty) {
        final model = s.aiModel.trim().isEmpty ? kDefaultModels[s.aiProvider]! : s.aiModel.trim();
        await ref.read(aiCacheProvider).put(cacheKey, s.aiProvider.name, model, text);
      }
    } on AiException catch (e) {
      state = AiSessionState(messages: msgs, error: e.message);
    } catch (_) {
      state = AiSessionState(messages: msgs, error: 'Terjadi kesalahan. Coba lagi.');
    }
  }
}

/// autoDispose: setiap panel AI yang dibuka memulai sesi baru.
final aiSessionProvider = NotifierProvider.autoDispose<AiSession, AiSessionState>(AiSession.new);
