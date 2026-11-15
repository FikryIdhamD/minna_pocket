// Model manifest.json, kanji_index.json, search_index.json.
// FILE INI DISEDIAKAN LENGKAP. JANGAN DIUBAH.

import 'jp_text.dart';
import 'json_utils.dart';
import 'mondaishuu.dart';

/// Urutan kunci bagian di layar Bab (juga urutan di manifest).
const kSectionOrder = [
  'kosakata', 'bunkei', 'reibun', 'kaiwa',
  'renshuu_a', 'renshuu_b', 'renshuu_c', 'mondai',
  'bunpou', 'sankou',
];

/// Kelompok tampilan di layar Bab.
const kSectionGroups = {
  'materi': ['kosakata', 'bunkei', 'reibun', 'kaiwa'],
  'latihan': ['renshuu_a', 'renshuu_b', 'renshuu_c', 'mondai'],
  'penjelasan': ['bunpou', 'sankou'],
};

/// Bagian yang harus memilih nomor dulu sebelum konten tampil.
const kSectionsWithPicker = {'renshuu_a', 'renshuu_b', 'renshuu_c', 'mondai', 'bunpou'};

class SectionMeta {
  const SectionMeta({
    required this.key,
    required this.source,
    this.count,
    this.numbers = const [],
    this.audioNumbers = const [],
    this.audio,
    this.duration,
    this.titleJp,
    this.titleTr,
  });
  final String key;
  final String source; // "main" | "translation"
  final int? count;
  final List<int> numbers;
  final List<int> audioNumbers;
  final String? audio;
  final double? duration;
  final JpText? titleJp;
  final String? titleTr;
  bool get hasPicker => kSectionsWithPicker.contains(key);
  bool get hasAudio => audio != null || audioNumbers.isNotEmpty;
  factory SectionMeta.fromJson(JsonMap j) => SectionMeta(
        key: j['key'] as String,
        source: j['source'] as String,
        count: j['count'] as int?,
        numbers: parseIntList(j['numbers']),
        audioNumbers: parseIntList(j['audio_numbers']),
        audio: j['audio'] as String?,
        duration: parseDouble(j['duration']),
        titleJp: JpText.maybe(j['title_jp']),
        titleTr: j['title_tr'] as String?,
      );
}

class LessonMeta {
  const LessonMeta({
    required this.lesson,
    required this.id,
    required this.file,
    required this.titleJp,
    required this.titleTr,
    required this.sections,
  });
  final int lesson;
  final String id;
  final String file;
  final JpText titleJp;
  final String titleTr;
  final List<SectionMeta> sections;
  SectionMeta? section(String key) {
    for (final s in sections) {
      if (s.key == key) return s;
    }
    return null;
  }

  factory LessonMeta.fromJson(JsonMap j) => LessonMeta(
        lesson: j['lesson'] as int,
        id: j['id'] as String,
        file: j['file'] as String,
        titleJp: JpText.fromJson(j['title_jp'] as JsonMap),
        titleTr: j['title_tr'] as String,
        sections: parseList(j['sections'], SectionMeta.fromJson),
      );
}

/// Item urutan di daftar Bab: bab biasa, 復習, atau まとめ.
class SequenceItem {
  const SequenceItem({required this.type, this.lesson, this.id, this.titleJp, this.subtitle});
  final String type; // "lesson" | "fukushuu" | "matome"
  final int? lesson;
  final String? id; // untuk fukushuu/matome, mis. "FA", "M1"
  final JpText? titleJp;
  final String? subtitle;
  factory SequenceItem.fromJson(JsonMap j) => SequenceItem(
        type: j['type'] as String,
        lesson: j['lesson'] as int?,
        id: j['id'] as String?,
        titleJp: JpText.maybe(j['title_jp']),
        subtitle: j['subtitle'] as String?,
      );
}

class BookManifest {
  const BookManifest({
    required this.book,
    required this.dataVersion,
    required this.title,
    required this.lessons,
    required this.mondaishuu,
    this.fukushuu = const [],
    required this.sequence,
  });
  final int book;
  final String dataVersion;
  final String title;
  final List<LessonMeta> lessons;
  final List<MondaishuuMeta> mondaishuu;
  /// 復習 A–G, 総復習, まとめ I/II buku utama (format set sama dengan Mondaishuu).
  final List<MondaishuuMeta> fukushuu;
  final List<SequenceItem> sequence;

  /// Meta set menurut id: MSxx / MSRx (mondaishuu) atau FA–FG, FS, M1, M2 (fukushuu).
  MondaishuuMeta? setMeta(String id) {
    for (final m in [...mondaishuu, ...fukushuu]) {
      if (m.id == id) return m;
    }
    return null;
  }

  LessonMeta? lesson(int no) {
    for (final l in lessons) {
      if (l.lesson == no) return l;
    }
    return null;
  }

  factory BookManifest.fromJson(JsonMap j) => BookManifest(
        book: j['book'] as int,
        dataVersion: j['data_version'] as String,
        title: j['title'] as String,
        lessons: parseList(j['lessons'], LessonMeta.fromJson),
        mondaishuu: parseList(j['mondaishuu'], MondaishuuMeta.fromJson),
        fukushuu: parseList(j['fukushuu'], MondaishuuMeta.fromJson),
        sequence: parseList(j['sequence'], SequenceItem.fromJson),
      );
}

class KanjiOccurrence {
  const KanjiOccurrence({required this.lesson, required this.section, required this.ref});
  final int lesson;
  final String section;
  final String ref;
  factory KanjiOccurrence.fromJson(JsonMap j) => KanjiOccurrence(
        lesson: j['lesson'] as int,
        section: j['section'] as String,
        ref: j['ref'] as String,
      );
}

class KanjiEntry {
  const KanjiEntry({
    required this.word,
    required this.readings,
    required this.readingsRo,
    this.meaning,
    required this.firstLesson,
    required this.occurrences,
  });
  final String word;
  final List<String> readings;
  final List<String> readingsRo; // romaji tiap bacaan (urutan sama dengan [readings])
  final String? meaning; // dari Kosa Kata; null jika kata tidak ada di Kosa Kata
  final int firstLesson;
  final List<KanjiOccurrence> occurrences;
  factory KanjiEntry.fromJson(JsonMap j) => KanjiEntry(
        word: j['word'] as String,
        readings: (j['readings'] as List).cast<String>(),
        readingsRo: ((j['readings_ro'] as List?) ?? const []).cast<String>(),
        meaning: j['meaning'] as String?,
        firstLesson: j['first_lesson'] as int,
        occurrences: parseList(j['occurrences'], KanjiOccurrence.fromJson),
      );
}

class SearchEntry {
  const SearchEntry({
    required this.type,
    required this.ref,
    required this.lesson,
    required this.jp,
    required this.kana,
    required this.ro,
    required this.tr,
  });
  final String type; // "kosakata" | "kalimat" | "tata_bahasa" | "referensi"
  final String ref;
  final int lesson;
  final String jp;
  final String kana; // hiragana
  final String ro; // romaji huruf kecil
  final String tr;
  factory SearchEntry.fromJson(JsonMap j) => SearchEntry(
        type: j['type'] as String,
        ref: j['ref'] as String,
        lesson: j['lesson'] as int,
        jp: j['jp'] as String,
        kana: j['kana'] as String,
        ro: j['ro'] as String,
        tr: j['tr'] as String,
      );
}
