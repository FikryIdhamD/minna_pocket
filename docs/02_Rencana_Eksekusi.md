# 02 — Rencana Eksekusi

> Dokumen ini dibaca dan dijalankan AI eksekutor **task per task**, bersama `AGENTS.md`.
> Pemilik (manusia) memeriksa di setiap **⛳ Titik cek**.
> Dokumen lain: 01 (rencana), 03 (data), 04 (desain), 05 (layar), 06 (algoritma), 07 (AI), 08 (build), 09 (QA).

---

## 0. Peran & kondisi awal

| Pihak | Tugas |
|---|---|
| **Perencana (Claude)** | Data konten (`assets/`, `content-src/`, `tools/`), kode fondasi (file bertanda `DISEDIAKAN LENGKAP`), semua dokumen |
| **AI eksekutor (Antigravity)** | Proyek Flutter, konfigurasi Android, semua layar, provider fitur yang ditandai [DIBUAT] di 06 |
| **Pemilik** | Menjalankan AI eksekutor, mengecek di ⛳, membuat keystore, memasang APK |

**Sudah tersedia di folder `Minna Pocket/` sebelum T00:**
```
AGENTS.md  pubspec.yaml  .gitignore  .github/workflows/build-apk.yml
android_snippets/               ← potongan konfigurasi Android untuk T03
assets/  fonts/ icons/ logo/ book1/(manifest, lessons, mondaishuu, extras, img, audio, indeks)
content-src/  schema/  tools/   ← milik perencana, JANGAN diubah
docs/                           ← dokumen 01–09, mockups/, LOG_EKSEKUSI.md
lib/                            ← kode fondasi (lihat §1) + folder kosong ber-.gitkeep
test/shared/                    ← tes kode fondasi
```

---

## 1. Peta kode

### 1.1 Sudah jadi — JANGAN diubah
```
lib/main/        app.dart app_env.dart bootstrap.dart main_book1.dart main_book2.dart observers.dart
lib/routes/      app_route.dart
lib/shared/domain/models/      models.dart jp_text.dart json_utils.dart lesson.dart manifest.dart
                               mondaishuu.dart kana.dart extra_doc.dart user_data.dart
lib/shared/domain/providers/   settings_provider.dart
lib/shared/theme/              app_colors.dart app_spacing.dart text_theme.dart app_theme.dart
lib/shared/utils/              strings.dart kana_input.dart answer_checker.dart srs.dart
lib/shared/widgets/            app_icon.dart jp_text_view.dart mode_toggle.dart progress_ring.dart
                               book_image.dart async_view.dart audio_widgets.dart jp_actions.dart
                               section_scaffold.dart content_blocks.dart kana_text_field.dart
lib/services/content_service/  data/datasource/asset_content_data_source.dart
                               data/repositories/content_repository_impl.dart
                               domain/repositories/content_repository.dart
                               domain/providers/content_providers.dart
lib/services/progress_service/ data/datasource/user_data_file.dart
                               domain/providers/user_data_provider.dart  domain/providers/progress_selectors.dart
lib/services/audio_service/    domain/providers/audio_controller.dart
lib/services/tts_service/      domain/providers/tts_service.dart
lib/features/ai_assist/        data/datasource/ai_client.dart ai_key_store.dart ai_cache.dart
                               domain/repositories/ai_prompts.dart  domain/providers/ai_session.dart
                               presentation/widgets/ai_panel.dart
lib/features/home/presentation/screens/home_shell.dart
test/shared/models_test.dart  test/shared/utils_test.dart
```

### 1.2 Dibuat AI eksekutor
Layar dan provider fitur di §3 (Fase 1). Setiap folder kosong punya `.gitkeep`. Saat file pertama dibuat di sebuah folder, **hapus `.gitkeep` di folder itu**.

---

## 2. Fase 0 — Fondasi proyek

### T00 — Cek lingkungan
1. Jalankan `flutter --version` dan `flutter doctor`.
2. Tulis hasil keduanya di `docs/LOG_EKSEKUSI.md`.
3. **Berhenti** jika: Flutter < 3.24; `flutter doctor` menandai ✗ pada *Android toolchain*; atau Java < 17.

Selesai jika log tertulis. Tidak ada commit.

### T01 — Git lokal
1. `git init`
2. `git add -A`
3. `git commit -m "chore: dokumen, data, dan kode fondasi dari perencana"`

Selesai jika `git log` menampilkan 1 commit.

