# 04 — Design System

> Semua token sudah ditulis sebagai kode di `lib/shared/theme/` dan **tidak boleh diubah**. Dokumen ini menjelaskan cara memakainya.
> Referensi visual: `docs/mockups/01_beranda_bab_kaiwa.html` dan `docs/mockups/02_mondai.html` (buka di browser).

## 1. Prinsip
1. **Konten buku adalah pusat.** Dekorasi minimal: tanpa gradien, tanpa bayangan tebal, tanpa emoji di UI (kecuali ✨ untuk AI dan label tertentu yang tertulis di `S`).
2. **Satu layar, satu tujuan, satu aksi utama** (tombol merah terisi). Aksi lain memakai tombol garis (outlined) atau teks.
3. **Warna punya arti tetap** (§2). Jangan memakai warna di luar token.
4. **Platform: Android / Material 3.** Tombol kembali ←, bottom navigation bar, bottom sheet. Tanpa pola iOS.

## 2. Warna — `context.palette.<token>` (`app_colors.dart`)
| Token | Arti / dipakai untuk |
|---|---|
| `bg` | latar semua layar (krem kertas) |
| `surface` | kartu, daftar, kotak isian |
| `surfaceAlt` | latar sekunder: nav bar, baris 復習, header tabel, skeleton |
| `border` | garis 1 dp untuk kartu, pemisah daftar |
| `ink` / `inkMuted` / `inkSubtle` | teks utama / sekunder / tersier & ikon nonaktif |
| `primary` | aksi utama, angka bab, progres; tile bagian **buku utama** memakai `primarySubtle` + `primaryStrong` |
| `secondary` | konten **buku terjemahan**: terjemahan, tile Kosa Kata/Tata Bahasa/Referensi, label AI |
| `highlight` / `highlightBg` | kanji ditekan / baris Kaiwa atau soal yang sedang diputar |
| `audio` | tombol play, segmen audio aktif, label durasi audio (`audioSubtle` + ink) |
| `success` / `danger` | koreksi benar / salah |
| `player`, `onPlayer`, `onPlayerMuted` | pemutar audio (gelap di kedua tema) |
| `imageBg` | latar gambar scan (selalu putih, juga di mode gelap) |

## 3. Tipografi — `AppText` (`text_theme.dart`)
| Gaya | Font | Pakai untuk |
|---|---|---|
| `display` 28 | Plus Jakarta Sans | judul besar halaman (jarang) |
| `title` 20 | PJS | judul layar hub (Latihan, Hafalan) |
| `headline` 17 | PJS | judul app bar, judul kartu |
| `bodyStrong` 15 / `body` 15 / `bodySm` 13 | PJS | teks UI |
| `caption` 12, `overline` 12 (UPPERCASE) | PJS | meta, label grup |
| `jp(scale)` 18, `jpTitle` 22, `jpSm` 14 | Noto Sans JP | teks Jepang (lewat `JpTextView`) |
| `brushHero` 44, `brushCard` 72, `brushNo` 26, `brushTile` 20 | Klee One | 第N課, kanji kartu hafalan, nomor bab, tile huruf |

Teks Jepang dari buku **selalu** ditampilkan dengan `JpTextView` (interaktif) atau `JpLabel` (statis). Jangan memakai `Text(jp.jp)` untuk konten utama.

## 4. Jarak & ukuran — `Sp`, `Radii`, `Sizes` (`app_spacing.dart`)
- **Margin layar 16** (`Sp.screen`). Jarak di dalam grup 4–12; antar grup 16–24; antar bagian 24–32.
- **Radius**: kartu `Radii.lg` (16), tombol & kotak `Radii.md` (12), isian `Radii.sm` (8), chip `Radii.full`.
- **Target sentuh minimum 48.** Baris daftar minimal 60. Lebar konten maksimum 640 (tablet: di tengah).
- **Bayangan** hanya pada pemutar mengambang (MiniPlayer). Elemen lain memakai `border`.

