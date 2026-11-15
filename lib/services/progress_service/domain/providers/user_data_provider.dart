// State data pengguna + semua aksi yang mengubahnya (docs/06_Algoritma.md §4).
// FILE INI DISEDIAKAN LENGKAP. JANGAN DIUBAH.

import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/domain/models/models.dart';
import '../../../../shared/utils/srs.dart';
import '../../data/datasource/user_data_file.dart';

final userDataFileProvider = Provider<UserDataFile>((ref) => UserDataFile('user_data.json'));

/// Di-override di main dengan hasil UserDataFile.load().
final initialUserDataProvider = Provider<UserData>((ref) => const UserData());

class UserDataNotifier extends Notifier<UserData> {
  Timer? _debounce;

  @override
  UserData build() {
    ref.onDispose(() => _debounce?.cancel());
    return ref.read(initialUserDataProvider);
  }

  void _set(UserData d) {
    state = d;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () => ref.read(userDataFileProvider).save(state));
  }

  /// Simpan segera (dipanggil saat aplikasi ke latar belakang).
  Future<void> flush() async {
    _debounce?.cancel();
    await ref.read(userDataFileProvider).save(state);
  }

  // ---------------------------------------------------------------- navigasi
  void setLastOpened(String route, String label) =>
      _set(state.copyWith(lastOpened: LastOpened(route: route, label: label, at: DateTime.now())));

  // ---------------------------------------------------------------- selesai
  bool isDone(String ref) => state.done.contains(ref);

  void setDone(String ref, bool done) {
    final s = {...state.done};
    done ? s.add(ref) : s.remove(ref);
    _set(state.copyWith(done: s));
  }

  void setManyDone(Iterable<String> refs, bool done) {
    final s = {...state.done};
    done ? s.addAll(refs) : s.removeAll(refs);
    _set(state.copyWith(done: s));
  }

  // ---------------------------------------------------------------- jawaban
  String? answer(String key) => state.answers[key];

  void setAnswer(String key, String value) {
    final m = {...state.answers};
    value.isEmpty ? m.remove(key) : m[key] = value;
    _set(state.copyWith(answers: m));
  }

  /// Hapus semua jawaban yang kuncinya diawali [prefix] (mis. "L01.mondai.1." atau "MS01.6.").
  void clearAnswers(String prefix) {
    final m = {...state.answers}..removeWhere((k, _) => k.startsWith(prefix));
    _set(state.copyWith(answers: m));
  }

  // ---------------------------------------------------------------- Mondaishuu
  /// Catat satu percobaan latihan. [items] = status tiap soal; skor = jumlah correct.
  void recordMsAttempt(String exerciseId, Map<String, ItemStatus> items) {
    final score = items.values.where((v) => v == ItemStatus.correct).length;
    final old = state.msScores[exerciseId];
    final m = {...state.msScores};
    m[exerciseId] = MsScore(
      best: old == null || score > old.best ? score : old.best,
      last: score,
      total: items.length,
      attempts: (old?.attempts ?? 0) + 1,
      items: items,
    );
    _set(state.copyWith(msScores: m));
  }

  // ---------------------------------------------------------------- SRS
  SrsCard cardOf(String key) => state.srs[key] ?? newCard();

  void srsReview(String key, SrsGrade grade) {
    final m = {...state.srs};
    m[key] = review(cardOf(key), grade);
    _set(state.copyWith(srs: m));
  }

  void srsReset(Iterable<String> keys) {
    final m = {...state.srs}..removeWhere((k, _) => keys.contains(k));
    _set(state.copyWith(srs: m));
  }

  // ---------------------------------------------------------------- tersimpan
  bool isBookmarked(String ref) => state.bookmarks.any((b) => b.ref == ref);

  void toggleBookmark({required String ref, required String kind, required String label}) {
    final l = [...state.bookmarks];
    final i = l.indexWhere((b) => b.ref == ref);
    if (i >= 0) {
      l.removeAt(i);
    } else {
      l.insert(0, Bookmark(ref: ref, kind: kind, label: label, at: DateTime.now()));
    }
    _set(state.copyWith(bookmarks: l));
  }

  void setBookmarkNote(String ref, String note) {
    final l = [
      for (final b in state.bookmarks)
        b.ref == ref ? Bookmark(ref: b.ref, kind: b.kind, label: b.label, note: note, at: b.at) : b,
    ];
    _set(state.copyWith(bookmarks: l));
  }

  // ---------------------------------------------------------------- tandaan 🚩
  void addFlag(String ref, String text, String note) =>
      _set(state.copyWith(flags: [FlagReport(ref: ref, text: text, note: note, at: DateTime.now()), ...state.flags]));

  void clearFlags() => _set(state.copyWith(flags: const []));

  String exportFlagsJson() => const JsonEncoder.withIndent('  ').convert({
        'app': 'minna_pocket',
        'book': state.book,
        'created_at': DateTime.now().toIso8601String(),
        'flags': state.flags.map((f) => f.toJson()).toList(),
      });

  // ---------------------------------------------------------------- pencarian
  void addSearch(String q) {
    final t = q.trim();
    if (t.isEmpty) return;
    final l = [t, ...state.searchHistory.where((e) => e != t)].take(10).toList();
    _set(state.copyWith(searchHistory: l));
  }

  void clearSearchHistory() => _set(state.copyWith(searchHistory: const []));

  // ---------------------------------------------------------------- onboarding & backup
  void setOnboardingDone() => _set(state.copyWith(onboardingDone: true));

  String exportBackupJson() {
    final now = DateTime.now();
    _set(state.copyWith(lastBackupAt: now));
    return const JsonEncoder.withIndent('  ').convert({
      'app': 'minna_pocket',
      'book': state.book,
      'created_at': now.toIso8601String(),
      'user_data': state.toJson(),
    });
  }

  /// Mengganti seluruh data dengan isi backup. Melempar FormatException jika file tidak valid.
  Future<void> importBackupJson(String raw) async {
    final j = jsonDecode(raw);
    if (j is! Map || j['app'] != 'minna_pocket' || j['user_data'] is! Map) {
      throw const FormatException('Bukan file backup Minna Pocket');
    }
    if (j['book'] != state.book) throw const FormatException('Backup untuk buku lain');
    _debounce?.cancel();
    state = UserData.fromJson((j['user_data'] as Map).cast<String, dynamic>());
    await flush();
  }

  /// Hapus semua progres (Settings → Hapus semua data).
  Future<void> resetAll() async {
    _debounce?.cancel();
    state = UserData(book: state.book);
    await flush();
  }
}

final userDataProvider = NotifierProvider<UserDataNotifier, UserData>(UserDataNotifier.new);
