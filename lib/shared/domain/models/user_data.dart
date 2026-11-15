// Data milik pengguna, disimpan di <dokumen aplikasi>/user_data.json.
// Lihat docs/03_Spesifikasi_Data.md §6. FILE INI DISEDIAKAN LENGKAP. JANGAN DIUBAH.

import 'json_utils.dart';

const kUserDataVersion = 1;

class LastOpened {
  const LastOpened({required this.route, required this.label, required this.at});
  final String route; // path go_router, mis. "/lesson/1/kaiwa"
  final String label; // teks tombol Lanjutkan, mis. "Bab 1 · Kaiwa"
  final DateTime at;
  factory LastOpened.fromJson(JsonMap j) =>
      LastOpened(route: j['route'] as String, label: j['label'] as String, at: DateTime.parse(j['at'] as String));
  JsonMap toJson() => {'route': route, 'label': label, 'at': at.toIso8601String()};
}

/// Status satu soal Mondaishuu pada percobaan terakhir.
enum ItemStatus { correct, wrong, assisted }

class MsScore {
  const MsScore({required this.best, required this.last, required this.total, required this.attempts, this.items = const {}});
  final int best;
  final int last;
  final int total;
  final int attempts;
  final Map<String, ItemStatus> items; // itemId -> status terakhir
  factory MsScore.fromJson(JsonMap j) => MsScore(
        best: j['best'] as int,
        last: j['last'] as int,
        total: j['total'] as int,
        attempts: j['attempts'] as int,
        items: ((j['items'] as Map?) ?? const {})
            .map((k, v) => MapEntry(k as String, ItemStatus.values.byName(v as String))),
      );
  JsonMap toJson() => {
        'best': best,
        'last': last,
        'total': total,
        'attempts': attempts,
        'items': items.map((k, v) => MapEntry(k, v.name)),
      };
}

/// Kartu spaced repetition (lihat docs/06_Algoritma.md §1).
class SrsCard {
  const SrsCard({required this.due, this.interval = 0, this.ease = 2.5, this.reps = 0, this.lapses = 0});
  final DateTime due; // tanggal jatuh tempo (jam diabaikan)
  final int interval; // hari
  final double ease;
  final int reps;
  final int lapses;
  factory SrsCard.fromJson(JsonMap j) => SrsCard(
        due: DateTime.parse(j['due'] as String),
        interval: j['interval'] as int,
        ease: (j['ease'] as num).toDouble(),
        reps: j['reps'] as int,
        lapses: j['lapses'] as int,
      );
  JsonMap toJson() => {
        'due': due.toIso8601String().substring(0, 10),
        'interval': interval,
        'ease': ease,
        'reps': reps,
        'lapses': lapses,
      };
}

class Bookmark {
  const Bookmark({required this.ref, required this.kind, required this.label, this.note = '', required this.at});
  final String ref; // ID item, mis. "L05.bunpou.2"
  final String kind; // "kalimat" | "kosakata" | "tata_bahasa" | "latihan" | "mondaishuu"
  final String label; // teks pendek untuk daftar
  final String note;
  final DateTime at;
  factory Bookmark.fromJson(JsonMap j) => Bookmark(
        ref: j['ref'] as String,
        kind: j['kind'] as String,
        label: j['label'] as String,
        note: (j['note'] as String?) ?? '',
        at: DateTime.parse(j['at'] as String),
      );
  JsonMap toJson() => {'ref': ref, 'kind': kind, 'label': label, 'note': note, 'at': at.toIso8601String()};
}

class FlagReport {
  const FlagReport({required this.ref, required this.text, this.note = '', required this.at});
  final String ref;
  final String text; // teks yang ditandai (salinan)
  final String note;
  final DateTime at;
  factory FlagReport.fromJson(JsonMap j) => FlagReport(
        ref: j['ref'] as String,
        text: j['text'] as String,
        note: (j['note'] as String?) ?? '',
        at: DateTime.parse(j['at'] as String),
      );
  JsonMap toJson() => {'ref': ref, 'text': text, 'note': note, 'at': at.toIso8601String()};
}

