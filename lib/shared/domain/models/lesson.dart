// Model isi satu bab (assets/<book>/lessons/Lxx.json).
// Struktur 1:1 dengan schema/lesson.schema.json.
// FILE INI DISEDIAKAN LENGKAP. JANGAN DIUBAH.

import 'jp_text.dart';
import 'json_utils.dart';

class Lesson {
  const Lesson({
    required this.book,
    required this.lesson,
    required this.id,
    required this.titleJp,
    required this.titleTr,
    required this.sections,
  });
  final int book;
  final int lesson;
  final String id; // "L01"
  final JpText titleJp;
  final String titleTr;
  final LessonSections sections;

  factory Lesson.fromJson(JsonMap j) => Lesson(
        book: j['book'] as int,
        lesson: j['lesson'] as int,
        id: j['id'] as String,
        titleJp: JpText.fromJson(j['title_jp'] as JsonMap),
        titleTr: j['title_tr'] as String,
        sections: LessonSections.fromJson(j['sections'] as JsonMap),
      );
}

class LessonSections {
  const LessonSections({
    this.kosakata,
    this.bunkei = const [],
    this.reibun = const [],
    this.kaiwa,
    this.renshuuA = const [],
    this.renshuuB,
    this.renshuuC = const [],
    this.mondai = const [],
    this.bunpou = const [],
    this.sankou,
  });
  final Kosakata? kosakata;
  final List<Bunkei> bunkei;
  final List<Reibun> reibun;
  final Kaiwa? kaiwa;
  final List<RenshuuA> renshuuA;
  final RenshuuB? renshuuB;
  final List<RenshuuC> renshuuC;
  final List<Mondai> mondai;
  final List<Bunpou> bunpou;
  final Sankou? sankou;

  factory LessonSections.fromJson(JsonMap j) => LessonSections(
        kosakata: j['kosakata'] == null ? null : Kosakata.fromJson(j['kosakata'] as JsonMap),
        bunkei: parseList(j['bunkei'], Bunkei.fromJson),
        reibun: parseList(j['reibun'], Reibun.fromJson),
        kaiwa: j['kaiwa'] == null ? null : Kaiwa.fromJson(j['kaiwa'] as JsonMap),
        renshuuA: parseList(j['renshuu_a'], RenshuuA.fromJson),
        renshuuB: j['renshuu_b'] == null ? null : RenshuuB.fromJson(j['renshuu_b'] as JsonMap),
        renshuuC: parseList(j['renshuu_c'], RenshuuC.fromJson),
        mondai: parseList(j['mondai'], Mondai.fromJson),
        bunpou: parseList(j['bunpou'], Bunpou.fromJson),
        sankou: j['sankou'] == null ? null : Sankou.fromJson(j['sankou'] as JsonMap),
      );
}

// ---------------------------------------------------------------- Kosa Kata
class Kosakata {
  const Kosakata(this.groups);
  final List<KosakataGroup> groups;
  factory Kosakata.fromJson(JsonMap j) => Kosakata(parseList(j['groups'], KosakataGroup.fromJson));
  List<KosakataItem> get allItems => [for (final g in groups) ...g.items];
}

class KosakataGroup {
  const KosakataGroup({this.labelJp, this.separator = false, required this.items});
  final JpText? labelJp;
  final bool separator; // garis putus-putus di buku (tanpa label)
  final List<KosakataItem> items;
  factory KosakataGroup.fromJson(JsonMap j) => KosakataGroup(
        labelJp: JpText.maybe(j['label_jp']),
        separator: (j['separator'] as bool?) ?? false,
        items: parseList(j['items'], KosakataItem.fromJson),
      );
}

class KosakataItem {
  const KosakataItem({required this.id, required this.kanaJp, this.kanjiJp, required this.tr});
  final String id;
  final JpText kanaJp;
  final JpText? kanjiJp;
  final String tr;
  factory KosakataItem.fromJson(JsonMap j) => KosakataItem(
        id: j['id'] as String,
        kanaJp: JpText.fromJson(j['kana_jp'] as JsonMap),
        kanjiJp: JpText.maybe(j['kanji_jp']),
        tr: j['tr'] as String,
      );
}

