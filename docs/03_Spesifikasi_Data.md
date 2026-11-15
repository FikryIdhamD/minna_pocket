# 03 — Spesifikasi Data

> Kontrak data antara **data konten** (disiapkan perencana) dan **aplikasi Flutter** (dibangun AI eksekutor).
> Sumber kebenaran formal: `schema/lesson.schema.json` dan `schema/mondaishuu.schema.json`.
> Model Dart yang membaca data ini **sudah disediakan lengkap** di `lib/shared/domain/models/` dan **tidak boleh diubah** oleh AI eksekutor.

---

## 1. Alur
```
PDF scan + CD ──(OCR & transkripsi manual)──► content-src/book1/*.json   (format penulisan, markup)
                                               │
                     tools/build_data.py ◄─────┘   + audio_raw.json (tools/audio_prepare.py)
                                               │   + crops.json      (tools/crop_images.py)
                                               ▼
                                     assets/book1/  (dibaca aplikasi)
                                               │
                     tools/validate.py ────────┘   (wajib lulus sebelum build APK)
```
Perintah lengkap (dijalankan dari folder `Minna Pocket/`):
```
python3 tools/audio_prepare.py "<folder MP3 CD>" assets/book1/audio content-src/book1/audio_raw.json
python3 tools/crop_images.py book1 "<main.pdf>" "<terjemahan.pdf>" "<mondaishuu.pdf>"
python3 tools/build_data.py book1
python3 tools/validate.py book1
```
Kebutuhan Python: `pip install fugashi unidic-lite jsonschema pillow`; program `ffmpeg`, `ffprobe`, `pdftoppm`.

> **AI eksekutor tidak menjalankan perintah di atas** kecuali task di `02_Rencana_Eksekusi.md` memintanya. Folder `assets/book1/` sudah terisi.

---

## 2. JpText (teks Jepang)

### 2.1 Markup di `content-src`
| Markup | Arti |
|---|---|
| `{漢字|かな}` | Kata berkanji + furigana persis dari buku |
| `[[teks]]` | Bergaris bawah (bagian pengganti di Renshuu C, angka bergaris di Mondaishuu) |
| `＿` | Tempat kosong (isian) |
| `　` (spasi lebar) | Spasi antar-frasa seperti di buku, **dipertahankan** |

Field yang mengandung markup: kunci `jp`, kunci berakhiran `_jp`, dan kunci berakhiran `_rich` (teks Indonesia bercampur Jepang, mis. penjelasan Tata Bahasa).

### 2.2 Bentuk terkompilasi (di `assets/`)
```json
{ "jp": "アメリカから　来ました。",
  "tokens": [
    { "s": "アメリカから", "ro": "Amerika kara" },
    { "s": "　", "ro": " " },
    { "s": "来", "r": "き", "ro": " ki", "k": true },
    { "s": "ました。", "ro": "mashita." } ] }
```
| Kunci token | Arti |
|---|---|
| `s` | teks tampil |
| `r` | bacaan (hanya token kanji) |
| `ro` | romaji token (spasi/tanda hubung di depan sudah disertakan) |
| `k` | `true` = token kanji → bisa ditekan, furigana muncul |
| `u` | `true` = garis bawah |
| `blank` | `true` = tempat kosong |

**Aturan tampil:**
- Mode あ: tampilkan `s` setiap token berurutan. Token `k` diberi ruby (furigana `r`) yang **tersembunyi** sampai ditekan.
- Mode Ro: baris utama = gabungan `ro` (rapikan spasi). Baris kecil di bawahnya = gabungan `s`. Token `k` diberi garis bawah titik-titik di **kedua** baris. Menekan satu token menyorot pasangannya (indeks token sama).
- `JpText.romaji` dan `JpText.reading` (untuk TTS) sudah tersedia di model.

Romaji dibuat otomatis:
- Sistem Hepburn; vokal panjang ditulis apa adanya (おう→ou, ー→vokal diulang).
- Partikel は/へ/を → wa/e/o.
- Spasi antar kata memakai MeCab (unidic-lite).
- Huruf kapital di awal kalimat.

---

## 3. File bab — `assets/book1/lessons/Lxx.json`

Struktur tingkat atas: `book`, `lesson`, `id` (`"L01"`), `title_jp`, `title_tr`, `sections`. Bagian yang **tidak ada** di suatu bab tidak muncul di `sections`, dan kartunya tidak ditampilkan.

