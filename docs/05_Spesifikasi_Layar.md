# 05 — Spesifikasi Layar

> Setiap layar: **file**, **kelas** (nama & parameter sudah dipakai router `lib/routes/app_route.dart`, jadi WAJIB sama), **data**, **susunan**, **interaksi**, **keadaan**.
> Teks dalam "tanda kutip" ditulis **persis**. Konstanta `S.xxx` ada di `lib/shared/utils/strings.dart`.
> Komponen jadi di `docs/04_Design_System.md §6` WAJIB dipakai. Jarak, warna, dan huruf hanya dari token.
> Semua layar adalah `ConsumerWidget` atau `ConsumerStatefulWidget` (Riverpod).
>
> Singkatan:
> - `L` = id bab (`L01`), `n` = nomor bab.
> - `ud` = `ref.read(userDataProvider.notifier)`.
> - `go/push` = `context.go` / `context.push` (go_router).

---

## K — Pola bersama

### K-1 Layar konten bab
Pakai `SectionScaffold(title, lesson, body: (ctx, showTr) => [...], doneRef, trackRoute, trackLabel, …)`.
- `title` = gabungan `S.sectionJp[key]` + spasi + `S.sectionNames[key]` (mis. "会話 Kaiwa"). Untuk kosakata/bunpou/sankou cukup `S.sectionNames[key]`.
- `trackRoute` = rute layar itu sendiri.
- `trackLabel` = "Bab n · <S.sectionNames[key]>" (+ " · Nomor x" untuk layar bernomor).
- Data diambil dengan `ref.watch(lessonProvider(n))` dibungkus `AsyncView`, lalu `SectionScaffold` dibangun di dalam `data:`.

### K-2 Status selesai
- Bagian tanpa nomor: `doneRef` = `"$L.<key>"` (mis. `L01.kaiwa`).
- Bagian bernomor: `"$L.<key>.<no>"`.
- `SectionScaffold` otomatis menandai selesai saat digulir sampai bawah dan menampilkan `DoneFooter`.

### K-3 Audio
- Saat layar dibuka (`initState`): simpan `final audio = ref.read(audioControllerProvider.notifier)`, lalu panggil `audio.open(path)`.
- Di `dispose()`: panggil `audio.stop()` lewat variabel itu. **Jangan memakai `ref` di dispose.**
- Kaiwa memakai `MiniPlayer` (di `floating`). Mondai memakai `SegmentPlayer` + `SegmentPlayButton`.

### K-4 Menu tekan-lama
Setiap teks Jepang utama (baris kalimat, kosakata, soal) dibungkus `GestureDetector(onLongPress: () => showJpActions(...))`. Parameter:

| Konten | kind | label | ai |
|---|---|---|---|
| Kalimat Bunkei/Reibun/Kaiwa/contoh | "kalimat" | teks `jp` | `AiRequest(explainSentence)` |
| Kosa Kata | "kosakata" | "`jp` — `tr`" | null |
| Soal Renshuu/Mondai | "latihan" | "Bab n · <Bagian> no.q" | `exampleAnswer` (lihat S-12) |

**`bookContext` untuk AI** (gabungan teks, maks ±1500 karakter):
1. Judul semua poin Tata Bahasa bab itu (`titleRich.jp`).
2. Kalimat Bunkei bab itu (`jp` + `tr`).
3. Untuk soal: juga contoh (例) nomor itu.

### K-5 Tombol ✨
Tombol ✨ hanya muncul jika `ref.watch(aiEnabledProvider).valueOrNull == true`.

### K-6 Ukuran huruf
Seluruh teks Jepang otomatis mengikuti `settings.textScale` lewat `JpTextView`.

---

## S-01 Onboarding — `features/onboarding/presentation/screens/onboarding_screen.dart`
`class OnboardingScreen` — rute `/onboarding`.

**Data:** `extraDocProvider('howto')`, `manifestProvider`.

**Susunan:** `PageView` 3 halaman + indikator titik di bawah + tombol teks "Lewati" (kanan atas, halaman 1–2).
1. **"Cara belajar dari buku"**: render `ExtraDoc.sections.first.blocks` dengan `ContentBlocksView` di dalam `ListView`. Tombol bawah: "Lanjut".
2. **"Fitur Minna Pocket"**: 4 baris (ikon + judul + 1 kalimat):
   - "Ketuk kanji" — "Furigana muncul saat kanji diketuk."
   - "あ | Ro" — "Ganti tampilan ke romaji kapan saja."
   - "🔊 Ucapkan" — "Tekan lama teks untuk mendengar pengucapan (suara sintetis)."
   - "✨ AI (opsional)" — "Isi API key di Pengaturan untuk penjelasan AI."

   Tombol: "Lanjut".
3. **"Sudah pernah belajar?"**, dua kartu pilihan:
   - **"Belum, mulai dari nol"**: `ud.setOnboardingDone()`, lalu `go('/')`, lalu `push('/kana/hira')`.
   - **"Sudah, sampai bab …"**: menampilkan pemilih angka 1–25 (− / angka / +). Tombol "Mulai dari Bab x+1":
     - untuk setiap bab `< x+1`, panggil `ud.setManyDone(semua sectionUnitRefs(l, s) untuk setiap bagian, true)` (fungsi dari `progress_selectors.dart`);
     - lalu `ud.setOnboardingDone()` dan `go('/')`.

"Lewati" = `ud.setOnboardingDone()` lalu `go('/')`.

---

## S-02 Beranda — `features/home/presentation/screens/home_screen.dart`
`class HomeScreen` — rute `/` (tab 1). Referensi: mockup 01 layar 1.

**Data:** `manifestProvider`, `userDataProvider`, `overallProgressProvider`, `lessonProgressProvider(n)`.

**Susunan** (`ListView`, padding 16):
1. **Header** (tinggi 56):
   - `Image.asset('assets/logo/logo_256.png', 36×36)` dalam `ClipRRect` radius 10;
   - teks `S.appName` (`AppText.title`);
   - `Spacer`;
   - `IconButton(AppIcons.search)` → `push('/search')`.