// ---------------------------------------------------------------- Bunkei / Reibun
class Bunkei {
  const Bunkei({required this.id, required this.no, required this.jp, this.variantsJp = const [], required this.tr});
  final String id;
  final int no;
  final JpText jp;
  final List<JpText> variantsJp; // teks kecil di bawah kalimat, mis. "（では）"
  final String tr;
  factory Bunkei.fromJson(JsonMap j) => Bunkei(
        id: j['id'] as String,
        no: j['no'] as int,
        jp: JpText.fromJson(j['jp'] as JsonMap),
        variantsJp: JpText.list(j['variants_jp']),
        tr: j['tr'] as String,
      );
}

/// Baris kalimat + terjemahan (Reibun, contoh Tata Bahasa).
class TrLine {
  const TrLine({this.id, required this.jp, this.tr, this.variantsJp = const [], this.speakerJp, this.speakerTr});
  final String? id;
  final JpText jp;
  final String? tr;
  final List<JpText> variantsJp;
  final JpText? speakerJp;
  final String? speakerTr;
  factory TrLine.fromJson(JsonMap j) => TrLine(
        id: j['id'] as String?,
        jp: JpText.fromJson(j['jp'] as JsonMap),
        tr: j['tr'] as String?,
        variantsJp: JpText.list(j['variants_jp']),
        speakerJp: JpText.maybe(j['speaker_jp']),
        speakerTr: j['speaker_tr'] as String?,
      );
}

class Reibun {
  const Reibun({required this.id, required this.no, required this.lines});
  final String id;
  final int no;
  final List<TrLine> lines;
  factory Reibun.fromJson(JsonMap j) => Reibun(
        id: j['id'] as String,
        no: j['no'] as int,
        lines: parseList(j['lines'], TrLine.fromJson),
      );
}

// ---------------------------------------------------------------- Kaiwa
class DialogLine {
  const DialogLine({
    this.id,
    this.speakerJp,
    this.speakerTr,
    required this.turnStart,
    this.breakBefore = false,
    required this.jp,
    this.tr,
    this.t,
  });
  final String? id;
  final JpText? speakerJp;
  final String? speakerTr;

  /// true = baris pertama giliran bicara (nama pembicara ditampilkan).
  final bool turnStart;

  /// true = garis pemisah adegan (titik-titik) sebelum baris ini.
  final bool breakBefore;
  final JpText jp;
  final String? tr;
  final TimeRange? t;
  factory DialogLine.fromJson(JsonMap j) => DialogLine(
        id: j['id'] as String?,
        speakerJp: JpText.maybe(j['speaker_jp']),
        speakerTr: j['speaker_tr'] as String?,
        turnStart: j['turn_start'] as bool,
        breakBefore: (j['break_before'] as bool?) ?? false,
        jp: JpText.fromJson(j['jp'] as JsonMap),
        tr: j['tr'] as String?,
        t: TimeRange.maybe(j['t']),
      );
}

class Kaiwa {
  const Kaiwa({
    required this.id,
    required this.titleJp,
    required this.titleTr,
    required this.image,
    required this.audio,
    this.cdTrack,
    this.duration,
    this.timing,
    required this.lines,
  });
  final String id;
  final JpText titleJp;
  final String titleTr;
  final String image; // relatif terhadap assets/<book>/
  final String audio; // relatif terhadap assets/<book>/
  final String? cdTrack;
  final double? duration;
  final String? timing; // "auto" | "manual"
  final List<DialogLine> lines;
  factory Kaiwa.fromJson(JsonMap j) => Kaiwa(
        id: j['id'] as String,
        titleJp: JpText.fromJson(j['title_jp'] as JsonMap),
        titleTr: j['title_tr'] as String,
        image: j['image'] as String,
        audio: j['audio'] as String,
        cdTrack: j['cd_track'] as String?,
        duration: parseDouble(j['duration']),
        timing: j['timing'] as String?,
        lines: parseList(j['lines'], DialogLine.fromJson),
      );
}

// ---------------------------------------------------------------- Renshuu A
enum BoxHighlight { normal, strong, none }

class ABox {
  const ABox({required this.opts, this.hl = BoxHighlight.normal});
  final List<JpText> opts;
  final BoxHighlight hl;
  factory ABox.fromJson(JsonMap j) => ABox(
        opts: JpText.list(j['opts_jp']),
        hl: switch (j['hl'] as String?) {
          'strong' => BoxHighlight.strong,
          'none' => BoxHighlight.none,
          _ => BoxHighlight.normal,
        },
      );
}