### T02 — Buat proyek Flutter di folder ini
1. Di folder `Minna Pocket/`: `flutter create --org id.minnapocket --project-name minna_pocket --platforms android .`
2. Kembalikan file milik perencana yang mungkin tertimpa: `git checkout -- pubspec.yaml .gitignore` (abaikan jika tidak berubah).
3. Hapus file contoh: `lib/main.dart` dan `test/widget_test.dart`.
4. Ganti isi `analysis_options.yaml` dengan:
   ```yaml
   include: package:flutter_lints/flutter.yaml
   analyzer:
     exclude: [build/**, content-src/**, tools/**]
   linter:
     rules:
       prefer_const_constructors: false
       prefer_const_literals_to_create_immutables: false
   ```
5. `git status`: pastikan **tidak ada** perubahan di `lib/` (selain `lib/main.dart` yang dihapus), `assets/`, `docs/`, `test/shared/`.

Commit: `chore: flutter create (android)`.

### T03 — Konfigurasi Android
1. Buka `android/app/build.gradle.kts`.
   - **Jika file itu tidak ada** (yang ada hanya `build.gradle` versi Groovy): BERHENTI dan laporkan.
   - Tempel bagian (A)–(D) dari `android_snippets/build.gradle.kts.snippet` sesuai petunjuk di file itu.
2. Ubah `android/app/src/main/AndroidManifest.xml` sesuai `android_snippets/AndroidManifest.snippet.xml` (A)–(C).
3. Salin ikon:
   - seluruh isi `assets/logo/android_res_book1/` → `android/app/src/book1/res/`;
   - seluruh isi `assets/logo/android_res_book2/` → `android/app/src/book2/res/`.
4. `flutter pub get`. Jika gagal resolusi versi: BERHENTI dan laporkan pesan lengkapnya.

Commit: `chore(android): flavor book1/book2, izin, ikon, signing`.

### T04 — Stub semua layar
Buat file-file berikut. Isinya **persis** templat di bawah, dengan `<Kelas>` dan parameter sesuai tabel.

**Templat tanpa parameter:**
```dart
import 'package:flutter/material.dart';

class <Kelas> extends StatelessWidget {
  const <Kelas>({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('<Kelas>')));
}
```

**Templat dengan parameter** (contoh `LessonScreen`):
```dart
import 'package:flutter/material.dart';

class LessonScreen extends StatelessWidget {
  const LessonScreen({super.key, required this.lesson});
  final int lesson;
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(), body: Center(child: Text('LessonScreen $lesson')));
}
```

| File (di `lib/features/`) | Kelas | Parameter |
|---|---|---|
| onboarding/presentation/screens/onboarding_screen.dart | OnboardingScreen | – |
| home/presentation/screens/home_screen.dart | HomeScreen | – |
| home/presentation/screens/more_screen.dart | MoreScreen | – |
| lesson/presentation/screens/lesson_screen.dart | LessonScreen | `int lesson` |
| lesson/presentation/screens/number_picker_screen.dart | NumberPickerScreen | `int lesson`, `String section` |
| kosakata/presentation/screens/kosakata_screen.dart | KosakataScreen | `int lesson` |
| kosakata/presentation/screens/sankou_screen.dart | SankouScreen | `int lesson` |
| bunkei_reibun/presentation/screens/bunkei_screen.dart | BunkeiScreen | `int lesson` |
| bunkei_reibun/presentation/screens/reibun_screen.dart | ReibunScreen | `int lesson` |
| kaiwa/presentation/screens/kaiwa_screen.dart | KaiwaScreen | `int lesson` |
| renshuu/presentation/screens/renshuu_a_screen.dart | RenshuuAScreen | `int lesson`, `int no` |
| renshuu/presentation/screens/renshuu_b_screen.dart | RenshuuBScreen | `int lesson`, `int no` |
| renshuu/presentation/screens/renshuu_c_screen.dart | RenshuuCScreen | `int lesson`, `int no` |
| mondai/presentation/screens/mondai_screen.dart | MondaiScreen | `int lesson`, `int no` |
| bunpou/presentation/screens/bunpou_screen.dart | BunpouScreen | `int lesson`, `int no` |
| book_extras/presentation/screens/intro_screen.dart | IntroScreen | – |
| practice_mix/presentation/screens/practice_hub_screen.dart | PracticeHubScreen | – |
| practice_mix/presentation/screens/mix_setup_screen.dart | MixSetupScreen | – |
| practice_mix/presentation/screens/mix_session_screen.dart | MixSessionScreen | – |
| mondaishuu/presentation/screens/mondaishuu_set_screen.dart | MondaishuuSetScreen | `String setId` |
| mondaishuu/presentation/screens/mondaishuu_exercise_screen.dart | MondaishuuExerciseScreen | `String setId`, `int exNo`, `bool onlyWrong = false` (tidak wajib) |
| mondaishuu/presentation/screens/mondaishuu_result_screen.dart | MondaishuuResultScreen | `String setId` |
| hafalan/presentation/screens/hafalan_hub_screen.dart | HafalanHubScreen | – |
| hafalan/presentation/screens/kana_table_screen.dart | KanaTableScreen | `String script` |
| hafalan/presentation/screens/flashcard_screen.dart | FlashcardScreen | `String deck` |
| hafalan/presentation/screens/quiz_screen.dart | QuizScreen | `String deck` |
| hafalan/presentation/screens/review_screen.dart | ReviewScreen | – |
| search/presentation/screens/search_screen.dart | SearchScreen | – |
| bookmarks/presentation/screens/bookmarks_screen.dart | BookmarksScreen | – |
| settings/presentation/screens/settings_screen.dart | SettingsScreen | – |
| settings/presentation/screens/flags_screen.dart | FlagsScreen | – |
| ai_assist/presentation/screens/ai_settings_screen.dart | AiSettingsScreen | – |