2. **Kartu Lanjutkan** (kartu daftar, padding 16):
   - **Jika `lastOpened != null`:**
     - tile 64×64 `primarySubtle` berisi huruf pertama `S.sectionTile` dari kunci di rute (atau "課");
     - overline "LANJUTKAN";
     - `lastOpened.label` (`AppText.headline`);
     - waktu relatif ("Hari ini", "Kemarin", "x hari lalu");
     - tombol penuh "Lanjutkan" → `push(lastOpened.route)`.
   - **Jika null:** overline "MULAI BELAJAR", judul "Bab 1 · " + `title_jp` bab 1 (`JpLabel`), tombol penuh "Mulai Bab 1" → `push('/lesson/1')`.
3. **Baris Ulasan hari ini** (tampil jika ada kartu jatuh tempo, lihat 06 §1.3):
   - latar `secondarySubtle`, radius `Radii.md`;
   - ikon `cards` + `S.reviewToday` + "x kartu jatuh tempo" + chevron;
   - → `push('/review')`.
4. **Banner backup** (tampil jika `done` tidak kosong DAN (`lastBackupAt` null ATAU lebih dari 30 hari)):
   - kartu `surfaceAlt`, teks "Simpan cadangan progres agar tidak hilang saat ganti HP.";
   - tombol teks "Backup" → `push('/settings')`.
5. **Baris はじめに:** kartu daftar satu baris, tile "あ" (buku utama), judul "はじめに · Huruf & pelafalan", chevron → `push('/intro')`.
6. **Judul grup:** "Bab" (`AppText.headline`) dan di kanan "Progres p% · s dari t dimulai" (`bodySm`, `inkMuted`).
7. **Daftar bab** (satu kartu daftar), iterasi `manifest.sequence`:
   - **type lesson:**
     - angka `n` (`AppText.brushNo`, lebar 32);
     - `JpLabel(title_jp)`;
     - subjudul: "x dari y bagian" (jika sudah dimulai) atau "y bagian";
     - trailing `ProgressRing(fraction)`;
     - → `push('/lesson/n')`.
   - **type fukushuu / matome:** latar baris `surfaceAlt`, tile teks "復" (atau "ま"), judul `title_jp`, subjudul `subtitle`, badge "Ulangan". → `push('/ms/${id}')` (rute set latihan S-15 yang sama dengan Mondaishuu; `contentRepository.mondaishuu(id)` membaca `manifest.setMeta(id)` sehingga id FA–FG, FS, M1, M2 ikut didukung). Progres/skor disimpan per `setId` seperti Mondaishuu.

**Keadaan:** loading = `SkeletonList`; error = `ErrorView` + Coba lagi (`ref.invalidate(manifestProvider)`).

---

## S-03 Bab — `features/lesson/presentation/screens/lesson_screen.dart`
`class LessonScreen({required int lesson})` — rute `/lesson/:no`. Referensi: mockup 01 layar 2.

**Data:** `manifestProvider` (`LessonMeta`), `userDataProvider.done`, `lessonProgressProvider(n)`.

**Susunan:**
- **AppBar:** ← (pop), judul kosong, aksi 🔎 → `push('/search')`.
- **Hero** (padding h20):
  - Row: "第n課" (`brushHero`, `primary`) + Column(`JpTextView(title_jp, size: JpSize.title)`, `title_tr` dengan `bodySm` `secondary`);
  - di bawahnya Row: `LinearProgressIndicator` (tinggi 6, radius full, warna `primary`, latar `surfaceAlt`) + teks "x / y selesai".
- **Untuk tiap grup** di `kSectionGroups` (lewati grup tanpa bagian yang ada): label grup `S.groupNames`, lalu kartu daftar berisi baris bagian.

**Baris bagian:**
- tile `S.sectionTile[key]` (buku utama/terjemahan menurut `source`);
- judul `S.sectionNames[key]`, ditambah `S.sectionJp[key]` kecil `jpSm` `inkMuted` bila ada;
- subjudul:

| key | subjudul |
|---|---|
| kosakata | "{count} kata · buku terjemahan" |
| bunkei | "{count} pola kalimat" |
| reibun | "{count} contoh kalimat" |
| kaiwa | `JpLabel(title_jp)` |
| renshuu_a | "{count} tabel pola" |
| renshuu_b | "{count} nomor" |
| renshuu_c | "{count} dialog latihan" |
| mondai | "{count} nomor · {audioNumbers.length} soal dengar" |
| bunpou | "{count} poin · buku terjemahan" |
| sankou | `titleTr` |

- trailing:
  - badge audio (kaiwa: durasi m:ss; mondai: jumlah nomor dengar);
  - lalu salah satu: selesai → ikon `checkCircle` (`success`); sebagian (bagian bernomor, 0 < fraksi < 1) → teks "x/y" `caption`; selain itu → `chevronRight` (`inkSubtle`).
- ketuk → `push(sectionRoute(n, key))`.

**Kartu jalan pintas** (jika ada set Mondaishuu dengan `lessons` memuat n):
- border `border`, radius `Radii.md`, ikon `practice` (`primary`), teks `S.goMondaishuu`, chevron;
- → `push('/ms/<id>')`.

---

## S-04 Pilih nomor — `features/lesson/presentation/screens/number_picker_screen.dart`
`class NumberPickerScreen({required int lesson, required String section})` — rute `/lesson/:no/p/:section`.

**Data:** `manifestProvider` (numbers, audioNumbers), `lessonProvider(n)` (untuk judul Tata Bahasa), `userDataProvider.done`.

**Susunan:**
- AppBar ← + judul "`S.sectionJp` `S.sectionNames`" (bunpou: "Tata Bahasa") + subjudul "Bab n · pilih nomor".
- **section ≠ bunpou** → `GridView` 3 kolom, jarak 12, kartu persegi radius `lg`. Isi tiap kartu:
  - angka nomor (`brushNo`);
  - di bawahnya "Nomor x" (`caption`, `inkMuted`);
  - pojok kanan atas: ikon `headphones` 16 (jika nomor ada di `audioNumbers`) dan/atau `checkCircle` 16 `success` (jika `"$L.$section.$x"` selesai).
