// Implementasi ContentRepository dengan cache memori. FILE INI DISEDIAKAN LENGKAP. JANGAN DIUBAH.

import '../../../../shared/domain/models/models.dart';
import '../../domain/repositories/content_repository.dart';
import '../datasource/asset_content_data_source.dart';

class ContentRepositoryImpl implements ContentRepository {
  ContentRepositoryImpl(this._ds);
  final AssetContentDataSource _ds;

  BookManifest? _manifest;
  final Map<int, Lesson> _lessons = {};
  final Map<String, MondaishuuSet> _ms = {};
  List<KanjiEntry>? _kanji;
  List<SearchEntry>? _search;
  KanaChart? _kana;
  final Map<String, ExtraDoc> _extras = {};

  @override
  Future<BookManifest> manifest() async =>
      _manifest ??= BookManifest.fromJson(await _ds.readJson('manifest.json') as JsonMap);

  @override
  Future<Lesson> lesson(int no) async {
    final cached = _lessons[no];
    if (cached != null) return cached;
    final meta = (await manifest()).lesson(no);
    if (meta == null) throw StateError('Bab $no tidak ada di manifest');
    return _lessons[no] = Lesson.fromJson(await _ds.readJson(meta.file) as JsonMap);
  }

  @override
  Future<MondaishuuSet> mondaishuu(String id) async {
    final cached = _ms[id];
    if (cached != null) return cached;
    final meta = (await manifest()).setMeta(id);
    if (meta == null) throw StateError('Set latihan $id tidak ada di manifest');
    return _ms[id] = MondaishuuSet.fromJson(await _ds.readJson(meta.file) as JsonMap);
  }

  @override
  Future<List<KanjiEntry>> kanjiIndex() async => _kanji ??= parseList(await _ds.readJson('kanji_index.json'), KanjiEntry.fromJson);

  @override
  Future<List<SearchEntry>> searchIndex() async => _search ??= parseList(await _ds.readJson('search_index.json'), SearchEntry.fromJson);

  @override
  Future<KanaChart> kanaChart() async => _kana ??= KanaChart.fromJson(await _ds.readJson('extras/kana.json') as JsonMap);

  @override
  Future<ExtraDoc> extraDoc(String id) async =>
      _extras[id] ??= ExtraDoc.fromJson(await _ds.readJson('extras/$id.json') as JsonMap);
}
