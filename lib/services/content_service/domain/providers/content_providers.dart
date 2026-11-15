// Provider konten (Riverpod). FILE INI DISEDIAKAN LENGKAP. JANGAN DIUBAH.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../main/app_env.dart';
import '../../../../shared/domain/models/models.dart';
import '../../data/datasource/asset_content_data_source.dart';
import '../../data/repositories/content_repository_impl.dart';
import '../repositories/content_repository.dart';

/// Di-override di main_bookN.dart.
final appEnvProvider = Provider<AppEnv>((ref) => AppEnv.book1);

final contentRepositoryProvider = Provider<ContentRepository>(
  (ref) => ContentRepositoryImpl(AssetContentDataSource(ref.watch(appEnvProvider))),
);

final manifestProvider = FutureProvider<BookManifest>((ref) => ref.watch(contentRepositoryProvider).manifest());

final lessonProvider = FutureProvider.family<Lesson, int>((ref, no) => ref.watch(contentRepositoryProvider).lesson(no));

final mondaishuuProvider =
    FutureProvider.family<MondaishuuSet, String>((ref, id) => ref.watch(contentRepositoryProvider).mondaishuu(id));

final kanjiIndexProvider = FutureProvider<List<KanjiEntry>>((ref) => ref.watch(contentRepositoryProvider).kanjiIndex());

final searchIndexProvider = FutureProvider<List<SearchEntry>>((ref) => ref.watch(contentRepositoryProvider).searchIndex());

final kanaChartProvider = FutureProvider<KanaChart>((ref) => ref.watch(contentRepositoryProvider).kanaChart());

final extraDocProvider = FutureProvider.family<ExtraDoc, String>((ref, id) => ref.watch(contentRepositoryProvider).extraDoc(id));
