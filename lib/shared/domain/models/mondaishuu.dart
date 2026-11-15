// Model set Mondaishuu (assets/<book>/mondaishuu/MSxx.json).
// FILE INI DISEDIAKAN LENGKAP. JANGAN DIUBAH.

import 'jp_text.dart';
import 'json_utils.dart';

/// Jenis tempat kosong:
/// - text     : isian singkat (dikoreksi otomatis)
/// - sentence : kalimat (dikoreksi otomatis; bila salah ada tombol "Anggap benar")
/// - choice   : pilih salah satu dari [choicesJp] (dikoreksi otomatis)
/// - option   : pilih huruf dari daftar opsi latihan (a, b, c, ...)
/// - free     : jawaban pribadi; tidak dikoreksi, hanya tampil contoh dari buku
enum BlankType {
  text,
  sentence,
  choice,
  option,
  free;

  bool get autoGraded => this != free;
}

class MsBlank {
  const MsBlank({required this.type, this.answersJp = const [], this.choicesJp = const [], this.answer});
  final BlankType type;
  final List<JpText> answersJp; // semua jawaban yang diterima (kunci 解答)
  final List<JpText> choicesJp;
  final String? answer; // untuk type option: huruf kunci
  factory MsBlank.fromJson(JsonMap j) => MsBlank(
        type: BlankType.values.byName(j['type'] as String),
        answersJp: JpText.list(j['answers_jp']),
        choicesJp: JpText.list(j['choices_jp']),
        answer: j['answer'] as String?,
      );
}

class MsLines {
  const MsLines({this.linesJp = const [], this.blanks = const []});
  final List<JpText> linesJp;
  final List<MsBlank> blanks;
  factory MsLines.fromJson(JsonMap j) => MsLines(
        linesJp: JpText.list(j['lines_jp']),
        blanks: parseList(j['blanks'], MsBlank.fromJson),
      );
}

class MsOption {
  const MsOption({required this.key, required this.jp, this.usedByExample = false});
  final String key;
  final JpText jp;
  final bool usedByExample; // dicoret di buku karena dipakai contoh
  factory MsOption.fromJson(JsonMap j) => MsOption(
        key: j['key'] as String,
        jp: JpText.fromJson(j['jp'] as JsonMap),
        usedByExample: (j['used_by_example'] as bool?) ?? false,
      );
}

class MsItem {
  const MsItem({required this.id, required this.no, this.image, required this.linesJp, required this.blanks});
  final String id; // "MS01.6.3"
  final int no;
  final String? image;
  final List<JpText> linesJp; // token blank berurutan sesuai [blanks]
  final List<MsBlank> blanks;
  factory MsItem.fromJson(JsonMap j) => MsItem(
        id: j['id'] as String,
        no: j['no'] as int,
        image: j['image'] as String?,
        linesJp: JpText.list(j['lines_jp']),
        blanks: parseList(j['blanks'], MsBlank.fromJson),
      );
  bool get autoGraded => blanks.every((b) => b.type.autoGraded);
}

class MsExercise {
  const MsExercise({
    required this.id,
    required this.no,
    this.points,
    this.instructionJp,
    this.image,
    this.options = const [],
    this.example,
    required this.items,
  });
  final String id; // "MS01.6"
  final int no;
  final int? points; // poin per soal (hanya di 復習)
  final JpText? instructionJp;
  final String? image;
  final List<MsOption> options;
  final MsLines? example; // tampil dengan jawaban terisi
  final List<MsItem> items;
  factory MsExercise.fromJson(JsonMap j) => MsExercise(
        id: j['id'] as String,
        no: j['no'] as int,
        points: j['points'] as int?,
        instructionJp: JpText.maybe(j['instruction_jp']),
        image: j['image'] as String?,
        options: parseList(j['options'], MsOption.fromJson),
        example: j['example'] == null ? null : MsLines.fromJson(j['example'] as JsonMap),
        items: parseList(j['items'], MsItem.fromJson),
      );
}

class MondaishuuSet {
  const MondaishuuSet({required this.id, required this.kind, required this.lessons, required this.titleJp, required this.exercises});
  final String id; // "MS01"
  final String kind; // "lesson" | "review" | "fukushuu" | "matome"
  final List<int> lessons;
  final JpText titleJp;
  final List<MsExercise> exercises;
  factory MondaishuuSet.fromJson(JsonMap j) => MondaishuuSet(
        id: j['id'] as String,
        kind: (j['kind'] as String?) ?? 'lesson',
        lessons: parseIntList(j['lessons']),
        titleJp: JpText.fromJson(j['title_jp'] as JsonMap),
        exercises: parseList(j['exercises'], MsExercise.fromJson),
      );
}

class MondaishuuMeta {
  const MondaishuuMeta({
    required this.id,
    required this.file,
    required this.lessons,
    required this.titleJp,
    required this.kind,
    required this.exerciseCount,
    required this.itemCount,
  });
  final String id;
  final String file;
  final List<int> lessons;
  final JpText titleJp;
  final String kind;
  final int exerciseCount;
  final int itemCount;
  factory MondaishuuMeta.fromJson(JsonMap j) => MondaishuuMeta(
        id: j['id'] as String,
        file: j['file'] as String,
        lessons: parseIntList(j['lessons']),
        titleJp: JpText.fromJson(j['title_jp'] as JsonMap),
        kind: j['kind'] as String,
        exerciseCount: j['exercise_count'] as int,
        itemCount: j['item_count'] as int,
      );
}
