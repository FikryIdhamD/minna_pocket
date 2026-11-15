// Semua rute aplikasi (go_router). FILE INI DISEDIAKAN LENGKAP. JANGAN DIUBAH.
// Setiap layar adalah kelas di features/<fitur>/presentation/screens/ (lihat docs/05_Spesifikasi_Layar.md).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/ai_assist/presentation/screens/ai_settings_screen.dart';
import '../features/book_extras/presentation/screens/intro_screen.dart';
import '../features/bookmarks/presentation/screens/bookmarks_screen.dart';
import '../features/bunkei_reibun/presentation/screens/bunkei_screen.dart';
import '../features/bunkei_reibun/presentation/screens/reibun_screen.dart';
import '../features/bunpou/presentation/screens/bunpou_screen.dart';
import '../features/hafalan/presentation/screens/flashcard_screen.dart';
import '../features/hafalan/presentation/screens/hafalan_hub_screen.dart';
import '../features/hafalan/presentation/screens/kana_table_screen.dart';
import '../features/hafalan/presentation/screens/quiz_screen.dart';
import '../features/hafalan/presentation/screens/review_screen.dart';
import '../features/home/presentation/screens/home_screen.dart';
import '../features/home/presentation/screens/home_shell.dart';
import '../features/home/presentation/screens/more_screen.dart';
import '../features/kaiwa/presentation/screens/kaiwa_screen.dart';
import '../features/kosakata/presentation/screens/kosakata_screen.dart';
import '../features/kosakata/presentation/screens/sankou_screen.dart';
import '../features/lesson/presentation/screens/lesson_screen.dart';
import '../features/lesson/presentation/screens/number_picker_screen.dart';
import '../features/mondai/presentation/screens/mondai_screen.dart';
import '../features/mondaishuu/presentation/screens/mondaishuu_exercise_screen.dart';
import '../features/mondaishuu/presentation/screens/mondaishuu_result_screen.dart';
import '../features/mondaishuu/presentation/screens/mondaishuu_set_screen.dart';
import '../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../features/practice_mix/presentation/screens/mix_session_screen.dart';
import '../features/practice_mix/presentation/screens/mix_setup_screen.dart';
import '../features/practice_mix/presentation/screens/practice_hub_screen.dart';
import '../features/renshuu/presentation/screens/renshuu_a_screen.dart';
import '../features/renshuu/presentation/screens/renshuu_b_screen.dart';
import '../features/renshuu/presentation/screens/renshuu_c_screen.dart';
import '../features/search/presentation/screens/search_screen.dart';
import '../features/settings/presentation/screens/flags_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';
import '../services/progress_service/domain/providers/user_data_provider.dart';

int _int(GoRouterState s, String k) => int.parse(s.pathParameters[k]!);

