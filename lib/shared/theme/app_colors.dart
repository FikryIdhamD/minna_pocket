// Token warna Minna Pocket (docs/04_Design_System.md §2).
// FILE INI DISEDIAKAN LENGKAP. JANGAN DIUBAH. Jangan menulis warna hex di file lain;
// selalu pakai `context.palette.<token>`.

import 'package:flutter/material.dart';

@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.bg,
    required this.surface,
    required this.surfaceAlt,
    required this.border,
    required this.ink,
    required this.inkMuted,
    required this.inkSubtle,
    required this.primary,
    required this.primaryStrong,
    required this.primarySubtle,
    required this.onPrimary,
    required this.highlight,
    required this.highlightBg,
    required this.secondary,
    required this.secondarySubtle,
    required this.audio,
    required this.audioSubtle,
    required this.onAudio,
    required this.success,
    required this.successSubtle,
    required this.danger,
    required this.dangerSubtle,
    required this.player,
    required this.onPlayer,
    required this.onPlayerMuted,
    required this.imageBg,
  });

  final Color bg; // latar aplikasi (krem kertas)
  final Color surface; // kartu
  final Color surfaceAlt; // latar sekunder, nav bar
  final Color border; // garis 1dp
  final Color ink; // teks utama
  final Color inkMuted; // teks sekunder
  final Color inkSubtle; // teks tersier, ikon non-aktif
  final Color primary; // merah sampul — konten buku utama, aksi utama
  final Color primaryStrong; // merah ditekan / teks merah di atas latar merah muda
  final Color primarySubtle; // latar tile buku utama
  final Color onPrimary;
  final Color highlight; // salem — kanji ditekan
  final Color highlightBg; // latar baris Kaiwa/soal yang diputar
  final Color secondary; // cokelat emas — konten buku terjemahan
  final Color secondarySubtle;
  final Color audio; // kuning CD — tombol play
  final Color audioSubtle;
  final Color onAudio;
  final Color success;
  final Color successSubtle;
  final Color danger;
  final Color dangerSubtle;
  final Color player; // latar pemutar (gelap di kedua tema)
  final Color onPlayer;
  final Color onPlayerMuted;
  final Color imageBg; // latar di belakang gambar scan (selalu putih)

  static const light = AppPalette(
    bg: Color(0xFFFBF8EE),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFF4EFE2),
    border: Color(0xFFE7E1D2),
    ink: Color(0xFF2A272B),
    inkMuted: Color(0xFF6B655F),
    inkSubtle: Color(0xFF8A8580),
    primary: Color(0xFFD82830),
    primaryStrong: Color(0xFFB51F27),
    primarySubtle: Color(0xFFFBE6E4),
    onPrimary: Color(0xFFFFFFFF),
    highlight: Color(0xFFF0B8A8),
    highlightBg: Color(0xFFFBE3DA),
    secondary: Color(0xFF866A49),
    secondarySubtle: Color(0xFFF1E8D8),
    audio: Color(0xFFF2E25C),
    audioSubtle: Color(0xFFFBF6C9),
    onAudio: Color(0xFF2A272B),
    success: Color(0xFF3E7D4F),
    successSubtle: Color(0xFFE3F0E5),
    danger: Color(0xFFB51F27),
    dangerSubtle: Color(0xFFFBE6E4),
    player: Color(0xFF2A272B),
    onPlayer: Color(0xFFFBF8EE),
    onPlayerMuted: Color(0xFFCFC9BD),
    imageBg: Color(0xFFFFFFFF),
  );

  static const dark = AppPalette(
    bg: Color(0xFF1C1A1D),
    surface: Color(0xFF262328),
    surfaceAlt: Color(0xFF211F23),
    border: Color(0xFF3A363B),
    ink: Color(0xFFEDE9E0),
    inkMuted: Color(0xFFB4AEA6),
    inkSubtle: Color(0xFF8F8A84),
    primary: Color(0xFFE5484F),
    primaryStrong: Color(0xFFFF8A8F),
    primarySubtle: Color(0xFF3D2224),
    onPrimary: Color(0xFFFFFFFF),
    highlight: Color(0xFF7A3D33),
    highlightBg: Color(0xFF3B2622),
    secondary: Color(0xFFCFB996),
    secondarySubtle: Color(0xFF3A3226),
    audio: Color(0xFFD9C94A),
    audioSubtle: Color(0xFF3A3618),
    onAudio: Color(0xFF1C1A1D),
    success: Color(0xFF6DB27E),
    successSubtle: Color(0xFF1F3325),
    danger: Color(0xFFFF8A8F),
    dangerSubtle: Color(0xFF3D2224),
    player: Color(0xFF111012),
    onPlayer: Color(0xFFEDE9E0),
    onPlayerMuted: Color(0xFFB4AEA6),
    imageBg: Color(0xFFFFFFFF),
  );

  @override
  AppPalette copyWith() => this;

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) =>
      (other is AppPalette && t >= 0.5) ? other : this;
}

extension PaletteX on BuildContext {
  AppPalette get palette => Theme.of(this).extension<AppPalette>()!;
}
