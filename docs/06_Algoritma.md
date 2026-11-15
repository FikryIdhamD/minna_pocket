# 06 — Algoritma

> Bagian bertanda **[KODE JADI]** sudah ditulis di `lib/` dan tidak boleh diubah. Bagian bertanda **[DIBUAT]** ditulis AI eksekutor **persis** mengikuti langkah di sini.

## 1. Hafalan & spaced repetition

### 1.1 Penilaian kartu — [KODE JADI] `lib/shared/utils/srs.dart`
| Nilai | Efek |
|---|---|
| Lupa | reps=0, lapses+1, interval 0, jatuh tempo hari ini (muncul lagi di sesi), ease −0.20 (min 1.3) |
| Susah | interval = max(1, interval×1.2), ease −0.15 |
| Bisa | reps 0 → 1 hari; reps 1 → 3 hari; berikutnya interval×ease |
| Mudah | seperti Bisa, ×1.3, ease +0.15 (maks 3.0) |

"Hafal" (`isMastered`) = reps ≥ 2 dan interval ≥ 3.

### 1.2 Isi deck — [DIBUAT] `features/hafalan/domain/providers/deck_providers.dart`
Buat `class DeckCard { final String key; final String front; final String? reading; final String? romaji; final String? meaning; final List<int> lessons; }` dan `final deckProvider = FutureProvider.family<List<DeckCard>, String>(...)`:
- **`hira`**: semua sel `kanaChart.hiragana` (urutan tabel), dengan key `"hira:<kana>"`, front = kana, romaji = `ro`.
- **`kata`**: sama, dari `katakana`, key `"kata:<kana>"`.
- **`kanji-<n>`**: semua `KanjiEntry` dengan `firstLesson == n`, key `"kanji:<word>"`, front = word, reading = `readings.join('・')`, romaji = `readingsRo.join(' / ')`, meaning = `meaning`, lessons = lesson unik dari `occurrences` (urut naik).

### 1.3 Antrian "Ulasan hari ini" — [DIBUAT] `features/hafalan/domain/providers/review_queue.dart`
1. **Jatuh tempo** = semua key di `userData.srs` dengan `isDue(card)`. Urutkan menurut `due` naik, lalu key.
2. **Kartu baru** = kartu deck yang belum ada di `srs`, diambil berurutan: deck `hira` → `kata` → `kanji-1` … `kanji-25`. Jumlahnya `settings.newCardsPerDay` dikurangi jumlah kartu baru yang sudah diperkenalkan hari ini.
   - Simpan hitungan hari ini di `shared_preferences` dengan kunci `review.newDate` (yyyy-MM-dd) dan `review.newCount`. Reset jika tanggal berbeda.
3. **Antrian** = jatuh tempo + kartu baru.
4. **Jumlah untuk Beranda/Hafalan** = panjang antrian.

### 1.4 Kuis — [DIBUAT] `features/hafalan/domain/providers/quiz_builder.dart`
- **Jumlah soal** = min(10, ukuran deck). Kartu diambil acak (`Random()`).
- **Hira/kata:** prompt = kana, pilihan = romaji. Pengecoh: 3 romaji acak dari deck yang sama, berbeda dari jawaban dan berbeda satu sama lain.
- **Kanji:** prompt = word, pilihan = `readings.first`. Pengecoh: `readings.first` dari 3 kata acak lain di deck yang sama. Jika deck < 4 kata, ambil dari bab sebelumnya. Jika masih kurang, tampilkan pilihan yang ada saja (minimal 2).
- Urutan pilihan diacak.

## 2. Koreksi jawaban — [KODE JADI] `lib/shared/utils/answer_checker.dart`
- `normalizeAnswer`:
  1. buang awalan "例："; romaji huruf kecil → hiragana;
  2. lebar penuh → biasa;
  3. katakana → hiragana;
  4. "ー" → vokal sebelumnya;
  5. buang spasi & tanda baca (。、・！？「」（）［］〜／：…).
- **Diterima** jika hasil normalisasi = normalisasi salah satu `answersJp` **atau** bacaannya (`reading`).
- `option`: bandingkan huruf (tanpa huruf besar/kecil). `free`: tidak dinilai.
- **Status soal** (S-18):
  - semua blank benar atau ditandai "Anggap benar" → `correct`, kecuali soal ada di `revealed` → `assisted`;
  - ada blank salah/kosong → `wrong`;
  - soal yang seluruh blank-nya `free` tidak dihitung.

## 3. Ketikan romaji → kana — [KODE JADI] `lib/shared/utils/kana_input.dart`
Aturan IME umum:
- "nn" → ん, kecuali sebelum vokal/y yang menjadi ん + な行;
- n + konsonan → ん;
- konsonan ganda → っ;
- "-" → ー.

Huruf besar tidak dikonversi (untuk "IMC", "CD"). `KanaTextField` mengonversi saat mengetik.

## 4. Progres — [KODE JADI] `progress_selectors.dart`, `user_data_provider.dart`
- **Unit selesai:**
  - bagian tanpa nomor → `"Lxx.<key>"`;
  - bagian bernomor (renshuu_a/b/c, mondai, bunpou) → `"Lxx.<key>.<no>"` untuk **setiap** nomor.