| Kunci `sections` | Isi | Model Dart |
|---|---|---|
| `kosakata` | `groups[]` → `items[]` {`id`, `kana_jp`, `kanji_jp`?, `tr`}. Grup bisa berlabel (`label_jp`, mis. 〈練習C〉) atau `separator: true` (garis putus-putus tanpa label) | `Kosakata` |
| `bunkei` | `[]` {`id`, `no`, `jp`, `variants_jp`?, `tr`} — `variants_jp` = teks kecil di bawah kalimat, mis. （では） | `Bunkei` |
| `reibun` | `[]` {`id`, `no`, `lines[]` {`id`, `jp`, `tr`}} — baris jawaban diawali `……` | `Reibun` |
| `kaiwa` | `title_jp`, `title_tr`, `image`, `audio`, `duration`, `timing`, `lines[]` {`id`, `speaker_jp`, `speaker_tr`, `turn_start`, `break_before`? (pemisah adegan), `jp`, `tr`, `t`[mulai, selesai]} | `Kaiwa` |
| `renshuu_a` | `[]` {`id`, `no`, `lines[][]` segmen}. Segmen = `{text_jp, variants_jp?}` **atau** `{slot: [box…]}`; box = `{opts_jp[], hl: normal|strong|none}`. Kotak-kotak dalam satu slot ditumpuk vertikal; opsi dalam satu kotak juga ditumpuk vertikal | `RenshuuA` |
| `renshuu_b` | `figures[]` {`id`, `image`} + `items[]` {`id`, `no`, `figure`?, `examples[]` {`prompt_jp`?, `answer_jp[]`}, `questions[]` {`id`, `no`, `prompt_jp`?}}. `prompt_jp` null = soal mengacu ke gambar | `RenshuuB` |
| `renshuu_c` | `[]` {`id`, `no`, `image`, `dialog[]` (DialogLine; bagian `u` = yang diganti), `substitutions[]` {`no`, `image`}} | `RenshuuC` |
| `mondai` | `[]` {`id`, `no`, `kind`, `audio`?, `image`? (gambar seluruh nomor), `instruction_jp`? (kotak kata dari buku / pertanyaan pengantar), `passage_title_jp`?, `passage_jp`? (bacaan; boleh di kind apa pun, mis. `truefalse` atau `choice`), `segments[]` {`label`, `t`}, `examples[]` (boleh kosong), `questions[]`} | `Mondai` |
| `bunpou` | `[]` {`id`, `no`, `title_rich`, `title_note`?, `blocks[]`} — blok: `h` (subjudul), `p` (paragraf), `note` ([Perhatian]), `ex` (contoh bernomor ①…, `lines[]`), `table`, `image` | `Bunpou` |
| `sankou` | `title_jp`, `title_tr`, `blocks[]` (biasanya satu `table`; sel = daftar {`jp`, `tr`}) | `Sankou` |

### 3.1 Jenis Mondai (`kind`)
| kind | Tampilan | Jawaban |
|---|---|---|
| `listen_write` | Audio + kotak ketik per soal | disimpan, tidak dikoreksi |
| `listen_choice_image` | Audio + gambar baris pilihan ①②③ + tombol ①②③ | disimpan, tidak dikoreksi (contoh punya `answer`) |
| `listen_truefalse` | Audio + tombol ○ / × per soal | disimpan, tidak dikoreksi |
| `listen_choice` | Audio + pilihan teks `choices_jp` per soal (contoh: pilihan di `lines_jp`, terpilih = `answer`) | disimpan, tidak dikoreksi |
| `fill` | Baris dengan `＿` → kotak isian di dalam kalimat | disimpan, tidak dikoreksi |
| `compose` | Beberapa baris dengan `＿` (mis. perkenalan diri) | disimpan, tidak dikoreksi |
| `choice` | Kalimat dengan pilihan dalam kurung + chip per kelompok (`choice_groups_jp`, atau `choices_jp` = satu kelompok) | disimpan, tidak dikoreksi |
| `write` | Menyusun kata (…／…／… → ＿) — kotak isian lebar | disimpan, tidak dikoreksi |
| `truefalse` | Bacaan (`passage_title_jp`?, `passage_jp[]` paragraf) + tombol ○ / × per soal (`lines_jp`), atau per soal `image` + `options` (pilih gambar ①②; gambar atas = ①); contoh: `lines_jp`/`image` + `answer` | disimpan, tidak dikoreksi |

**Segmen audio Mondai:** urutannya **semua contoh dulu, lalu semua soal**. Gunakan `Mondai.exampleSegment(i)` dan `Mondai.questionSegment(i)`.