- **section = bunpou** → kartu daftar; baris "x." + `JpTextView(titleRich, size small, mode kana, interactive false)` + trailing centang/chevron.
- ketuk → `push(sectionRoute(n, section, no: x))`.

---

## S-05 Kosa Kata — `features/kosakata/presentation/screens/kosakata_screen.dart`
`class KosakataScreen({required int lesson})` — rute `/lesson/:no/kosakata`. Pola K-1, `doneRef "$L.kosakata"`, `showModeToggle: true`.

**Susunan** (per grup):
- **Label grup:**
  - jika `labelJp` → `JpTextView(labelJp, size small)` dengan padding atas 16;
  - jika `separator` → `Divider` dengan jarak 16.
- **Kartu daftar** berisi item. Tiap item `Row`:
  - **kiri** `Expanded(Column)`:
    - jika `kanjiJp != null` → `JpTextView(kanjiJp)` lalu `JpTextView(kanaJp, size small, color inkMuted, interactive false)`;
    - jika tidak → `JpTextView(kanaJp)`;
    - lalu `Text(tr, body)`.
  - **kanan** `IconButton(AppIcons.speaker)` → `ref.read(ttsServiceProvider).speak(kanaJp.reading)`.
- Tekan lama item → K-4 (kind "kosakata").

---

## S-06 Bunkei — `features/bunkei_reibun/presentation/screens/bunkei_screen.dart`
`class BunkeiScreen({required int lesson})` — rute `/lesson/:no/bunkei`. Pola K-1, judul "文型 Bunkei", `showTranslationToggle: true`, `doneRef "$L.bunkei"`.

**Susunan:** untuk tiap item, Row:
- lingkaran nomor 28 (`surfaceAlt`, `caption`);
- `Expanded(Column)`:
  - `JpTextView(jp)`;
  - setiap `variantsJp` → `JpTextView(v, size small, color inkMuted, interactive false)` rata kanan;
  - terjemahan `Text(tr, bodySm, secondary)` tampil jika `showTr` atau baris ini sedang dibuka.

Jarak antar item 20.

**Interaksi:**
- ketuk baris (di luar kanji) → buka/tutup terjemahan baris itu (state lokal `Set<String>`);
- tekan lama → K-4 (kalimat).

---

## S-07 Reibun — `features/bunkei_reibun/presentation/screens/reibun_screen.dart`
`class ReibunScreen({required int lesson})` — rute `/lesson/:no/reibun`. Sama seperti S-06, dengan perbedaan:
- tiap item adalah kartu daftar berisi `lines`;
- baris yang `jp.jp` diawali "……" diberi indentasi kiri 16;
- terjemahan per baris;
- `doneRef "$L.reibun"`.

---

## S-08 Kaiwa — `features/kaiwa/presentation/screens/kaiwa_screen.dart`
`class KaiwaScreen({required int lesson})` — rute `/lesson/:no/kaiwa`. Referensi: mockup 01 layar 3.

**Kerangka:** K-1 + K-3:
- judul "会話 Kaiwa";
- `showTranslationToggle`, `showAudioSettings: true`;
- `doneRef "$L.kaiwa"`;
- `floating: MiniPlayer(title: "CD ${cdTrack.replaceAll('CD','')} · Kaiwa")`;
- `scrollController` milik state.

**Susunan:**
1. Judul: `JpTextView(titleJp, size title)` + `Text(titleTr, bodySm, secondary)`.
2. `BookImage(kaiwa.image)`.
3. Petunjuk: "Tekan kanji untuk furigana · ketuk baris untuk memutar dari situ · tekan lama untuk menu" (`caption`, `inkSubtle`).
4. Baris dialog, masing-masing `Container` padding v8 h12 radius `md`, dengan `GlobalKey` per baris. Jika `line.breakBefore`, tampilkan dulu garis pemisah adegan: `Padding(v 8)` → `Divider` warna `border` (indentasi kiri 56). Isinya `Row`:
   - kolom pembicara lebar 56: `JpLabel(speakerJp)` hanya jika `turnStart`, warna `inkMuted`;
   - `Expanded(Column(JpTextView(jp), terjemahan bila showTr atau baris dibuka))`.
   - Latar `highlightBg` jika baris sedang diputar: `audio.playing && line.t!.contains(audio.positionSec)`, atau bila `audio.loop` dan `audio.range == line.t`.

**Interaksi:**
- **Ketuk baris** → `audio.playFrom(line.t!)` + buka terjemahan baris itu.
- **Tekan lama baris** → `showJpActions(... extra: [JpExtraAction(icon: AppIcons.repeatOne, label: "Ulangi baris ini terus", onTap: () => audio.loopRange(line.t!))])`. Ketika loop aktif, tampilkan SnackBar "Mengulang baris ini. Ketuk ⏸ untuk berhenti.".
- **Gulir otomatis:** jika `settings.kaiwaAutoScroll` dan baris yang diputar berubah → `Scrollable.ensureVisible(key.currentContext!, alignment: 0.35, duration: 250ms)`.
- **Tombol ⏸ di MiniPlayer saat loop aktif** → jeda; panggil juga `audio.stopLoop()` saat baris lain diketuk.

---

## S-09 Renshuu A — `features/renshuu/presentation/screens/renshuu_a_screen.dart`
`class RenshuuAScreen({required int lesson, required int no})` — rute `/lesson/:no/renshuu_a/:n`.

**Kerangka:**
- K-1: judul "練習A Renshuu A", subjudul "Bab n · Nomor no", `doneRef "$L.renshuu_a.no"`.
- `bottomBar: NumberNavBar(prevRoute, nextRoute, nextLabel: "Nomor ${no+1}")`. `prev`/`next` = nomor sebelum/sesudah di `numbers` manifest; null jika tidak ada.