class UserData {
  const UserData({
    this.version = kUserDataVersion,
    this.book = 1,
    this.lastOpened,
    this.done = const {},
    this.msScores = const {},
    this.answers = const {},
    this.srs = const {},
    this.bookmarks = const [],
    this.flags = const [],
    this.searchHistory = const [],
    this.onboardingDone = false,
    this.lastBackupAt,
  });

  final int version;
  final int book;
  final LastOpened? lastOpened;

  /// Ref yang sudah selesai, mis. "L01.kaiwa", "L01.renshuu_b.4", "L01.bunpou.2".
  final Set<String> done;

  /// Skor Mondaishuu per latihan, kunci = id latihan "MS01.6".
  final Map<String, MsScore> msScores;

  /// Jawaban yang diketik pengguna (Mondai buku utama & Mondaishuu terakhir).
  /// Kunci = "<idSoal>#<indeksBlank>", mis. "L01.mondai.1.3#0".
  final Map<String, String> answers;

  /// Kartu SRS, kunci = "hira:あ" | "kata:ア" | "kanji:会社員".
  final Map<String, SrsCard> srs;
  final List<Bookmark> bookmarks;
  final List<FlagReport> flags;
  final List<String> searchHistory; // maks 10, terbaru di depan
  final bool onboardingDone;
  final DateTime? lastBackupAt;

  factory UserData.fromJson(JsonMap j) => UserData(
        version: (j['version'] as int?) ?? kUserDataVersion,
        book: (j['book'] as int?) ?? 1,
        lastOpened: j['last_opened'] == null ? null : LastOpened.fromJson(j['last_opened'] as JsonMap),
        done: ((j['done'] as List?) ?? const []).cast<String>().toSet(),
        msScores: ((j['ms_scores'] as Map?) ?? const {})
            .map((k, v) => MapEntry(k as String, MsScore.fromJson(v as JsonMap))),
        answers: ((j['answers'] as Map?) ?? const {}).map((k, v) => MapEntry(k as String, v as String)),
        srs: ((j['srs'] as Map?) ?? const {}).map((k, v) => MapEntry(k as String, SrsCard.fromJson(v as JsonMap))),
        bookmarks: parseList(j['bookmarks'], Bookmark.fromJson),
        flags: parseList(j['flags'], FlagReport.fromJson),
        searchHistory: ((j['search_history'] as List?) ?? const []).cast<String>(),
        onboardingDone: (j['onboarding_done'] as bool?) ?? false,
        lastBackupAt: j['last_backup_at'] == null ? null : DateTime.parse(j['last_backup_at'] as String),
      );

  JsonMap toJson() => {
        'version': version,
        'book': book,
        'last_opened': lastOpened?.toJson(),
        'done': done.toList()..sort(),
        'ms_scores': msScores.map((k, v) => MapEntry(k, v.toJson())),
        'answers': answers,
        'srs': srs.map((k, v) => MapEntry(k, v.toJson())),
        'bookmarks': bookmarks.map((b) => b.toJson()).toList(),
        'flags': flags.map((f) => f.toJson()).toList(),
        'search_history': searchHistory,
        'onboarding_done': onboardingDone,
        'last_backup_at': lastBackupAt?.toIso8601String(),
      };

  UserData copyWith({
    LastOpened? lastOpened,
    Set<String>? done,
    Map<String, MsScore>? msScores,
    Map<String, String>? answers,
    Map<String, SrsCard>? srs,
    List<Bookmark>? bookmarks,
    List<FlagReport>? flags,
    List<String>? searchHistory,
    bool? onboardingDone,
    DateTime? lastBackupAt,
  }) =>
      UserData(
        version: version,
        book: book,
        lastOpened: lastOpened ?? this.lastOpened,
        done: done ?? this.done,
        msScores: msScores ?? this.msScores,
        answers: answers ?? this.answers,
        srs: srs ?? this.srs,
        bookmarks: bookmarks ?? this.bookmarks,
        flags: flags ?? this.flags,
        searchHistory: searchHistory ?? this.searchHistory,
        onboardingDone: onboardingDone ?? this.onboardingDone,
        lastBackupAt: lastBackupAt ?? this.lastBackupAt,
      );
}