### 3.2 ID tetap
| Pola | Contoh |
|---|---|
| `Lxx.kosakata.n` (urut lintas grup) | `L01.kosakata.10` |
| `Lxx.bunkei.no`, `Lxx.reibun.no`, `Lxx.reibun.no.baris` | `L01.reibun.5.3` |
| `Lxx.kaiwa`, `Lxx.kaiwa.baris` | `L01.kaiwa.6` |
| `Lxx.renshuu_a.no`, `Lxx.renshuu_b.no`, `Lxx.renshuu_b.no.soal`, `Lxx.renshuu_c.no` | `L01.renshuu_b.4.2` |
| `Lxx.mondai.no`, `Lxx.mondai.no.soal` (soal tanpa nomor = `.0`) | `L01.mondai.6.0` |
| `Lxx.bunpou.no`, `Lxx.sankou` | `L01.bunpou.3` |
| `MSxx.latihan`, `MSxx.latihan.soal` | `MS01.6.3` |

ID dipakai untuk progres, tersimpan, jawaban, tandaan 🚩, dan cache AI.

---

## 4. Mondaishuu — `assets/book1/mondaishuu/MSxx.json`
- `id` (`MS01` = 第1・2課), `kind` (`lesson` | `review` | `fukushuu` | `matome`; dua terakhir hanya di folder `fukushuu/`), `lessons[]`, `title_jp`, `exercises[]`.
- Latihan: `id`, `no`, `image`?, `options[]`? (pilihan berhuruf a, b, c…; `used_by_example` = dicoret di buku), `example`? (`lines_jp` + `blanks`, ditampilkan **sudah terisi**), `items[]`.
- Soal: `id`, `no`, `lines_jp[]` (token `blank` berurutan = `blanks[]` berurutan), `blanks[]`.

| `blanks[].type` | Input | Koreksi |
|---|---|---|
| `text` | kotak ketik pendek di dalam kalimat | otomatis (06_Algoritma §2) |
| `sentence` | kotak ketik panjang | otomatis; bila salah ada tombol **Anggap benar** |
| `choice` | chip pilihan dari `choices_jp` di posisi kosong | otomatis |
| `option` | chip huruf dari `options` latihan | otomatis (`answer` = huruf) |
| `free` | kotak ketik panjang | **tidak** dikoreksi; tombol 💡 menampilkan contoh dari buku |

`answers_jp` = semua jawaban yang diterima menurut 解答 (dipisah ／ di buku).

---

## 5. Manifest & indeks
**`manifest.json`:**
- `book`, `data_version`, `title`.
- `lessons[]` (`LessonMeta`: judul + `sections[]` `SectionMeta` dengan `count`, `numbers`, `audio_numbers`, `audio`, `duration`).
- `mondaishuu[]` (`MondaishuuMeta`).
- `sequence[]`: urutan daftar di Beranda, `{type: lesson|fukushuu|matome, lesson?, id?}`.

**`kanji_index.json`:**
- `[]` {`word`, `readings[]`, `meaning`?, `first_lesson`, `occurrences[]` {`lesson`, `section`, `ref`}}.
- `meaning` diambil dari Kosa Kata bab mana pun yang memuat kata itu (null jika tidak ada).

**`search_index.json`:**
- `[]` {`type`: kosakata | kalimat | tata_bahasa | referensi, `ref`, `lesson`, `jp`, `kana` (hiragana), `ro` (romaji huruf kecil), `tr`}.

---

## 6. Data pengguna — `<dokumen aplikasi>/user_data.json`
Model: `UserData` (`lib/shared/domain/models/user_data.dart`). Disimpan utuh (tulis ke file sementara lalu `rename`) setiap kali berubah, dengan jeda (debounce) 500 ms.

| Kunci | Isi |
|---|---|
| `last_opened` | {route, label, at} — untuk tombol Lanjutkan |
| `done` | daftar ref selesai (`L01.kaiwa`, `L01.renshuu_b.4`, `L01.bunpou.2`, `L01.kosakata`, …) |
| `ms_scores` | per latihan Mondaishuu: best, last, total, attempts, status per soal |
| `answers` | jawaban yang diketik: kunci `<idSoal>#<indeksBlank>` |
| `srs` | kartu hafalan: kunci `hira:あ`, `kata:ア`, `kanji:会社員` |
| `bookmarks`, `flags`, `search_history`, `onboarding_done`, `last_backup_at` | sesuai nama |

File terpisah:
- `ai_cache.json`: {kunci → {provider, model, at, text}}.
- Pengaturan: `shared_preferences`.
- API key: `flutter_secure_storage` (**tidak** pernah masuk backup).

**Backup** = salinan `user_data.json` (+ `ai_cache.json` opsional) dibungkus satu file `minna_pocket_backup_YYYYMMDD.json`:
```json
{ "app": "minna_pocket", "book": 1, "created_at": "...", "user_data": { ... } }
```

---