**Susunan:** satu kartu `surface` padding 16. Tiap baris (`lines`) adalah `SingleChildScrollView(horizontal)` → `Row(crossAxisAlignment.start)` berisi segmen:
- **Segmen teks:** `Padding(top 8, h4)` → `Column(JpTextView(textJp), variants kecil inkMuted)`.
- **Segmen slot:** `Column` berisi kotak-kotak, jarak 4. Tiap kotak:
  - `Container(padding 8, radius sm)`, warna: `normal` → `highlightBg`; `strong` → `highlight`; `none` → transparan;
  - isinya `Column` opsi (`JpTextView` per opsi, jarak 2).

Jarak antar baris 16. Di bawah kartu, `Text("Baca keras-keras setiap baris kombinasi.", caption, inkMuted)`.

---

## S-10 Renshuu B — `features/renshuu/presentation/screens/renshuu_b_screen.dart`
`class RenshuuBScreen({required int lesson, required int no})`. Kerangka seperti S-09: judul "練習B Renshuu B", `showGrammar: true`, `doneRef "$L.renshuu_b.no"`.

**Susunan:**
1. Jika `renshuuB.figureOf(item) != null` → `BookImage(figure.image)`. Lebar layar penuh; bisa diperbesar dengan `InteractiveViewer` (maxScale 3) di dalam dialog saat diketuk.
2. Kartu contoh (pola 04 §6.1) untuk setiap `examples`:
   - baris prompt: `JpTextView(promptJp)` + "→";
   - jika prompt null, tulis "(lihat gambar) →" (`bodySm`, `inkMuted`);
   - lalu tiap `answerJp` sebagai `JpTextView` (indentasi 16).
3. Daftar soal (kartu daftar). Baris: "q)" (`bodyStrong`, `inkMuted`, lebar 28) + `JpTextView(promptJp)` (atau "(lihat gambar)") + " →".
4. `Text(S.noKeyMondai)` kecil `inkMuted`, lalu tombol garis `S.goMondaishuu` (jika ada set).

**Interaksi:** tekan lama soal → K-4 (kind "latihan", `ai: AiRequest(exampleAnswer, target: "<prompt atau 'Nomor q (lihat gambar)'>", bookContext: K-4 + contoh)`).

---

## S-11 Renshuu C — `features/renshuu/presentation/screens/renshuu_c_screen.dart`
`class RenshuuCScreen({required int lesson, required int no})`. Kerangka seperti S-09: judul "練習C Renshuu C", `doneRef "$L.renshuu_c.no"`.

**Susunan:**
1. `SegmentedButton<int>` dengan segmen: "Contoh" (0) dan "1", "2", … sesuai `substitutions`.
2. Gambar: segmen 0 → `BookImage(item.image)`; segmen k → `BookImage(substitutions[k-1].image)`.
3. Dialog: baris dengan kolom pembicara (huruf A/B/C, `bodyStrong`, `primaryStrong`, lebar 28, hanya jika `turnStart`) + `JpTextView(jp)`. Bagian bergaris bawah (`u`) adalah bagian yang diganti sesuai gambar pengganti.
4. Petunjuk `caption`: "Ganti bagian bergaris bawah sesuai gambar 1 / 2, lalu ucapkan dialognya."

---

## S-12 Mondai — `features/mondai/presentation/screens/mondai_screen.dart`
`class MondaiScreen({required int lesson, required int no})`. Referensi: mockup 02.

**Kerangka:**
- K-1 + K-3: judul "問題 Mondai", `showGrammar: true`, `showAudioSettings: kind.isListening`, `doneRef "$L.mondai.no"`;
- `bottomBar: NumberNavBar(...)` seperti S-09.

**Susunan:**
1. **Tab nomor:** `Row` chip untuk semua `numbers`, tinggi 44, radius `md`. Nomor aktif: latar `player`, teks `onPlayer`. Nomor dengan audio diberi ikon `headphones` 16. Ketuk → `pushReplacement(sectionRoute(n,'mondai',no: x))`.
2. **Jika `kind.isListening`:** `SegmentPlayer(mondai: m, title: "CD ${cdTrack.replaceAll('CD','')} · Mondai $no")`. Saat layar dibuka: `audio.open(m.audio!)`.
3. **Gambar nomor:** jika `m.image != null` → `BookImage(m.image!)` (di bawah pemutar, sebelum contoh).
   **Kotak kata / instruksi:** jika `m.instructionJp != null` → kartu berbingkai (`border`, radius `md`, padding `Sp.x3`) berisi `JpTextView(m.instructionJp!)` (sebelum bacaan dan contoh). Dipakai untuk kotak pilihan kata dari buku (kata yang dicoret di buku ditulis dalam kurung siku ［…］) atau pertanyaan pengantar seperti "どこで　買いましたか。".
   **Bacaan:** jika `m.passageJp` tidak kosong → kartu berbingkai (`border`, radius `md`, padding `Sp.x4`): `passageTitleJp` (jika ada) sebagai `JpTextView(passageTitleJp!, textAlign: TextAlign.end)`, lalu setiap paragraf `JpTextView(p)` dengan jarak `Sp.x3` (sebelum contoh).
4. **Contoh (kartu contoh):** hanya jika `examples` tidak kosong. Label `JpLabel(labelJp)`. Isi menurut kind:

| kind | isi contoh |
|---|---|
| listen_write / fill / compose / write / choice | `linesJp` → `JpTextView` (bagian bergaris bawah = jawaban contoh) |
| listen_choice_image | `BookImage(image)` + Row chip ①②③, chip `answer` terpilih (nonaktif) |
| listen_truefalse | teks besar `answer` (○/×) |
| truefalse | jika `image != null`: seperti listen_choice_image tetapi `options` (biasanya 2) chip ①②; selain itu `JpTextView(linesJp[0])` dengan teks besar `answer` (○/×) di kirinya |
| listen_choice | Row `ChoiceChip` dari `linesJp` (label `JpLabel`); chip yang `jp`-nya sama dengan `answer` terpilih (nonaktif) |

   Jika ada segmen contoh → `SegmentPlayButton(range: m.exampleSegment(i)!.t, tag: '${m.id}#ex$i')` di kanan.