/// Satu segmen baris tabel substitusi: teks tetap ATAU slot berisi kotak.
class ASegment {
  const ASegment({this.textJp, this.variantsJp = const [], this.slot});
  final JpText? textJp;
  final List<JpText> variantsJp;
  final List<ABox>? slot;
  bool get isSlot => slot != null;
  factory ASegment.fromJson(JsonMap j) => ASegment(
        textJp: JpText.maybe(j['text_jp']),
        variantsJp: JpText.list(j['variants_jp']),
        slot: j['slot'] == null ? null : parseList(j['slot'], ABox.fromJson),
      );
}

class RenshuuA {
  const RenshuuA({required this.id, required this.no, required this.lines});
  final String id;
  final int no;
  final List<List<ASegment>> lines;
  factory RenshuuA.fromJson(JsonMap j) => RenshuuA(
        id: j['id'] as String,
        no: j['no'] as int,
        lines: (j['lines'] as List)
            .map((l) => parseList(l, ASegment.fromJson))
            .toList(growable: false),
      );
}

// ---------------------------------------------------------------- Renshuu B
class Figure {
  const Figure({required this.id, required this.image});
  final String id;
  final String image;
  factory Figure.fromJson(JsonMap j) => Figure(id: j['id'] as String, image: j['image'] as String);
}

class BExample {
  const BExample({this.promptJp, required this.answerJp});
  final JpText? promptJp;
  final List<JpText> answerJp;
  factory BExample.fromJson(JsonMap j) => BExample(
        promptJp: JpText.maybe(j['prompt_jp']),
        answerJp: JpText.list(j['answer_jp']),
      );
}

class BQuestion {
  const BQuestion({required this.id, required this.no, this.promptJp, this.image});
  final String id;
  final int no;
  final JpText? promptJp; // null = soal mengacu ke gambar (figure)
  final String? image;
  factory BQuestion.fromJson(JsonMap j) => BQuestion(
        id: j['id'] as String,
        no: j['no'] as int,
        promptJp: JpText.maybe(j['prompt_jp']),
        image: j['image'] as String?,
      );
}

class RenshuuBItem {
  const RenshuuBItem({
    required this.id,
    required this.no,
    this.figure,
    this.instructionJp,
    required this.examples,
    required this.questions,
  });
  final String id;
  final int no;
  final String? figure; // id Figure
  final JpText? instructionJp;
  final List<BExample> examples;
  final List<BQuestion> questions;
  factory RenshuuBItem.fromJson(JsonMap j) => RenshuuBItem(
        id: j['id'] as String,
        no: j['no'] as int,
        figure: j['figure'] as String?,
        instructionJp: JpText.maybe(j['instruction_jp']),
        examples: parseList(j['examples'], BExample.fromJson),
        questions: parseList(j['questions'], BQuestion.fromJson),
      );
}

class RenshuuB {
  const RenshuuB({required this.figures, required this.items});
  final List<Figure> figures;
  final List<RenshuuBItem> items;
  factory RenshuuB.fromJson(JsonMap j) => RenshuuB(
        figures: parseList(j['figures'], Figure.fromJson),
        items: parseList(j['items'], RenshuuBItem.fromJson),
      );
  Figure? figureOf(RenshuuBItem item) {
    for (final f in figures) {
      if (f.id == item.figure) return f;
    }
    return null;
  }
}

// ---------------------------------------------------------------- Renshuu C
class Substitution {
  const Substitution({required this.no, this.image, this.optsJp = const []});
  final int no;
  final String? image;
  final List<JpText> optsJp; // jika pengganti berupa teks (bukan gambar)
  factory Substitution.fromJson(JsonMap j) => Substitution(
        no: j['no'] as int,
        image: j['image'] as String?,
        optsJp: JpText.list(j['opts_jp']),
      );
}

class RenshuuC {
  const RenshuuC({required this.id, required this.no, this.image, required this.dialog, required this.substitutions});
  final String id;
  final int no;
  final String? image;
  final List<DialogLine> dialog;
  final List<Substitution> substitutions;
  factory RenshuuC.fromJson(JsonMap j) => RenshuuC(
        id: j['id'] as String,
        no: j['no'] as int,
        image: j['image'] as String?,
        dialog: parseList(j['dialog'], DialogLine.fromJson),
        substitutions: parseList(j['substitutions'], Substitution.fromJson),
      );
}