Semua parameter memakai `required` **kecuali** `onlyWrong`.

**Selesai jika:**
- `flutter analyze` → 0 error/warning;
- `flutter test` → lulus (tes `test/shared/` membaca data asli);
- `flutter run --flavor book1 -t lib/main/main_book1.dart` → aplikasi terbuka dengan teks "OnboardingScreen".

Commit: `feat: stub semua layar, aplikasi bisa berjalan`.

> ⛳ **Titik cek 1 (pemilik):** aplikasi terpasang di HP, ikon の muncul dengan nama "Minna Pocket".

---

## 3. Fase 1 — Layar (satu task = satu commit)

**Aturan umum setiap task:**
- Ganti isi stub dengan implementasi sesuai spesifikasi.
- Boleh membuat file baru **hanya** di folder `presentation/widgets/` dan `domain/providers/` milik fitur di task itu (kecuali disebut lain).
- **Selesai jika:**
  - `flutter analyze` 0 error/warning;
  - `flutter test` lulus;
  - aplikasi dijalankan dan semua butir **09 §<ID layar>** terpenuhi.
- Commit: `feat(<fitur>): <judul>`.

| Task | Judul | Spesifikasi | File yang diubah/dibuat |
|---|---|---|---|
| T10 | Beranda | 05 §S-02, 06 §8 | home/…/home_screen.dart; boleh widgets di home/ |
| T11 | Bab (daftar bagian) | 05 §S-03 | lesson/…/lesson_screen.dart |
| T12 | Pilih nomor | 05 §S-04 | lesson/…/number_picker_screen.dart |
| T13 | Kosa Kata | 05 §S-05 | kosakata/…/kosakata_screen.dart |
| T14 | Bunkei & Reibun | 05 §S-06, S-07 | bunkei_reibun/…/bunkei_screen.dart, reibun_screen.dart |
| T15 | Kaiwa | 05 §S-08 | kaiwa/…/kaiwa_screen.dart |
| T16 | Tata Bahasa & Kata Referensi | 05 §S-13, S-14 | bunpou/…/bunpou_screen.dart; kosakata/…/sankou_screen.dart |
| T17 | Renshuu A | 05 §S-09 | renshuu/…/renshuu_a_screen.dart |
| T18 | Renshuu B | 05 §S-10 | renshuu/…/renshuu_b_screen.dart |
| T19 | Renshuu C | 05 §S-11 | renshuu/…/renshuu_c_screen.dart |
| T20 | Mondai | 05 §S-12 | mondai/…/mondai_screen.dart |

> ⛳ **Titik cek 2:** Bab 1 bisa dipelajari dari awal sampai Mondai di HP. Audio Kaiwa & Mondai berbunyi, kanji bisa diketuk, mode Ro berfungsi.

| Task | Judul | Spesifikasi | File |
|---|---|---|---|
| T21 | Tab Latihan | 05 §S-16 | practice_mix/…/practice_hub_screen.dart |
| T22 | Set Mondaishuu | 05 §S-17 | mondaishuu/…/mondaishuu_set_screen.dart |
| T23 | Latihan Mondaishuu | 05 §S-18, 06 §2 | mondaishuu/…/mondaishuu_exercise_screen.dart; boleh widgets di mondaishuu/ |
| T24 | Ringkasan Mondaishuu | 05 §S-19 | mondaishuu/…/mondaishuu_result_screen.dart |

> ⛳ **Titik cek 3:** Mondaishuu 第1・2課 bisa dikerjakan. Koreksi, coba lagi, lihat jawaban, dan skor tersimpan setelah aplikasi ditutup lalu dibuka lagi.