## 5. Ikon — `AppIcon(AppIcons.x)`
Set Lucide (SVG di `assets/icons/`). Ukuran 24 (default), 18–20 di dalam tombol kecil. Hanya nama yang ada di `AppIcons` yang boleh dipakai.

## 6. Komponen jadi (WAJIB dipakai, jangan dibuat ulang)
| Komponen | File | Fungsi |
|---|---|---|
| `JpTextView` / `JpLabel` | `shared/widgets/jp_text_view.dart` | teks Jepang: kanji-tap furigana, mode romaji, blank |
| `ModeToggle` | `mode_toggle.dart` | tombol あ \| Ro |
| `SectionScaffold`, `DoneFooter`, `NumberNavBar` | `section_scaffold.dart` | kerangka layar konten bab, auto-selesai, navigasi nomor |
| `ContentBlocksView`, `TableBlockView`, `showGrammarSheet` | `content_blocks.dart` | blok Tata Bahasa/Referensi, panel 📖 |
| `MiniPlayer`, `SegmentPlayer`, `SegmentPlayButton`, `SpeedChip`, `showAudioSettingsSheet` | `audio_widgets.dart` | semua UI audio |
| `showJpActions`, `JpExtraAction`, `showFlagDialog` | `jp_actions.dart` | menu tekan-lama |
| `showAiPanel` | `features/ai_assist/presentation/widgets/ai_panel.dart` | panel ✨ |
| `KanaTextField`, `FieldState` | `kana_text_field.dart` | isian dengan konversi romaji→kana |
| `BookImage` | `book_image.dart` | gambar scan |
| `ProgressRing` | `progress_ring.dart` | lingkaran progres |
| `AsyncView`, `SkeletonList`, `ErrorView` | `async_view.dart` | loading/error |
| `AppIcon`, `AppIcons` | `app_icon.dart` | ikon |

### 6.1 Pola komponen yang dibuat di layar (gunakan persis)
- **Kartu daftar** = `Container(decoration: BoxDecoration(color: palette.surface, borderRadius: Radii.lgAll, border: Border.all(color: palette.border)))`, berisi baris-baris dipisah `Divider(height: 1)`.
- **Baris daftar** = `InkWell` → `Padding(horizontal 12–16)` → `Row`: leading (tile 40×40 radius 10 / angka Klee), `Expanded(Column(judul, subjudul))`, trailing (chevron / centang / badge). Tinggi minimal 60.
- **Tile huruf bagian**: 40×40, radius 10, teks `AppText.brushTile`. Buku utama: latar `primarySubtle`, teks `primaryStrong`. Buku terjemahan: latar `secondarySubtle`, teks `secondary`.
- **Label grup**: `AppText.overline`, `inkMuted`, UPPERCASE, padding kiri 4, jarak bawah 8.
- **Kartu contoh (例)**: latar `secondarySubtle`, radius `Radii.md`, padding 12. Label "例" di kotak kecil `surface` radius 6 (`AppText.bodyStrong`, warna `secondary`).
- **Badge audio**: `Container` radius full, latar `audioSubtle`, padding h8 v2, ikon headphones 14 + teks `caption` (warna ink).
- **Badge status kecil** ("Sedang", "Ulangan"): radius full, padding h8 v2, `caption`. "Sedang" = `primarySubtle`/`primaryStrong`; "Ulangan" = `secondarySubtle`/`secondary`.
- **Tombol utama penuh**: `SizedBox(width: double.infinity, child: FilledButton(...))`.

## 7. Mode gelap
Otomatis lewat `AppPalette.dark`. Gambar scan tetap di atas `imageBg` putih (`BookImage`). Jangan mewarnai ulang gambar.

## 8. Logo & ikon aplikasi
- `assets/logo/app_icon_book1_1024.png` (preview), `assets/logo/android_res_book1/**` (sudah dalam ukuran mipmap Android + adaptive icon).
- `assets/logo/logo_256.png` dipakai di header Beranda (36×36, radius 10).
- Konsep: の merah (Klee One) di kotak krem, pita hitam tipis, titik kuning. Versi II menambahkan "II".