5. **Soal:** kartu daftar, satu baris per soal:
   - `SegmentPlayButton` (jika listening, segmen `m.questionSegment(i)`) + nomor "q)" + input. Baris yang segmennya sedang diputar berlatar `highlightBg`.
   - Kunci jawaban penyimpanan = `"${q.id}#k"`, dengan k = indeks blank (0 untuk input tunggal).
   - Input menurut kind:
     - **listen_write:** `KanaTextField(initial: ud.answer(key) ?? '', onChanged: (v) => ud.setAnswer(key, v), hint: S.typeAnswer)`.
     - **listen_choice_image:** `BookImage(q.image)` + Row 3 `ChoiceChip` "①②③" (nilai "1","2","3"), terpilih = jawaban tersimpan.
     - **listen_truefalse:** 2 `ChoiceChip` "○" "×".
     - **truefalse:** jika `q.image != null` → `BookImage(q.image)` + Row `q.options` `ChoiceChip` "①②…" (nilai "1","2",…; gambar atas = ①) — pilih gambar yang sesuai bacaan; selain itu `JpTextView(q.linesJp[0])` lalu 2 `ChoiceChip` "○" "×". Kunci `"${q.id}#0"`.
     - **listen_choice:** `Wrap` `ChoiceChip` dari `q.choicesJp` (label `JpLabel`, nilai `choice.jp`, kunci `"${q.id}#0"`), terpilih = jawaban tersimpan.
     - **fill / compose / write:** `linesJp` → `JpTextView(line, blankBuilder: (c,i) => KanaTextField(width: 96 (write: 220), …key "${q.id}#$i"), blankIndexOffset: <jumlah blank baris sebelumnya>)`.
     - **choice:** `linesJp` → `JpTextView`, lalu untuk setiap kelompok `g` di `q.choiceGroups`: satu baris `Wrap` `ChoiceChip` (label `JpLabel`, nilai `choice.jp`, kunci `"${q.id}#g"`), diberi label kecil "(g+1)" jika kelompok lebih dari satu.
6. **Kotak info** border (`border`, radius `md`): ikon `info` + `S.noKeyMondai`.
7. **Baris bantuan:**
   - jika AI aktif: tombol garis bertepi `secondary` "✨ Contoh jawaban AI" → `showAiPanel(AiRequest(action: exampleAnswer, lesson: n, refId: m.id, target: <soal-soal nomor ini dalam teks>, bookContext: K-4 + contoh))`;
   - tombol garis "Mondaishuu Bab n" (jika ada set) → `push('/ms/<id>')`.
8. `TextButton(S.clearAnswers)` → `ud.clearAnswers('${m.id}.')`.

---

## S-13 Tata Bahasa — `features/bunpou/presentation/screens/bunpou_screen.dart`
`class BunpouScreen({required int lesson, required int no})`. K-1: judul "Tata Bahasa", subjudul "Bab n · Poin no", `doneRef "$L.bunpou.no"`, `showModeToggle: true`, `bottomBar: NumberNavBar("Poin ${no+1}")`.

**Susunan:**
1. Kartu `secondarySubtle` padding 16: "no." (`brushNo`, `secondary`) + `JpTextView(titleRich, size small, mode kana)` + `titleNote` (`caption`).
2. `ContentBlocksView(blocks: b.blocks, showTr: true)`.
3. Jika AI aktif: Row 2 tombol garis "✨ Jelaskan lebih sederhana" (`simplerGrammar`) dan "✨ Contoh lain" (`moreExamples`). `target` = `titleRich.jp`; `bookContext` = teks semua blok (`textRich.jp` + baris contoh).

---

## S-14 Kata Referensi — `features/kosakata/presentation/screens/sankou_screen.dart`
`class SankouScreen({required int lesson})`. K-1: judul "Kata Referensi", `doneRef "$L.sankou"`. Susunan: `JpTextView(titleJp, size title)` + `Text(titleTr, secondary)` + `ContentBlocksView(blocks)`.

---

## S-15 はじめに — `features/book_extras/presentation/screens/intro_screen.dart`
`class IntroScreen` — rute `/intro`.

**Data:** `extraDocProvider('intro')`, `kanaChartProvider`.

**Susunan:** `DefaultTabController` dengan tab "Huruf" dan "Panduan".
- **Huruf:** tabel hiragana lalu katakana (komponen `KanaGrid` dari S-23).
- **Panduan:** `ExtraDoc.sections` → setiap section = judul `headline` + `ContentBlocksView`.

Jika file `intro.json` belum ada (error), tab Panduan menampilkan `ErrorView("Bagian ini belum tersedia.")`.

---

## S-16 Latihan (tab) — `features/practice_mix/presentation/screens/practice_hub_screen.dart`
`class PracticeHubScreen` — rute `/practice`.

**Susunan:**
1. Judul "Latihan" (`AppText.title`).
2. Kartu Latihan Campuran: ikon `shuffle` di tile `primarySubtle`, judul "Latihan Campuran", subjudul "Soal acak lintas bab dari Mondaishuu & Kosa Kata", chevron → `push('/mix')`.
3. Label grup "MONDAISHUU". Kartu daftar dari `manifest.mondaishuu`:
   - judul `JpLabel(titleJp)`;
   - subjudul: "Bab a–b · y soal" (jika `lessons.length > 1`) atau "Bab a · y soal";
   - trailing teks "benar terbaik: x/y" (`caption`), x = jumlah `best` dari semua latihan set itu di `msScores`;
   - → `push('/ms/<id>')`.

---

## S-17 Set Mondaishuu — `features/mondaishuu/presentation/screens/mondaishuu_set_screen.dart`
`class MondaishuuSetScreen({required String setId})` — rute `/ms/:id`.

**Susunan:**
- AppBar ← + `JpLabel(titleJp)` + subjudul "Mondaishuu".
- Kartu daftar latihan. Baris: "Latihan {no}" + subjudul "{items.length} soal" + trailing badge skor "best/total" (`successSubtle`/`success` jika best == total; selain itu `surfaceAlt`) → `push('/ms/<id>/ex/<no>')`.
- Tombol garis penuh "Lihat ringkasan" → `push('/ms/<id>/result')`.

---

