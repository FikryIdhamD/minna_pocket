// Spaced repetition bergaya SM-2 (docs/06_Algoritma.md §1). FILE INI DISEDIAKAN LENGKAP. JANGAN DIUBAH.

import '../domain/models/user_data.dart';

enum SrsGrade { lupa, susah, bisa, mudah }

DateTime today() {
  final n = DateTime.now();
  return DateTime(n.year, n.month, n.day);
}

/// Kartu baru (belum pernah diulas) jatuh tempo hari ini.
SrsCard newCard() => SrsCard(due: today());

/// Hitung kartu berikutnya setelah dinilai.
/// - lupa  : reps=0, lapses+1, interval=0 (muncul lagi di sesi ini), ease-0.20 (min 1.3)
/// - susah : interval = max(1, round(interval*1.2)), ease-0.15
/// - bisa  : reps 0→1 hari, reps 1→3 hari, selanjutnya round(interval*ease)
/// - mudah : seperti bisa, lalu ×1.3 dan ease+0.15
SrsCard review(SrsCard c, SrsGrade g) {
  final t = today();
  switch (g) {
    case SrsGrade.lupa:
      return SrsCard(due: t, interval: 0, ease: (c.ease - 0.20).clamp(1.3, 3.0).toDouble(), reps: 0, lapses: c.lapses + 1);
    case SrsGrade.susah:
      final iv = (c.interval * 1.2).round().clamp(1, 36500).toInt();
      return SrsCard(due: t.add(Duration(days: iv)), interval: iv, ease: (c.ease - 0.15).clamp(1.3, 3.0).toDouble(), reps: c.reps + 1, lapses: c.lapses);
    case SrsGrade.bisa:
    case SrsGrade.mudah:
      int iv;
      if (c.reps == 0) {
        iv = 1;
      } else if (c.reps == 1) {
        iv = 3;
      } else {
        iv = (c.interval * c.ease).round();
      }
      var ease = c.ease;
      if (g == SrsGrade.mudah) {
        iv = (iv * 1.3).round();
        ease = (ease + 0.15).clamp(1.3, 3.0).toDouble();
      }
      iv = iv.clamp(1, 36500).toInt();
      return SrsCard(due: t.add(Duration(days: iv)), interval: iv, ease: ease, reps: c.reps + 1, lapses: c.lapses);
  }
}

bool isDue(SrsCard c) => !c.due.isAfter(today());

/// Kartu "hafal" untuk statistik progres = sudah diulas ≥2 kali dan interval ≥3 hari.
bool isMastered(SrsCard c) => c.reps >= 2 && c.interval >= 3;