// ---------------------------------------------------------------- Mondai
enum MondaiKind {
  listenWrite,
  listenChoiceImage,
  listenTrueFalse,
  listenChoice,
  fill,
  compose,
  choice,
  write,
  trueFalse; // bacaan + ○/× per soal (bukan soal dengar)

  static MondaiKind parse(String s) => switch (s) {
        'listen_write' => MondaiKind.listenWrite,
        'listen_choice_image' => MondaiKind.listenChoiceImage,
        'listen_truefalse' => MondaiKind.listenTrueFalse,
        'listen_choice' => MondaiKind.listenChoice,
        'fill' => MondaiKind.fill,
        'compose' => MondaiKind.compose,
        'choice' => MondaiKind.choice,
        'truefalse' => MondaiKind.trueFalse,
        _ => MondaiKind.write,
      };

  bool get isListening =>
      this == listenWrite || this == listenChoiceImage || this == listenTrueFalse || this == listenChoice;
}

class AudioSegment {
  const AudioSegment({required this.label, required this.t});
  final String label; // "例", "例1", "1", "2", ...
  final TimeRange t;
  factory AudioSegment.fromJson(JsonMap j) =>
      AudioSegment(label: j['label'] as String, t: TimeRange.maybe(j['t'])!);
}

class MondaiExample {
  const MondaiExample({required this.labelJp, this.linesJp = const [], this.image, this.options, this.answer});
  final JpText labelJp;
  final List<JpText> linesJp;
  final String? image;
  final int? options; // jumlah pilihan gambar (①②③)
  final String? answer; // "2" untuk pilihan ②, "○"/"×" untuk benar-salah
  factory MondaiExample.fromJson(JsonMap j) => MondaiExample(
        labelJp: JpText.fromJson(j['label_jp'] as JsonMap),
        linesJp: JpText.list(j['lines_jp']),
        image: j['image'] as String?,
        options: j['options'] as int?,
        answer: j['answer'] as String?,
      );
}

class MondaiQuestion {
  const MondaiQuestion({
    required this.id,
    this.no,
    this.linesJp = const [],
    this.image,
    this.options,
    this.choicesJp = const [],
    this.choiceGroupsJp = const [],
  });
  final String id;
  final int? no; // null = soal tunggal tanpa nomor
  final List<JpText> linesJp; // token blank = tempat isian
  final String? image;
  final int? options;
  final List<JpText> choicesJp;

  /// Beberapa kelompok pilihan dalam satu soal (mis. (それ・その・そこ) … (わたし・わたしは・わたしの)).
  final List<List<JpText>> choiceGroupsJp;

  /// Semua kelompok pilihan: [choiceGroupsJp] bila ada, selain itu [choicesJp] sebagai satu kelompok.
  List<List<JpText>> get choiceGroups =>
      choiceGroupsJp.isNotEmpty ? choiceGroupsJp : (choicesJp.isEmpty ? const [] : [choicesJp]);
  factory MondaiQuestion.fromJson(JsonMap j) => MondaiQuestion(
        id: j['id'] as String,
        no: j['no'] as int?,
        linesJp: JpText.list(j['lines_jp']),
        image: j['image'] as String?,
        options: j['options'] as int?,
        choicesJp: JpText.list(j['choices_jp']),
        choiceGroupsJp: j['choice_groups_jp'] == null
            ? const []
            : (j['choice_groups_jp'] as List).map(JpText.list).toList(growable: false),
      );
  int get blankCount => linesJp.fold(0, (n, l) => n + l.tokens.where((t) => t.blank).length);
}