## S-18 Latihan Mondaishuu — `features/mondaishuu/presentation/screens/mondaishuu_exercise_screen.dart`
`class MondaishuuExerciseScreen({required String setId, required int exNo, bool onlyWrong = false})` — rute `/ms/:id/ex/:ex[?only=wrong]`. Alur lengkap ada di `01_Perencanaan §4.10 A`; algoritma di `06 §2`.

**State lokal** (ConsumerStatefulWidget):
- `Map<String, String> input` (kunci `"${item.id}#k"`), diawali dari `ud.answer`;
- `Map<String, BlankResult> result`;
- `Set<String> revealed`, `Set<String> markedCorrect`, `Set<String> retrying`;
- `bool checked`;
- `List<MsItem> items`: jika `onlyWrong`, hanya item dengan status wrong/assisted di `msScores[ex.id].items`; jika "acak" aktif, diacak.

**AppBar:** ← + judul `JpLabel(set.titleJp)` + subjudul "Latihan $exNo" + aksi `ModeToggle`, 📖 (`showGrammarSheet(context, set.lessons.first)`), menu ⋯ (`PopupMenuButton`) berisi "Acak urutan soal" dan `S.resetNumber`.

**Body** (`ListView` padding 16):
1. `BookImage(ex.image)` jika ada.
2. Jika `ex.options` tidak kosong: kartu `surface` berisi baris "key. " + `JpTextView(jp, size small)`; jika `usedByExample` → teks dicoret (`TextDecoration.lineThrough`, `inkSubtle`).
3. Kartu contoh (例): `linesJp` dengan `blankBuilder` yang menampilkan **jawaban** (`answersJp.first.jp` / `answer`) di kotak `highlightBg` radius 6, padding h6.
4. Satu kartu per soal (`surface`, radius `lg`, padding 12):
   - **Header:** "no)" (`bodyStrong`) + Spacer + `IconButton(AppIcons.hint, tooltip: S.showAnswer)` → masukkan item ke `revealed` (status *assisted*).
   - **Isi:** `linesJp` dengan `blankBuilder(i)` menurut `blanks[i].type`:
     - `text` → `KanaTextField(width: 110, state: …)`;
     - `sentence`, `free` → `KanaTextField(width: 200)`;
     - `choice` → `Wrap` `ChoiceChip`, label `JpLabel(choice)`, nilai = `choice.jp`;
     - `option` → `ActionChip` berlabel huruf terpilih atau "?". Ketuk → bottom sheet daftar opsi (huruf + teks). Opsi `usedByExample` dinonaktifkan.
   - **Setelah Periksa:**
     - blank benar → `FieldState.correct`; salah → `FieldState.wrong`;
     - item salah menampilkan Row tombol kecil: "↻ " + `S.tryAgain` (kosongkan input item ini dan hapus hasilnya), "💡 " + `S.showAnswer`, dan (AI aktif) "✨ Kenapa salah?" (`AiRequest(whyWrong, userAnswer: input, keyAnswer: jawaban kunci)`);
     - blank `sentence` yang salah menambah tombol `S.markCorrect` (masuk `markedCorrect`, dihitung benar);
     - jika `revealed` → teks "Jawaban: " + semua `answersJp` dipisah " ／ " (atau "Jawaban: " + huruf opsi), dengan `JpTextView` `secondary`;
     - item `free` tidak pernah merah/hijau; 💡 menampilkan `S.modelAnswer` + `answersJp`.

**Bottom bar** (`Container` `bg` + border atas, padding 16):
- **Sebelum diperiksa:** tombol penuh `S.check`, aktif jika minimal satu input terisi. Saat ditekan:
  - hitung `result` untuk semua blank (`checkBlank`);
  - status item: semua blank benar/ditandai benar → (item ada di `revealed` ? assisted : correct); jika ada yang salah → wrong; item yang semua blank-nya `free` tidak dihitung;
  - `ud.recordMsAttempt(ex.id, {item.id: status})`;
  - simpan semua input lewat `ud.setAnswer`;
  - `checked = true`.
- **Sesudah diperiksa:** teks "Skor x / y" (`headline`) + Row:
  - tombol garis `S.resetNumber` (kosongkan semua input/hasil/revealed, `checked = false`);
  - tombol utama "Latihan berikutnya" → `pushReplacement('/ms/<id>/ex/<no+1>')`; atau "Lihat ringkasan" jika ini latihan terakhir → `pushReplacement('/ms/<id>/result')`.

---

## S-19 Ringkasan Mondaishuu — `features/mondaishuu/presentation/screens/mondaishuu_result_screen.dart`
`class MondaishuuResultScreen({required String setId})`.

**Susunan:**
- Angka besar "x / y" (total `last` / total soal yang dinilai) + "Skor terbaik: b / y".
- Kartu daftar per latihan: "Latihan n" + "terakhir a/t · terbaik b/t".
- Tombol penuh `S.repeatAll`: untuk setiap latihan panggil `ud.clearAnswers('${ex.id}.')`, lalu `pushReplacement('/ms/<id>/ex/1')`.
- Tombol garis `S.repeatWrong` (hanya jika ada item wrong/assisted): `pushReplacement('/ms/<id>/ex/<latihan pertama yang punya item salah>?only=wrong')`.

---

## S-20 Latihan Campuran: atur — `features/practice_mix/presentation/screens/mix_setup_screen.dart`
`class MixSetupScreen` — rute `/mix`.

**Susunan:**
- **"Rentang bab":** `RangeSlider` 1..(bab terakhir di manifest), divisions = jumlah bab − 1, label "Bab a – b".
- **"Jenis soal":** `CheckboxListTile` "Mondaishuu" dan "Kuis kosakata" (minimal satu harus dicentang).
- **"Jumlah soal":** `SegmentedButton` 10 / 20 / 30 / "Semua".
- **"Fokus kelemahan":** `SwitchListTile` dengan subjudul "Soal yang pernah salah lebih sering muncul".
- Tombol penuh "Mulai": simpan konfigurasi ke `mixConfigProvider` (`Notifier<MixConfig?>`, dibuat di `features/practice_mix/domain/providers/mix_providers.dart`) → `push('/mix/session')`.