## 7. Aset media
- **Gambar**: `assets/book1/img/<Lxx|MSxx>/<nama>.webp`, grayscale lossless, lebar ≤ 900 px. Tampilkan dengan `Image.asset`, `fit: BoxFit.contain`, latar `surface` putih. Di mode gelap, gambar **tetap** di atas kartu putih (tidak diinversi).
- **Audio**: `assets/book1/audio/Lxx_kaiwa.m4a`, `Lxx_mondaiN.m4a` (AAC mono 64 kbps).
- **Waktu audio** `t` bertanda `timing: "auto"`: hasil deteksi otomatis. Kesalahan dilaporkan lewat 🚩 dan diperbaiki di `content-src/book1/audio_overrides.json`.
- Path di JSON **relatif** terhadap `assets/book1/`. Path aset Flutter = `'assets/book1/' + path`.

---

## 8. Status produksi data (diperbarui perencana)
| Bagian | Status |
|---|---|
| Bab 1 | ✅ lengkap (teks, gambar, audio + waktu) |
| Bab 2 | ✅ lengkap |
| Bab 3 | ✅ lengkap |
| Bab 4 | ✅ lengkap |
| Bab 5 | ✅ lengkap |
| Bab 6 | ✅ lengkap |
| Bab 7 | ✅ lengkap |
| Bab 8 | ✅ lengkap |
| Bab 9 | ✅ lengkap |
| Bab 10 | ✅ lengkap |
| Bab 11 | ✅ lengkap |
| Bab 12 | ✅ lengkap |
| Bab 13 | ✅ lengkap |
| Bab 14 | ✅ lengkap |
| Bab 15 | ✅ lengkap |
| Bab 16 | ✅ lengkap |
| Bab 17 | ✅ lengkap |
| Bab 18 | ✅ lengkap |
| Bab 19 | ✅ lengkap |
| Bab 20 | ✅ lengkap |
| Bab 21 | ✅ lengkap |
| Bab 22 | ✅ lengkap |
| Bab 23 | ✅ lengkap |
| Bab 24 | ✅ lengkap |
| Bab 25 | ✅ lengkap (termasuk Kolom 1: Topik dan Subjek sebagai bunpou 6) |
| Mondaishuu 第1〜25課 (MS01–MS24) + 復習 1〜8/9〜17/18〜25/1〜25課 (MSR1–MSR4) | ✅ 28 set lengkap + kunci |
| Mondaishuu: kind review (`MSR*`) memakai `lessons[]` rentang bab | ✅ |
| Tabel kana (extras/kana.json), Cara Penggunaan Efektif (extras/howto.json) | ✅ |
| はじめに/intro (extras/intro.json: Cara Penggunaan, Ciri Khas & Aksara, Ucapan, Ungkapan Kelas & Salam, Kata Petunjuk), 復習 A–G + 総復習 + まとめ I/II buku utama (`content-src/book1/fukushuu/` → `assets/book1/fukushuu/`, id FA–FG, FS, M1, M2; format = skema Mondaishuu, `kind` = fukushuu/matome; urutan buku di `content-src/book1/sequence.json`; manifest `fukushuu[]`) | ✅ lengkap + kunci (hal. PDF buku utama: A 53–54, B 87–88, C 129–130, M1 131–132, D 165–166, E 191–192, F 217–218, G 243–244, M2 245–246, 総復習 247–250; kunci hal. 327–330) |
| Audio 87 trek (Kaiwa & Mondai bab 1–25) | ✅ terkompresi di assets/book1/audio |

Pemotongan audio Mondai otomatis memilih metode yang durasi soalnya paling seragam: (a) penanda ucapan nomor soal, atau (b) jeda terpanjang. Koreksi manual bisa dilakukan lewat `content-src/book1/audio_overrides.json`.


### Catatan: set 復習 / まとめ (fukushuu/)
- Folder `content-src/book1/fukushuu/*.json` memakai skema `mondaishuu.schema.json` (id `FA`–`FG`, `FS` = 総復習, `M1`/`M2` = まとめ I/II; `kind` = `fukushuu` atau `matome`). Pencocokan jumlah `＿` dengan `blanks[]` dan penetapan ID (`FA.1.1`) sama dengan Mondaishuu.
- Item boleh punya `image` sendiri (gambar per butir). Butir percakapan tulis-bebas (まとめ I no.3) memakai blank `free` (kunci buku sebagai contoh, tidak dinilai otomatis).
- Pemetaan bab: A=1–3, B=4–7, C=8–12, M1=1–14, D=13–16, E=17–19, F=20–22, G=23–25, M2 dan 総復習=1–25.
- Urutan tampilan: `content-src/book1/sequence.json` (lesson/fukushuu/matome). Baris di S-02 membuka `/ms/<id>` (layar set latihan Mondaishuu dipakai ulang; `BookManifest.setMeta(id)` mencari di `mondaishuu[]` dan `fukushuu[]`). `manifest.sequence` untuk fukushuu/matome diperkaya build dengan `title_jp` dan `subtitle`.