- **Bagian selesai** = semua unitnya selesai. **Progres bab** = bagian selesai / jumlah bagian. **Progres keseluruhan** = rata-rata progres bab.
- **Auto-selesai:** `SectionScaffold` menandai `doneRef` saat sisa gulir < 24 px (termasuk layar yang tidak perlu digulir). Pengguna bisa membatalkan lewat `DoneFooter`.
- **Lanjutkan:** setiap layar konten memanggil `setLastOpened(route, label)` saat dibuka (otomatis lewat `trackRoute`/`trackLabel` di `SectionScaffold`). Layar Mondaishuu [DIBUAT] memanggilnya sendiri di `initState` dengan label "Mondaishuu · <title> · Latihan n".
- **Penyimpanan:** setiap perubahan disimpan ke file setelah jeda 500 ms, dan langsung saat aplikasi ke latar belakang (`LifecycleObserver`).

## 5. Audio — [KODE JADI] `audio_controller.dart`
- **Satu `AudioPlayer`** untuk seluruh aplikasi. Kecepatan selalu mengikuti `settings.audioSpeed` (berubah langsung saat diganti).
- **`playFrom(t)`** (ketuk baris Kaiwa): lompat ke `t.start`, putar terus.
- **`playSegment(t)`** (Mondai): lompat ke `t.start`, putar. Jika `autoPause` aktif, berhenti saat posisi ≥ `t.end`.
- **`loopRange(t)`**: kembali ke `t.start` setiap posisi ≥ `t.end`, sampai `stopLoop()`.
- **Selesai file:** jika `autoRepeat` aktif kembali ke 0 dan lanjut; jika tidak, jeda di 0.
- **Baris/segmen "sedang diputar"** = `playing` dan `t.start − 0.05 ≤ posisi < t.end + 0.3`.

## 6. Pencarian — [DIBUAT] `features/search/domain/providers/search_providers.dart`

### 6.1 Normalisasi query
`q = query.trim().toLowerCase()`.
- Jika q berisi huruf latin a–z:
  - `qRo` = q tanpa spasi;
  - `qKana` = `toHiragana(romajiToHiraganaFinal(q))` tanpa spasi;
  - `qTr` = q.
- Jika tidak: `qJp` = `toHiragana(q)` tanpa spasi.

### 6.2 Kecocokan & peringkat (per entri `SearchEntry`)
**Bidang:**
- `ro2` = `ro` tanpa spasi;
- `kana2` = `kana` tanpa spasi & tanda baca;
- `jp2` = `toHiragana(jp)` tanpa spasi.

**Skor** (makin kecil makin atas; entri tanpa skor dibuang):
| Kondisi | Skor |
|---|---|
| Sama persis dengan salah satu bidang (latin: `ro2` == `qRo` atau `kana2` == `qKana`; Jepang: `jp2` == `qJp` atau `kana2` == `qJp`) | 0 |
| Diawali query | 1 |
| Mengandung query | 2 |
| Latin, `tr.toLowerCase()` mengandung `qTr` sebagai kata utuh (`RegExp(r'\b' + RegExp.escape(qTr))`) | 3 |
| Latin, `tr.toLowerCase()` mengandung `qTr` di mana saja | 4 |

**Urutan:** skor, lalu tipe (kosakata < kalimat < tata_bahasa < referensi), lalu `lesson`. Maksimal 60 hasil. Hitung di provider `FutureProvider.family<List<SearchEntry>, String>`.

### 6.3 Navigasi dari ref (dipakai Pencarian & Tersimpan)
Fungsi `String routeForRef(String ref)` di `features/search/domain/providers/route_for_ref.dart`:
- `MSxx.<ex>[.<item>]` → `/ms/MSxx/ex/<ex>`.
- `Lnn.<key>[.<no>[.<sub>]]`:
  - n = `int.parse(nn)`;
  - key ∈ {kosakata, bunkei, reibun, kaiwa, sankou} → `sectionRoute(n, key)`;
  - key bernomor dengan `<no>` → `sectionRoute(n, key, no: no)`;
  - tanpa nomor → `sectionRoute(n, key)`.

## 7. Latihan Campuran — [DIBUAT] `features/practice_mix/domain/providers/mix_providers.dart`
```dart
class MixConfig { final int from, to; final bool useMs, useVocab; final int? count; final bool focusWeak; }
sealed class MixQuestion {}            // MixMsQuestion(set, exercise, item) | MixVocabQuestion(item, options, lesson)
final mixConfigProvider = NotifierProvider<MixConfigNotifier, MixConfig?>(...);
final mixQuestionsProvider = FutureProvider<List<MixQuestion>>(...);  // dihitung sekali per sesi
```
**Pembuatan soal:**
1. **Kumpulan Mondaishuu** (jika `useMs`): semua `MsItem` dengan `autoGraded == true`, dari set yang `lessons` beririsan dengan [from, to].
2. **Kumpulan kosakata** (jika `useVocab`): semua `KosakataItem` bab from..to yang `tr`-nya tidak mengandung "fiksi". Pilihan = arti benar + 3 `tr` acak berbeda dari kumpulan yang sama.
3. **Bobot:** 1 untuk semua soal. Jika `focusWeak`:
   - soal Mondaishuu dengan status `wrong`/`assisted` di `msScores` → bobot 3;
   - kosakata yang key `"kanji:<kata>"`-nya punya `lapses ≥ 1` → bobot 3.
4. **Ambil** `count` soal (atau semua) secara acak berbobot tanpa pengembalian, lalu acak urutannya.
5. **Hasil sesi** (benar/salah per soal dan bab asalnya) disimpan di state layar. Sesi tidak mengubah `msScores`.

## 8. Waktu relatif (Beranda)
| Kondisi | Teks |
|---|---|
| Hari yang sama | "Hari ini" |
| Kemarin | "Kemarin" |
| < 30 hari | "x hari lalu" |
| Lainnya | "dd/MM/yyyy" |