Pembuatan soal mengikuti `06 §7`.

---

## S-21 Latihan Campuran: sesi — `features/practice_mix/presentation/screens/mix_session_screen.dart`
`class MixSessionScreen` — rute `/mix/session`.

**Susunan:**
- AppBar ← + "Latihan Campuran" + `LinearProgressIndicator` (i / total).
- Satu soal per layar:
  - **Soal Mondaishuu:** tampilkan seperti kartu soal S-18 (dengan contoh latihan di atasnya) + tombol `S.check`. Setelah diperiksa → hasil + tombol "Berikutnya".
  - **Kuis kosakata:** `JpTextView` kata (kanji jika ada, selain itu kana, `JpSize.title`, rata tengah) + 4 tombol garis berisi arti (`tr`). Ketuk → langsung tandai benar (`success`) / salah (`danger`, arti benar ikut disorot) → tombol "Berikutnya".
- **Ringkasan di akhir:**
  - "x / y benar";
  - daftar soal salah (teks + Bab);
  - "Bab yang paling sering salah": 3 bab teratas, masing-masing dengan tombol → `push('/lesson/n')`;
  - tombol "Ulangi yang salah" (sesi baru dari soal salah) dan "Selesai" (pop).

---

## S-22 Hafalan (tab) — `features/hafalan/presentation/screens/hafalan_hub_screen.dart`
`class HafalanHubScreen` — rute `/hafalan`.

**Susunan:**
1. Judul "Hafalan".
2. **Kartu Ulasan:** angka jatuh tempo (`brushNo`) + `S.reviewToday` + tombol "Mulai ulasan" → `push('/review')`. Jika 0: tampilkan "Tidak ada kartu jatuh tempo." dan sembunyikan tombol.
3. **Kartu Hiragana:**
   - judul "Hiragana" + "x / y hafal" (`isMastered`);
   - Row tombol garis "Tabel" → `/kana/hira`, "Kartu" → `/cards/hira`, "Kuis" → `/quiz/hira`.
4. **Kartu Katakana:** sama, dengan `kata`.
5. Label "KANJI PER BAB". Kartu daftar dari `kanjiIndexProvider` dikelompokkan per `firstLesson`:
   - baris "Bab n" + "k kata · h hafal";
   - trailing tombol teks "Kartu" (`/cards/kanji-n`) dan "Kuis" (`/quiz/kanji-n`).

---

## S-23 Tabel kana — `features/hafalan/presentation/screens/kana_table_screen.dart`
`class KanaTableScreen({required String script})` — `hira` | `kata`.

**Susunan:**
- AppBar "Hiragana" / "Katakana".
- `TabBar` berisi judul tabel (`KanaTable.title`).
- Isi: `KanaGrid` — buat widget publik `KanaGrid({required KanaTable table})` di `features/hafalan/presentation/widgets/kana_grid.dart`, yang juga dipakai S-15:
  - grid jumlah kolom = panjang baris terpanjang;
  - sel null = kosong;
  - sel: kana (`AppText.brushTile` × 1.4) + romaji (`caption`, `inkMuted`) di kotak `surface` radius `md`;
  - titik kecil `success` di pojok jika kartu `"$script:kana"` `isMastered`.
- Ketuk sel → TTS kana itu.

---

## S-24 Kartu — `features/hafalan/presentation/screens/flashcard_screen.dart`
`class FlashcardScreen({required String deck})` — deck: `hira` | `kata` | `kanji-n`. Isi deck mengikuti `06 §1.2`.

**Susunan:**
- AppBar dengan judul deck + teks "i / total" + aksi `shuffle` (mengacak urutan).
- **Kartu besar** (radius `lg`, `surface`, tinggi ±50% layar):
  - **depan:** kana/kanji `AppText.brushCard`;
  - **ketuk → belakang:**
    - kana: romaji (`title`) + tombol 🔊;
    - kanji: bacaan (`jpTitle`), romaji (`body`), arti (`body`, `secondary`; "—" jika null), "Muncul di: Bab a, b" (`caption`), tombol 🔊 (`reading`).
- **Setelah dibalik:** 4 tombol berjajar `S.gradeLupa` (`danger`), `S.gradeSusah`, `S.gradeBisa`, `S.gradeMudah` (`success`) → `ud.srsReview(key, grade)` → kartu berikutnya.
- **Akhir:** "Selesai! x kartu diulas." + tombol "Ulangi" dan "Kembali".

---

## S-25 Kuis — `features/hafalan/presentation/screens/quiz_screen.dart`
`class QuizScreen({required String deck})`. Aturan di `06 §1.4`.

**Susunan:**
- Soal: depan kartu (seperti S-24) + 4 tombol garis pilihan.
- Benar → tombol hijau, lanjut otomatis setelah 700 ms.
- Salah → tombol merah + jawaban benar hijau; lanjut setelah tombol "Berikutnya". Kartu ditandai `ud.srsReview(key, SrsGrade.lupa)`.
- **Ringkasan:** "x / y benar", tombol "Ulangi", "Ulangi yang salah", "Kembali".

---

## S-26 Ulasan hari ini — `features/hafalan/presentation/screens/review_screen.dart`
`class ReviewScreen` — rute `/review`.

**Susunan:** sama dengan S-24, dengan antrian dari `06 §1.3`. Kartu yang dinilai "Lupa" dimasukkan lagi ke akhir antrian sesi. Jika antrian kosong: ikon `checkCircle` + "Semua kartu sudah diulas hari ini." + tombol "Kembali".

---

## S-27 Pencarian — `features/search/presentation/screens/search_screen.dart`
`class SearchScreen` — rute `/search`.

**Susunan:**
- AppBar dengan `TextField` (autofocus, hint `S.searchHint`, tombol × untuk mengosongkan).
- **Query kosong:** label "RIWAYAT" + `Wrap` chip `searchHistory` (ketuk → isi query) + tombol teks "Hapus riwayat".
- **Query ≥ 1 huruf:** hasil dari `06 §6`, dikelompokkan dengan label "KOSA KATA", "KALIMAT", "TATA BAHASA", "KATA REFERENSI". Baris:
  - `JpLabel` (jp) + `tr` (`bodySm`, `inkMuted`, 1 baris) + trailing "Bab n" (`caption`);
  - ketuk → `ud.addSearch(query)` lalu navigasi menurut ref (`06 §6.3`).
