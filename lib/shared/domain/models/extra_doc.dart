// Dokumen tambahan buku: はじめに (intro), Cara Penggunaan Efektif (howto), まとめ (matome).
// File: assets/<book>/extras/<id>.json. FILE INI DISEDIAKAN LENGKAP. JANGAN DIUBAH.

import 'json_utils.dart';
import 'lesson.dart';

class ExtraSection {
  const ExtraSection({required this.id, required this.title, required this.blocks});
  final String id;
  final String title;
  final List<ContentBlock> blocks;
  factory ExtraSection.fromJson(JsonMap j) => ExtraSection(
        id: j['id'] as String,
        title: j['title'] as String,
        blocks: parseList(j['blocks'], ContentBlock.fromJson),
      );
}

class ExtraDoc {
  const ExtraDoc({required this.id, required this.title, required this.sections});
  final String id;
  final String title;
  final List<ExtraSection> sections;
  factory ExtraDoc.fromJson(JsonMap j) => ExtraDoc(
        id: j['id'] as String,
        title: j['title'] as String,
        sections: parseList(j['sections'], ExtraSection.fromJson),
      );
}