| Task | Judul | Spesifikasi | File |
|---|---|---|---|
| T25 | Deck, antrian ulasan, kuis (provider) | 06 §1.2–1.4 | hafalan/domain/providers/deck_providers.dart, review_queue.dart, quiz_builder.dart |
| T26 | Tab Hafalan + tabel kana | 05 §S-22, S-23 | hafalan/…/hafalan_hub_screen.dart, kana_table_screen.dart, widgets/kana_grid.dart |
| T27 | Kartu, Kuis, Ulasan | 05 §S-24–S-26 | hafalan/…/flashcard_screen.dart, quiz_screen.dart, review_screen.dart |
| T28 | Pencarian | 05 §S-27, 06 §6 | search/…/search_screen.dart; search/domain/providers/search_providers.dart, route_for_ref.dart |
| T29 | Tersimpan | 05 §S-28 | bookmarks/…/bookmarks_screen.dart (boleh impor `routeForRef` dari search) |
| T30 | Lainnya | 05 §S-29 | home/…/more_screen.dart |
| T31 | Pengaturan + Tandaan | 05 §S-30, S-32 | settings/…/settings_screen.dart, flags_screen.dart |
| T32 | Pengaturan AI | 05 §S-31, 07 | ai_assist/…/ai_settings_screen.dart |
| T33 | はじめに | 05 §S-15 | book_extras/…/intro_screen.dart (impor `KanaGrid` dari hafalan) |
| T34 | Onboarding | 05 §S-01 | onboarding/…/onboarding_screen.dart |
| T35 | Latihan Campuran | 05 §S-20, S-21, 06 §7 | practice_mix/…/mix_setup_screen.dart, mix_session_screen.dart; practice_mix/domain/providers/mix_providers.dart |

> ⛳ **Titik cek 4:** semua menu bisa dibuka; backup → hapus data → pulihkan berhasil; tombol ✨ muncul setelah API key diisi.

---

## 4. Fase 2 — Uji menyeluruh & rilis

### T40 — Uji menyeluruh
1. Jalankan seluruh **09 §Umum** dan semua §S-xx di HP, dalam mode terang & gelap, dengan ukuran huruf "Sangat besar".
2. Catat butir yang gagal di `docs/LOG_EKSEKUSI.md`.
3. Perbaiki **hanya** di file layar yang bersangkutan. Jika penyebabnya di file `DISEDIAKAN LENGKAP` atau di data: BERHENTI dan laporkan.

Commit: `fix: hasil uji menyeluruh`.

### T41 — Build rilis
1. Pemilik membuat keystore (08 §3) **sebelum** task ini.
2. Naikkan `version:` di `pubspec.yaml` menjadi `1.0.0+1` (sudah) atau +1 dari sebelumnya. Ini **satu-satunya** perubahan pubspec yang diizinkan.
3. `flutter build apk --release --flavor book1 -t lib/main/main_book1.dart`
4. Catat ukuran APK di log.

Commit: `release: v1.0.0`. Buat tag: `git tag v1.0.0`.

> ⛳ **Titik cek 5:** APK rilis terpasang & berjalan offline (mode pesawat), kecuali fitur ✨.

---

## 5. Fase data (dikerjakan perencana, paralel dengan Fase 1)
Perencana mengirim paket data baru (bab 2–25, Mondaishuu lain, 復習, はじめに/intro, まとめ). Setiap kali paket data datang, AI eksekutor menjalankan:

### T50 — Terapkan paket data
1. Salin/timpa isi paket ke folder proyek **persis** sesuai struktur paket. Isinya hanya `assets/book1/**`, `content-src/**`, dan `pubspec.yaml` (bagian ASSETS).
2. `flutter pub get` → `flutter test` (tes otomatis memeriksa semua bab yang ada di manifest).
3. Jalankan aplikasi; buka bab baru; cek 09 §S-03..S-12 sekilas.

Commit: `data: <isi paket>`.

**Tambahan untuk 復習 / まとめ:** tidak perlu layar atau rute baru. Data 復習/まとめ memakai format set Mondaishuu dan rute `/ms/:id` yang sama; baris di Beranda (05 §S-02) membuka `/ms/FA` dst. Task T-Mondaishuu cukup memastikan `contentRepository.mondaishuu(id)` memakai `manifest.setMeta(id)` (sudah ada di repo).

---

## 6. Jika ada masalah
| Masalah | Tindakan |
|---|---|
| Error di file `DISEDIAKAN LENGKAP` | BERHENTI. Salin pesan error lengkap ke log. Pemilik meneruskannya ke perencana. |
| Resolusi paket gagal (`pub get`) | BERHENTI. Salin pesan lengkap ke log. |
| Spesifikasi kurang jelas | BERHENTI. Tulis pertanyaan spesifik ke log. |
| Data terlihat salah (teks, furigana, gambar, audio) | Jangan diubah. Catat ID item di log. Pemilik bisa juga memakai 🚩 di aplikasi. |