final routerProvider = Provider<GoRouter>((ref) {
  final onboarded = ref.read(userDataProvider).onboardingDone;
  return GoRouter(
    initialLocation: onboarded ? '/' : '/onboarding',
    routes: [
      GoRoute(path: '/onboarding', builder: (c, s) => const OnboardingScreen()),
      StatefulShellRoute.indexedStack(
        builder: (c, s, shell) => HomeShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: '/', builder: (c, s) => const HomeScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/practice', builder: (c, s) => const PracticeHubScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/hafalan', builder: (c, s) => const HafalanHubScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/more', builder: (c, s) => const MoreScreen())]),
        ],
      ),
      // ---- bab
      GoRoute(path: '/intro', builder: (c, s) => const IntroScreen()),
      GoRoute(path: '/lesson/:no', builder: (c, s) => LessonScreen(lesson: _int(s, 'no')), routes: [
        GoRoute(path: 'kosakata', builder: (c, s) => KosakataScreen(lesson: _int(s, 'no'))),
        GoRoute(path: 'bunkei', builder: (c, s) => BunkeiScreen(lesson: _int(s, 'no'))),
        GoRoute(path: 'reibun', builder: (c, s) => ReibunScreen(lesson: _int(s, 'no'))),
        GoRoute(path: 'kaiwa', builder: (c, s) => KaiwaScreen(lesson: _int(s, 'no'))),
        GoRoute(path: 'sankou', builder: (c, s) => SankouScreen(lesson: _int(s, 'no'))),
        GoRoute(
          path: 'p/:section',
          builder: (c, s) => NumberPickerScreen(lesson: _int(s, 'no'), section: s.pathParameters['section']!),
        ),
        GoRoute(path: 'renshuu_a/:n', builder: (c, s) => RenshuuAScreen(lesson: _int(s, 'no'), no: _int(s, 'n'))),
        GoRoute(path: 'renshuu_b/:n', builder: (c, s) => RenshuuBScreen(lesson: _int(s, 'no'), no: _int(s, 'n'))),
        GoRoute(path: 'renshuu_c/:n', builder: (c, s) => RenshuuCScreen(lesson: _int(s, 'no'), no: _int(s, 'n'))),
        GoRoute(path: 'mondai/:n', builder: (c, s) => MondaiScreen(lesson: _int(s, 'no'), no: _int(s, 'n'))),
        GoRoute(path: 'bunpou/:n', builder: (c, s) => BunpouScreen(lesson: _int(s, 'no'), no: _int(s, 'n'))),
      ]),
      // ---- Mondaishuu
      GoRoute(path: '/ms/:id', builder: (c, s) => MondaishuuSetScreen(setId: s.pathParameters['id']!), routes: [
        GoRoute(
          path: 'ex/:ex',
          builder: (c, s) => MondaishuuExerciseScreen(
            setId: s.pathParameters['id']!,
            exNo: _int(s, 'ex'),
            onlyWrong: s.uri.queryParameters['only'] == 'wrong',
          ),
        ),
        GoRoute(path: 'result', builder: (c, s) => MondaishuuResultScreen(setId: s.pathParameters['id']!)),
      ]),
      // ---- Latihan Campuran
      GoRoute(path: '/mix', builder: (c, s) => const MixSetupScreen(), routes: [
        GoRoute(path: 'session', builder: (c, s) => const MixSessionScreen()),
      ]),
      // ---- Hafalan
      GoRoute(path: '/kana/:script', builder: (c, s) => KanaTableScreen(script: s.pathParameters['script']!)),
      GoRoute(path: '/cards/:deck', builder: (c, s) => FlashcardScreen(deck: s.pathParameters['deck']!)),
      GoRoute(path: '/quiz/:deck', builder: (c, s) => QuizScreen(deck: s.pathParameters['deck']!)),
      GoRoute(path: '/review', builder: (c, s) => const ReviewScreen()),
      // ---- lain
      GoRoute(path: '/search', builder: (c, s) => const SearchScreen()),
      GoRoute(path: '/bookmarks', builder: (c, s) => const BookmarksScreen()),
      GoRoute(path: '/settings', builder: (c, s) => const SettingsScreen(), routes: [
        GoRoute(path: 'ai', builder: (c, s) => const AiSettingsScreen()),
        GoRoute(path: 'flags', builder: (c, s) => const FlagsScreen()),
      ]),
    ],
    errorBuilder: (c, s) => Scaffold(appBar: AppBar(), body: const Center(child: Text('Halaman tidak ditemukan'))),
  );
});

/// Rute bab → layar konten, dipakai daftar subtitle & tombol Lanjutkan.
String sectionRoute(int lesson, String section, {int? no}) {
  const direct = {'kosakata', 'bunkei', 'reibun', 'kaiwa', 'sankou'};
  if (direct.contains(section)) return '/lesson/$lesson/$section';
  if (no == null) return '/lesson/$lesson/p/$section';
  return '/lesson/$lesson/$section/$no';
}