class Mondai {
  const Mondai({
    required this.id,
    required this.no,
    required this.kind,
    this.instructionJp,
    this.audio,
    this.cdTrack,
    this.duration,
    this.image,
    this.passageTitleJp,
    this.passageJp = const [],
    this.segments = const [],
    required this.examples,
    required this.questions,
  });
  final String id;
  final int no;
  final MondaiKind kind;
  final JpText? instructionJp;
  final String? audio;
  final String? cdTrack;
  final double? duration;
  final String? image; // gambar untuk seluruh nomor (ditampilkan di atas soal)
  final JpText? passageTitleJp; // judul bacaan (kind truefalse)
  final List<JpText> passageJp; // paragraf bacaan (kind truefalse)
  final List<AudioSegment> segments; // urutan: semua contoh, lalu semua soal
  final List<MondaiExample> examples;
  final List<MondaiQuestion> questions;
  factory Mondai.fromJson(JsonMap j) => Mondai(
        id: j['id'] as String,
        no: j['no'] as int,
        kind: MondaiKind.parse(j['kind'] as String),
        instructionJp: JpText.maybe(j['instruction_jp']),
        audio: j['audio'] as String?,
        cdTrack: j['cd_track'] as String?,
        duration: parseDouble(j['duration']),
        image: j['image'] as String?,
        passageTitleJp: JpText.maybe(j['passage_title_jp']),
        passageJp: JpText.list(j['passage_jp']),
        segments: parseList(j['segments'], AudioSegment.fromJson),
        examples: parseList(j['examples'], MondaiExample.fromJson),
        questions: parseList(j['questions'], MondaiQuestion.fromJson),
      );

  /// Segmen audio milik contoh ke-[i].
  AudioSegment? exampleSegment(int i) => i < segments.length ? segments[i] : null;

  /// Segmen audio milik soal ke-[i] (indeks dalam [questions]).
  AudioSegment? questionSegment(int i) {
    final k = examples.length + i;
    return k < segments.length ? segments[k] : null;
  }
}

// ---------------------------------------------------------------- Bunpou / Sankou
class CellItem {
  const CellItem({this.jp, this.tr});
  final JpText? jp;
  final String? tr;
  factory CellItem.fromJson(JsonMap j) => CellItem(jp: JpText.maybe(j['jp']), tr: j['tr'] as String?);
}

class TableCell {
  const TableCell(this.items);
  final List<CellItem> items;
  factory TableCell.fromJson(dynamic v) => TableCell(parseList(v, CellItem.fromJson));
}

enum BlockType { h, p, note, ex, table, image }

class ContentBlock {
  const ContentBlock({
    required this.type,
    this.textRich,
    this.mark,
    this.lines = const [],
    this.header = const [],
    this.rows = const [],
    this.image,
    this.caption,
  });
  final BlockType type;
  final JpText? textRich;
  final String? mark; // "①", "②", ...
  final List<TrLine> lines;
  final List<TableCell> header;
  final List<List<TableCell>> rows;
  final String? image;
  final String? caption;
  factory ContentBlock.fromJson(JsonMap j) => ContentBlock(
        type: BlockType.values.byName(j['type'] as String),
        textRich: JpText.maybe(j['text_rich']),
        mark: j['mark'] as String?,
        lines: parseList(j['lines'], TrLine.fromJson),
        header: j['header'] == null
            ? const []
            : (j['header'] as List).map(TableCell.fromJson).toList(growable: false),
        rows: j['rows'] == null
            ? const []
            : (j['rows'] as List)
                .map((r) => (r as List).map(TableCell.fromJson).toList(growable: false))
                .toList(growable: false),
        image: j['image'] as String?,
        caption: j['caption'] as String?,
      );
}

class Bunpou {
  const Bunpou({required this.id, required this.no, required this.titleRich, this.titleNote, required this.blocks});
  final String id;
  final int no;
  final JpText titleRich;
  final String? titleNote;
  final List<ContentBlock> blocks;
  factory Bunpou.fromJson(JsonMap j) => Bunpou(
        id: j['id'] as String,
        no: j['no'] as int,
        titleRich: JpText.fromJson(j['title_rich'] as JsonMap),
        titleNote: j['title_note'] as String?,
        blocks: parseList(j['blocks'], ContentBlock.fromJson),
      );
}

class Sankou {
  const Sankou({required this.id, required this.titleJp, required this.titleTr, required this.blocks});
  final String id;
  final JpText titleJp;
  final String titleTr;
  final List<ContentBlock> blocks;
  factory Sankou.fromJson(JsonMap j) => Sankou(
        id: j['id'] as String,
        titleJp: JpText.fromJson(j['title_jp'] as JsonMap),
        titleTr: j['title_tr'] as String,
        blocks: parseList(j['blocks'], ContentBlock.fromJson),
      );
}
