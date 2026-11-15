// Kontrak akses konten buku. FILE INI DISEDIAKAN LENGKAP. JANGAN DIUBAH.

import '../../../../shared/domain/models/models.dart';

abstract class ContentRepository {
  Future<BookManifest> manifest();
  Future<Lesson> lesson(int no);
  Future<MondaishuuSet> mondaishuu(String id);
  Future<List<KanjiEntry>> kanjiIndex();
  Future<List<SearchEntry>> searchIndex();
  Future<KanaChart> kanaChart();
  Future<ExtraDoc> extraDoc(String id); // 'intro' | 'howto' | 'matome1' ...
}