- **Tidak ada hasil** → `S.emptySearch`.

---

## S-28 Tersimpan — `features/bookmarks/presentation/screens/bookmarks_screen.dart`
`class BookmarksScreen` — rute `/bookmarks`.

**Susunan:**
- `Wrap` `ChoiceChip` filter: "Semua", "Kalimat", "Kosa Kata", "Tata Bahasa", "Latihan".
- Kartu daftar. Baris: `label` + `note` (`bodySm`, `secondary`, jika ada) + "Bab n" (dari ref).
  - Ketuk → navigasi `06 §6.3`.
  - Trailing `PopupMenuButton`: "Ubah catatan" (dialog `TextField` → `ud.setBookmarkNote`) dan "Hapus" (`ud.toggleBookmark`).
- Kosong → `S.emptyBookmarks`.

---

## S-29 Lainnya (tab) — `features/home/presentation/screens/more_screen.dart`
`class MoreScreen` — rute `/more`. Judul "Lainnya". Kartu daftar:
- "Pencarian" (`search`) → `/search`;
- "Tersimpan" (`star`, trailing jumlah) → `/bookmarks`;
- "Pengaturan" (`settings`) → `/settings`;
- "Tentang" (`info`): dialog berisi "Minna Pocket", "Versi data: <data_version>", "Isi dari buku Minna no Nihongo Shokyu I (3A Corporation). Untuk penggunaan pribadi.", dan lisensi font & ikon (OFL, ISC).

---

## S-30 Pengaturan — `features/settings/presentation/screens/settings_screen.dart`
`class SettingsScreen` — rute `/settings`. `ListView` dengan label grup:

- **TAMPILAN**
  - "Tema": `SegmentedButton` "Sistem" / "Terang" / "Gelap".
  - "Ukuran huruf": `SegmentedButton` "Kecil" (0.9) / "Normal" (1.0) / "Besar" (1.15) / "Sangat besar" (1.3), dengan pratinjau `JpTextView` kalimat Bunkei 1 bab 1.
  - "Mode teks bawaan": あ / Ro.
  - "Tampilkan terjemahan otomatis" (switch `showTranslation`).
- **AUDIO** — isi sama dengan `showAudioSettingsSheet` (kecepatan, jeda otomatis, ulangi otomatis, gulir otomatis).
- **SUARA PENGUCAPAN 🔊**
  - "Kecepatan bicara": `Slider` 0.3–0.6.
  - Tile "Cek suara Jepang" → jika tersedia: SnackBar "Suara Jepang tersedia."; jika tidak: dialog "Suara Jepang belum terpasang. Buka Pengaturan Android → Bahasa & input → Output text-to-speech, lalu pasang data suara Jepang."
- **HAFALAN** — "Kartu baru per hari": 5 / 10 / 20.
- **AI** — tile "Penjelasan AI" dengan subjudul "<Penyedia> · aktif" atau "Belum diatur" → `/settings/ai`.
- **DATA**
  - "Backup sekarang" → `FilePicker.platform.saveFile(fileName: 'minna_pocket_backup_YYYYMMDD.json', bytes: utf8.encode(ud.exportBackupJson()))` → SnackBar "Backup tersimpan.".
  - "Pulihkan dari backup" → konfirmasi "Data saat ini akan diganti. Lanjutkan?" → `pickFiles(type: custom, allowedExtensions: ['json'], withData: true)` → `ud.importBackupJson(utf8.decode(bytes))` → SnackBar "Data dipulihkan." (`FormatException` → SnackBar dengan pesannya).
  - "Tandaan salah ketik (n)" → `/settings/flags`.
  - "Hapus cache AI" → `aiCacheProvider.clear()`.
  - "Hapus semua data" (`danger`) → konfirmasi → `ud.resetAll()`.
- **PANDUAN** — "Tampilkan panduan awal" → `go('/onboarding')`.

---

## S-31 Pengaturan AI — `features/ai_assist/presentation/screens/ai_settings_screen.dart`
`class AiSettingsScreen` — rute `/settings/ai`.

**Susunan:**
- **"Penyedia":** `SegmentedButton<AiProvider>` "Claude" / "Gemini" / "OpenAI".
- **"Model":** `TextField`, hint = `kDefaultModels[provider]`, disimpan ke `settings.aiModel` saat Simpan.
- **"API key":** `TextField(obscureText)` dengan ikon mata; nilai awal dari `aiKeyStore.read(provider)`.
- **Tombol:**
  - penuh "Simpan" → `aiKeyStore.write` + `aiKeyVersionProvider.notifier.bump()` + `settings.update(aiProvider, aiModel)` + SnackBar "Tersimpan.";
  - garis "Tes koneksi" → `AiClient().stream(... system: 'Jawab singkat.', messages: [AiMessage('user','Balas dengan satu kata: OK')])` → sukses: SnackBar "Koneksi berhasil."; `AiException`: SnackBar dengan pesannya;
  - teks `danger` "Hapus key".
- **Teks info** (`bodySm`, `inkMuted`): "Key disimpan terenkripsi di HP ini dan tidak ikut backup. Biaya pemakaian ditagih ke akun API milikmu. Jawaban AI selalu diberi label dan bisa keliru."

---

## S-32 Tandaan salah ketik — `features/settings/presentation/screens/flags_screen.dart`
`class FlagsScreen` — rute `/settings/flags`.

**Susunan:**
- Daftar `flags`: teks (`jpSm`), catatan, ref, tanggal.
- Tombol penuh "Ekspor" → `saveFile(fileName: 'minna_pocket_tandaan_YYYYMMDD.json', bytes: utf8.encode(ud.exportFlagsJson()))`.
- Tombol teks `danger` "Hapus semua" (dengan konfirmasi).
- Kosong → "Belum ada tandaan."
