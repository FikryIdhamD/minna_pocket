# Minna Pocket — Perencanaan Aplikasi

> Dokumen 1 dari 2. Isinya **apa** yang dibangun dan **bagaimana bentuknya**. Langkah kerja, urutan, dan jadwal ada di dokumen 2 (Rencana Eksekusi).
>
> Versi: 1.1 · Tanggal: 11 November 2026 · Status: **DIBEKUKAN** (disetujui pemilik; perubahan hanya lewat catatan revisi di §13)

---

## 1. Ringkasan

**Minna Pocket** adalah aplikasi Android (Flutter) untuk penggunaan pribadi yang menggantikan buku fisik *Minna no Nihongo Shokyu I (2nd ed.)*, supaya tidak perlu membawa buku ke mana-mana.

**Prinsip utama:**
1. **100% isi dari buku.** Tidak ada materi, soal, terjemahan, atau penjelasan yang dikarang sendiri. Yang ditambahkan aplikasi hanya hal-hal **turunan otomatis** dari isi buku:
   - romaji (konversi dari kana buku)
   - indeks kanji (kumpulan furigana buku)
   - penanda waktu audio

   Pengecualian: **fitur AI opsional** (§4.11), yang tampil terpisah dan berlabel jelas "bukan dari buku".
2. **Template + data.** Setiap jenis bagian (Bunkei, Kaiwa, Renshuu, dst.) punya satu template layar. Isi tiap bab hanyalah data (JSON) yang dibaca template.
3. **Offline penuh, tanpa backend.** Semua data, gambar, dan audio dibundel di dalam APK. Hanya fitur AI opsional yang butuh internet, dan itu pun memanggil penyedia AI langsung dengan API key milik pengguna.
4. **Satu buku, satu aplikasi.** *Minna Pocket I* (bab 1–25) dibuat sekarang. *Minna Pocket II* (bab 26–50) menyusul memakai kode yang sama (lihat §10).
5. **UI bersih, tidak terasa seperti buku.** Materi dipecah per bagian dan per nomor, tidak ditumpuk dalam satu halaman panjang.

---

## 2. Sumber materi

| Sumber | Halaman | Isi yang dipakai |
|---|---|---|
| Minna no Nihongo I – 本冊 (buku utama) | 331 (scan) | はじめに, 文型, 例文, 会話, 練習A/B/C, 問題, 復習A–H, まとめ, lampiran |
| Terjemahan & Keterangan Tata Bahasa (Indonesia) | 199 (scan) | Kosa Kata, Terjemahan (Pola Kalimat, Contoh Kalimat, Percakapan), Kata Referensi & Informasi, Keterangan Tata Bahasa, Introduksi (huruf, pelafalan) |
| Standard Workbook – 標準問題集 (Mondaishuu) | 86 (scan) | Latihan per bab (1・2 digabung), 復習 (1–8, 9–17, 18–25, 1–25), **解答 (kunci jawaban)** |
| CD audio | 87 file MP3, ±72 menit, 165 MB | Kaiwa dan Mondai untuk bab 1–25 |

Semua PDF berupa **gambar scan** (tanpa lapisan teks), jadi isinya harus di-OCR.

### 2.1 Batasan bawaan dari sumber
- Renshuu A/B/C dan Mondai di buku utama **tidak punya kunci jawaban**. Soal ditampilkan bersama contohnya (例) tanpa koreksi otomatis.
- Soal dengar di Mondai **tidak punya transkrip**. Yang ditampilkan hanya audio dan soal.
- Renshuu **tidak punya audio**. Audio hanya ada untuk Kaiwa dan Mondai.
- Furigana di buku ditulis **per kata**, bukan per huruf kanji. Bacaan yang ditampilkan juga per kata.
- Arti kanji hanya tersedia **per kata** (dari Kosa Kata). Arti satu huruf kanji tidak ada di buku.

---

## 3. Struktur menu dan navigasi

### 3.1 Peta aplikasi

```
Beranda
├── [Lanjutkan] → halaman terakhir yang dibuka
├── [Ulasan hari ini] → kartu hafalan yang jatuh tempo (§4.6)
├── 🔎 Pencarian (§4.15)
├── ⭐ Tersimpan (§4.16)
├── Progres keseluruhan (%)
├── はじめに / Introduksi          (huruf, pelafalan, ungkapan kelas, salam, angka)
├── Bab 1 … Bab 25                 (復習 A–H dan まとめ disisipkan sesuai posisi di daftar isi buku)
├── Mondaishuu                     (menu terpisah)
├── Latihan Campuran               (soal acak lintas bab, §4.14)
├── Hafalan                        (hiragana, katakana, kanji)
└── Settings
```

### 3.2 Alur di dalam bab

```
Bab N
 └── Daftar subtitle (hanya yang ada di bab itu)
      ├── Subtitle satu jenis  ──────────────→ langsung ke konten
      └── Subtitle beberapa jenis ─→ pilih nomor/jenis ─→ konten
```

| Subtitle | Sumber | Langsung / pilih dulu | Isi layar |
|---|---|---|---|
| Kosa Kata | Terjemahan §I | Langsung | Daftar kata: kanji, bacaan, arti |
| 文型 Bunkei | Utama | Langsung | Pola kalimat + terjemahan (bisa disembunyikan) |
| 例文 Reibun | Utama | Langsung | Pasangan tanya-jawab + terjemahan |
| 会話 Kaiwa | Utama | Langsung | Judul, ilustrasi, dialog, audio, terjemahan |
| 練習A Renshuu A | Utama | Pilih nomor | Satu tabel substitusi per layar |
| 練習B Renshuu B | Utama | Pilih nomor | Satu nomor per layar: 例 di atas, soal di bawah |
| 練習C Renshuu C | Utama | Pilih nomor | Satu dialog latihan per layar + ilustrasi |
| 問題 Mondai | Utama | Pilih nomor | Satu nomor per layar, soal dengar dengan audio |
| Tata Bahasa | Terjemahan §IV | Pilih poin | Satu poin tata bahasa per layar |
| Kata Referensi | Terjemahan §III | Langsung | Daftar/tabel kosakata tematik |

Layar konten punya tombol **‹ Sebelumnya / Berikutnya ›** antar-nomor, jadi tidak perlu kembali ke daftar.

### 3.3 Mondaishuu
Beranda → Mondaishuu → daftar (第1・2課, 第3課, …, 復習) → pilih nomor latihan → kerjakan → koreksi.

### 3.4 Hafalan
Beranda → Hafalan → Hiragana / Katakana / Kanji (per bab) → mode **Tabel**, **Kartu** (flashcard), atau **Kuis**.

---

## 4. Fitur

### 4.1 Kanji yang bisa ditekan
- Kanji tampil **tanpa furigana**.
- Ditekan sekali: furigana muncul di atas kata dan latarnya disorot salem. Ditekan lagi: furigana hilang.
- Bacaan diambil dari furigana buku **pada posisi itu**, jadi selalu sesuai konteks (日 bisa ひ / にち / び / か).
- Tekan lama: muncul panel kecil berisi bacaan, arti (kalau kata itu ada di Kosa Kata), dan "muncul juga di bab …".

### 4.2 Mode romaji (tombol geser あ | Ro)
- Satu tombol geser **あ | Ro** di top bar. Tidak memakai ikon 🔍, karena ikon itu dipakai untuk Pencarian. Pilihan mode diingat untuk seluruh aplikasi.
- **Mode romaji:** baris utama tampil dalam romaji (Hepburn: し=shi, つ=tsu, partikel は/へ/を = wa/e/o). Di bawahnya teks Jepang asli tampil kecil dan abu-abu.
- Kata yang berasal dari kanji diberi **garis bawah titik-titik** di kedua baris. Menekan salah satunya ikut menyorot pasangannya.
- Romaji diberi spasi per kata. Pemenggalannya dihitung saat data dibangun (bukan di HP).

### 4.3 Audio
- **Di dekat konten hanya ada ▶︎/⏸ dan bar progres**, ditambah label kecepatan aktif (mis. `0.75×`). Menekan label ini mengganti kecepatan global (0.75× ↔ 1×).
- **Pengaturan global** lewat ikon 🎧 di top bar (hanya di layar yang punya audio): kecepatan, ulang otomatis, auto-scroll Kaiwa. Berlaku untuk semua audio.
- **Mondai (audio per soal):**
  - CD menyediakan **satu file per nomor** berisi 例 + semua soal. File dibagi menjadi **segmen per soal** berdasarkan deteksi jeda suara saat build data. Contoh: Mondai 1 Bab 1 = 例 + 5 soal; Mondai 3 = 例1, 例2 + 3 soal.
  - Di atas nomor ada pemutar dengan bar bersegmen (`例 · 1 · 2 · …`, lebar sebanding durasi). Segmen bisa ditekan untuk lompat.
  - Setiap soal punya tombol ▶ sendiri yang memutar segmen soal itu saja.
  - **Jeda otomatis** (pengaturan global di 🎧, default aktif): audio berhenti di akhir tiap segmen.
  - Tombol 🔁 mengulang segmen yang sedang diputar.
  - Tab nomor di atas layar Mondai; nomor yang punya audio diberi ikon 🎧.
- **Kaiwa:**
  - Pemutar menempel di bawah layar (mini player).
  - Baris yang sedang diucapkan menyala.
  - Tekan satu baris: audio diputar dari baris itu.
  - Tekan lama satu baris: baris itu diulang terus (untuk shadowing) sampai ditekan lagi.
- Audio dikompres ke AAC mono ±64 kbps (±35 MB total).

### 4.4 Terjemahan
- Di Bunkei, Reibun, dan Kaiwa, terjemahan Indonesia dari buku terjemahan disembunyikan secara default.
- Tombol "Tampilkan terjemahan" ada per baris dan untuk semua baris sekaligus.

### 4.5 Mondaishuu interaktif
- **Pilihan ganda / isian singkat:** dikoreksi otomatis dari 解答. Bisa menerima beberapa variasi jawaban yang tertulis di kunci.
- **Jawaban kalimat panjang:** mode "cek sendiri". Anda menulis jawaban, lalu kunci ditampilkan berdampingan dan Anda menandai benar/salah.
- Skor per latihan. Yang disimpan skor terbaik dan skor terakhir.

Alur pengerjaan, coba lagi, lihat jawaban, dan mengulang dijelaskan di §4.10.

### 4.6 Hafalan
- **Hiragana dan katakana:** dari tabel di はじめに / Introduksi.
- **Kanji:** semua kata berkanji yang muncul di bab 1–25, dikelompokkan per bab pertama kemunculannya. Bacaan dari furigana buku, arti dari Kosa Kata.
- **Mode belajar:**
  - **Kartu:** depan berisi huruf/kanji, belakang berisi bacaan, romaji, dan arti. Tandai *Hafal* atau *Belum*.
  - **Kuis:** pilihan ganda. Pilihan salah diambil dari isi bab yang sama.
  - **Ulasan hari ini (spaced repetition):**
    - Setiap kartu punya jadwal ulang. Setelah ditunjukkan, pengguna menilai diri: **Lupa / Susah / Bisa / Mudah**.
    - Kartu yang lupa muncul lagi di sesi yang sama. Kartu yang bisa dijadwalkan ulang makin jarang (mis. 1 → 3 → 7 → 16 hari …).
    - Algoritma ringan bergaya SM-2, dihitung lokal di HP.
    - Kartu baru masuk antrian bertahap, dengan batas kartu baru per hari yang bisa diatur di Settings (default 10).
    - Beranda menampilkan jumlah kartu jatuh tempo.
- Setiap kartu punya tombol 🔊 (§4.12).
- **Tidak ada latihan menulis / urutan goresan**. Fokusnya mengenali dan memahami, dan data urutan goresan tidak ada di buku.

### 4.7 Progres
| Jenis | Kapan dianggap selesai |
|---|---|
| Materi (Kosa Kata, Bunkei, Reibun, Kaiwa, Tata Bahasa, Kata Referensi) | Otomatis saat sampai akhir halaman; bisa dicentang/dibatalkan manual |
| Renshuu A/B/C, Mondai | Per nomor yang sudah dibuka sampai akhir |
| Mondaishuu | Skor per latihan |
| Hafalan | Jumlah kartu "Hafal" / total |

**Tampilan progres:**
- Beranda: tombol **Lanjutkan** dan % keseluruhan.
- Daftar bab: lingkaran progres per bab.
- Kartu subtitle: centang kalau sudah selesai.

**Tanpa gamifikasi:** tidak ada poin, streak, atau lencana.

### 4.8 Laporan salah OCR (🚩)
- Tekan lama teks → **Tandai salah**. Tandaan tersimpan lokal.
- Di Settings ada **Ekspor tandaan** (file JSON) untuk dikirim dan diperbaiki di update berikutnya.

### 4.9 Settings
- Tema: terang / gelap / ikut sistem
- Ukuran huruf
- Mode romaji default
- Terjemahan default (tampil / sembunyi)
- Audio: kecepatan, ulang otomatis, auto-scroll
- Backup / Restore progres (file)
- Ekspor tandaan 🚩
- AI: penyedia, model, API key, hapus cache penjelasan (§4.11)
- Suara 🔊: kecepatan bicara, cek paket suara Jepang (§4.12)
- Hafalan: batas kartu baru per hari
- Tampilkan ulang panduan awal (§4.13)
- Tentang aplikasi

### 4.10 Alur latihan

Prinsipnya: latihan **selalu bisa diulang**, dan saat buntu **selalu ada bantuan**, tapi bantuan itu hanya memakai isi buku.

#### A. Mondaishuu (ada kunci jawaban → dikoreksi)
1. Pilih latihan (mis. 第3課), lalu pilih nomor.
2. **Layar nomor** berisi instruksi dan **例 yang sudah terisi** (diberi warna sebagai contoh). Di bawahnya semua soal nomor itu:
   - **Pilihan ganda**: tekan salah satu pilihan.
   - **Isian**: ketik di kotak. Ketikan romaji otomatis menjadi kana (`desu` → です), jadi keyboard Jepang tidak wajib. Jawaban kana diterima walau kuncinya kanji (dicocokkan lewat bacaan di indeks kanji).
   - **Kalimat**: ketik bebas.
3. **Periksa**:
   - Benar diberi ✓ hijau.
   - Salah diberi ✗ merah, **tanpa langsung membuka jawaban**. Soal yang salah punya dua tombol:
     - **↻ Coba lagi**: hanya kotak itu yang dikosongkan; soal ✓ tidak terganggu.
     - **💡 Lihat jawaban**: membuka jawaban 解答 untuk soal itu saja.
   - Jawaban kalimat: kunci ditampilkan berdampingan, lalu pengguna menandai sendiri benar/salah.
4. **💡 tersedia di setiap soal sejak awal**, jadi bisa dipakai saat buntu sebelum menjawab. Soal yang jawabannya dibuka diberi tanda **"dibantu"** dan tidak dihitung benar di skor percobaan itu.
5. **Skor nomor** muncul, lalu lanjut ke nomor berikutnya.
6. **Ringkasan latihan** berisi skor dan tiga tombol: **Ulangi semua**, **Ulangi yang salah/dibantu**, dan opsi **acak urutan soal**.
7. Di layar nomor selalu ada **Ulangi nomor ini** (mengosongkan semua jawaban di nomor itu).
8. **Riwayat tetap tersimpan saat mengulang**: skor terbaik dan skor terakhir, supaya perkembangan terlihat.

#### B. Renshuu dan Mondai buku utama (tanpa kunci → tidak dikoreksi)
Jawaban benar **tidak ditampilkan karena tidak ada di buku** (tidak dikarang). Bantuan saat buntu:
- **例 menempel di atas** layar saat soal digeser.
- **📖 Tata Bahasa**: panel dari bawah berisi penjelasan tata bahasa bab itu, tanpa meninggalkan soal.
- Jalan pintas **"Latihan bab ini di Mondaishuu →"** untuk latihan yang dikoreksi.

Per bagian:
- **Renshuu A**: tabel substitusi. Pilihan di kotak sorotan digeser untuk membentuk kalimat baru; dibaca lisan.
- **Renshuu B**: latihan lisan sesuai fungsi buku. Contoh (soal → jawaban contoh) di atas, soal 1, 2, 3 … beserta gambar di bawah. Tanpa kotak jawaban. Nomor tercentang selesai saat soal terakhir tercapai.
- **Renshuu C**: dialog contoh dengan bagian yang bisa diganti disorot. Chip pilihan (1, 2, 3) mengganti bagian sorotan di dialog.
- **Mondai**:
  - Soal dengar: putar audio (bisa berulang), lalu jawab.
  - Soal tulis: kotak jawaban atau pilihan.
  - Jawaban **disimpan** tapi **tidak dikoreksi**. Ada tombol **Hapus jawaban & ulangi**.

#### C. Kuis hafalan
1. Pilih kelompok (mis. hiragana あ–さ, kanji Bab 3).
2. Satu soal per layar, 4 pilihan. Pilihan salah diambil dari isi kelompok yang sama.
3. Umpan balik langsung (✓/✗ + jawaban benar), lalu otomatis lanjut.
4. Ringkasan skor dengan tombol **Ulangi** dan **Ulangi yang salah**. Kartu yang salah ditandai "Belum hafal".

#### D. Bantuan AI di latihan (jika API key diisi, lihat §4.11)
- Mondaishuu, soal ✗ → **✨ Kenapa salah?**
- Renshuu B, Mondai buku utama → **✨ Minta contoh jawaban dari AI** (berlabel AI, bukan kunci resmi).

#### Data tambahan untuk progres
```jsonc
"mondaishuu": {
  "MS03.ex2": { "best": 10, "last": 8, "total": 10, "attempts": 3,
                "items": { "1": "correct", "2": "assisted", "3": "wrong" } }
},
"mondai_answers": { "L03.mondai.3.2": "…jawaban yang diketik…" }
```

### 4.11 Penjelasan AI (opsional, BYOK)

**Konsep:** *bring your own key*. Pengguna memasukkan API key miliknya sendiri, lalu aplikasi memanggil penyedia AI **langsung dari HP**. Tidak ada backend dan tidak ada server perantara. AI hanya dipakai untuk **memberi penjelasan**, tidak untuk menambah materi.

**Pengaturan (Settings → AI)**
- **Penyedia** (bisa ganti-ganti): Claude (Anthropic), Gemini (Google), OpenAI. Model dipilih dari daftar per penyedia, dan nama model juga bisa diketik manual supaya tetap jalan saat ada model baru.
- **API key** disimpan terenkripsi di HP (Android Keystore). Key tidak pernah masuk ke kode, repo, atau backup progres.
- **Tombol "Tes koneksi."**
- **Bahasa penjelasan:** Indonesia (default).
- **Hapus cache penjelasan.**
- **Jika key kosong, semua tombol ✨ disembunyikan** dan aplikasi berperilaku 100% buku.

**Titik pemakaian (tombol ✨, hanya muncul di konteksnya)**
| Lokasi | Aksi | Isi yang dikirim ke AI |
|---|---|---|
| Teks Jepang mana pun (tekan lama) | ✨ Jelaskan kalimat ini | Kalimat + bacaan + terjemahan buku + Kosa Kata dan Tata Bahasa bab itu |
| Mondaishuu, soal ✗ | ✨ Kenapa salah? | Soal + jawaban pengguna + kunci 解答 + Tata Bahasa bab itu |
| Renshuu B, Mondai buku utama | ✨ Minta contoh jawaban | Instruksi + 例 + soal + Tata Bahasa bab itu |
| Tata Bahasa | ✨ Jelaskan lebih sederhana / ✨ Contoh lain | Poin tata bahasa dari buku |

**Tampilan**
- Jawaban muncul di **panel dari bawah**, ditampilkan bertahap (*streaming*). Pengguna bisa **bertanya lanjutan** di panel itu, dengan konteks tetap terkait konten yang sedang dibuka.
- Kotak jawaban memakai gaya berbeda dari isi buku: garis tepi putus-putus, ikon ✨, dan label tetap **"✨ Penjelasan AI — bukan dari buku, bisa keliru"**.
- Teks Jepang di jawaban AI tetap tampil apa adanya. Tidak memakai fitur kanji-tap karena bacaannya bukan dari buku.

**Akurasi dan biaya**
- Setiap permintaan menyertakan **isi buku yang relevan** sebagai rujukan. AI diinstruksikan menjelaskan berdasarkan buku dan menyebut kalau ia tidak yakin.
- Jawaban **di-cache di HP** per (aksi + konten). Pertanyaan yang sama tidak memanggil API lagi; ada tombol "Minta ulang" kalau ingin jawaban baru.
- Biaya ditanggung akun API pengguna. Panjang jawaban dibatasi agar hemat.
- Saat offline, tombol ✨ tetap terlihat tapi menampilkan pesan "Butuh internet".

**Privasi**
- Yang dikirim hanya potongan isi buku dan jawaban pengguna terkait, langsung ke penyedia yang dipilih. Tidak ada data lain.

### 4.12 Suara pengucapan 🔊 (text-to-speech)
**Alasan:** CD hanya berisi Kaiwa dan Mondai, sehingga pemula tidak punya contoh bunyi huruf dan kosakata.

**Cara kerja**
- Memakai mesin suara Jepang **bawaan Android** (TTS).
- Gratis dan tidak menambah ukuran APK.
- Bisa offline jika paket suara Jepang sudah ter-install. Jika belum, aplikasi menampilkan panduan singkat untuk memasangnya dari pengaturan Android.

**Tombol 🔊 muncul di**
- Kartu hafalan (huruf dan kata)
- Daftar Kosa Kata
- Tabel hiragana/katakana
- Menu tekan-lama pada kalimat Jepang

**Aturan**
- Teks yang diucapkan adalah **bacaan kana dari buku** (bukan kanji mentah), supaya pengucapan kanji tidak salah tebak oleh mesin.
- Diberi label kecil **"suara sintetis"**, untuk membedakannya dari audio CD.
- Jika ada audio CD untuk konten itu (Kaiwa, Mondai), **audio CD selalu diutamakan**.

### 4.13 Panduan awal dan pengguna yang sudah pernah belajar
**Saat pertama kali dibuka** ada 3–4 layar singkat (bisa dilewati):
1. Cara belajar yang disarankan, **diambil dari halaman "Cara Penggunaan Efektif" di buku terjemahan**. Urutan per bab: Kosa Kata → Bunkei → Reibun → Kaiwa → Renshuu → Mondai → Mondaishuu.
2. Pengenalan fitur: kanji ditekan untuk furigana, あ|Ro romaji, 🔊 suara, ✨ AI (jika diaktifkan).
3. Pertanyaan: **"Sudah pernah belajar?"**
   - **Belum** → diarahkan ke Hafalan hiragana, lalu Bab 1.
   - **Sudah, sampai bab …** → bab sebelumnya bisa ditandai selesai sekaligus (opsional), dan tombol Lanjutkan diarahkan ke bab berikutnya.

**Prinsip kebebasan**
- **Semua bab, bagian, dan latihan terbuka sejak awal.** Tidak ada kunci atau urutan wajib.
- Progres bisa diubah manual kapan saja: tandai atau batalkan per bagian, atau per bab sekaligus.
- Panduan awal bisa ditampilkan lagi dari Settings.

### 4.14 Latihan Campuran
Untuk latihan terus-menerus lintas bab, tanpa harus memilih per bab.

- **Pilih rentang bab** (mis. 1–10) dan jenis soal: Mondaishuu, kuis kosakata/kanji, atau keduanya.
- **Soal diambil acak** dari isi buku dalam rentang itu. Mondaishuu dikoreksi dengan 解答, kuis dari Kosa Kata. Tidak ada soal buatan.
- **Sesi berisi 10 / 20 / 30 soal** atau tanpa batas.
- Bantuan yang sama berlaku: ↻ coba lagi, 💡 lihat jawaban, ✨ kenapa salah.
- **Ringkasan di akhir sesi:**
  - skor
  - daftar soal yang salah
  - tombol **Ulangi yang salah**
  - bab mana yang paling sering salah, dengan jalan pintas ke bab itu
- **Opsi "Fokus kelemahan":** soal yang pernah salah atau dibantu diberi peluang muncul lebih besar.

### 4.15 Pencarian 🔎
- **Satu kolom cari** di Beranda (ikon 🔎 juga ada di top bar daftar bab).
- **Bisa diketik dalam:** kanji/kana (会社員, かいしゃいん), romaji (kaishain), atau Indonesia (karyawan).
- **Cakupan:** Kosa Kata, Kata Referensi, indeks kanji, kalimat (Bunkei, Reibun, Kaiwa), dan Tata Bahasa.
- **Hasil dikelompokkan per jenis**, masing-masing dengan label bab. Menekan hasil membuka lokasinya dan menyorot teks yang cocok.
- **Indeks pencarian dibuat saat build data** (`search_index.json`), jadi pencarian cepat dan offline.
- **Riwayat pencarian terakhir** disimpan lokal dan bisa dihapus.

### 4.16 Tersimpan ⭐
- **Tombol ⭐** di kalimat (menu tekan-lama), kosakata, poin Tata Bahasa, nomor Renshuu/Mondai, dan soal Mondaishuu.
- **Halaman Tersimpan** di Beranda, dikelompokkan per jenis, dengan filter per bab. Menekan item membuka lokasinya.
- **Catatan pribadi singkat** bisa ditambahkan per item (opsional).
- **Ikut Backup/Restore.**

---

## 5. Design system

### 5.1 Identitas
- **Nama:** Minna Pocket (aplikasi buku II: *Minna Pocket II*)
- **Logo:** kotak sudut membulat berwarna krem kertas. Di tengahnya **の** merah sampul dengan gaya goresan kuas tipis, di bawahnya pita hitam tipis (referensi blok hitam sampul), dan titik kuning kecil di kanan atas (referensi stiker "CD付"). Aplikasi II menambahkan angka **II** kecil.
- Logo **digambar sendiri**: tidak memakai ilustrasi burung sampul atau logotype asli.

![Konsep logo](assets/logo.svg)

*(Ini preview konsep. Versi final dibuat sebagai path vektor dengan adaptive icon Android, foreground + background.)*

### 5.2 Palet warna (disampel dari buku)

| Token | Terang | Gelap | Asal di buku | Dipakai untuk |
|---|---|---|---|---|
| `primary` | `#D82830` | `#E5484F` | Merah sampul | Tombol utama, bab aktif, konten buku utama |
| `ink` | `#2A272B` | `#EDE9E0` | Teks & blok hitam sampul | Teks utama |
| `paper` | `#FBF8EE` | `#1C1A1D` | Kertas halaman dalam | Latar aplikasi |
| `surface` | `#FFFFFF` | `#262328` | — | Kartu |
| `highlight` | `#F0B8A8` (latar `#FBE3DA`) | `#5A2E27` | Kotak sorotan Renshuu A | Kanji ditekan, baris Kaiwa aktif |
| `secondary` | `#866A49` | `#CFB996` | Pita sampul buku terjemahan | Konten dari buku terjemahan (Kosa Kata, Terjemahan, Tata Bahasa) |
| `secondarySoft` | `#CFB996` | `#4A3D2C` | Idem | Latar label/chip terjemahan |
| `audio` | `#F2E25C` | `#D9C94A` | Stiker "CD付" | Penanda audio saja (dipakai hemat) |
| `muted` | `#8A8580` | `#8F8A84` | — | Teks sekunder, teks Jepang kecil di mode romaji |
| `success` / `error` | `#3E7D4F` / `#D82830` | `#6DB27E` / `#E5484F` | — | Koreksi Mondaishuu |

**Aturan warna:**
- **Merah** = buku utama.
- **Cokelat emas** = buku terjemahan.
- **Salem** = sorotan interaksi.
- **Kuning** = audio.
- Kontras teks minimal WCAG AA di kedua tema.

### 5.3 Tipografi
| Peran | Font | Ukuran dasar |
|---|---|---|
| Teks Jepang | Noto Sans JP | 18 sp (bisa diubah di Settings) |
| Kanji besar (kartu hafalan, judul bab) | Klee One | 48–96 sp |
| Teks Indonesia dan romaji | Plus Jakarta Sans | 15–16 sp |
| Furigana | Noto Sans JP | 50% dari teks induk |

Semua font dibundel (offline).

### 5.4 Ikon dan komponen
- **Ikon:** set **Lucide** (garis tipis, konsisten), disertakan sebagai file SVG.
  - 🔎 `search` = pencarian (romaji memakai tombol geser あ | Ro)
  - 🎧 `headphones` = audio
  - `flag` = laporan salah
  - `check-circle` = selesai
- **Komponen inti:**
  - Kartu bab (dengan lingkaran progres)
  - Kartu subtitle
  - Daftar nomor (grid)
  - Teks Jepang interaktif (kanji tap dan romaji)
  - Baris dialog
  - Mini player
  - Tombol play inline
  - Tabel substitusi
  - Kartu soal (contoh + soal)
  - Flashcard
  - Bottom sheet pengaturan
- **Bentuk:** sudut 16 dp untuk kartu, 12 dp untuk tombol. Jarak dasar 8 dp. Bayangan sangat tipis; dominan garis 1 dp warna `ink` 10%.

---

## 6. Arsitektur teknis

### 6.1 Ringkas
- **Flutter** (Android). Tanpa backend dan tanpa internet.
- **Konten:** JSON per bab + gambar + audio di `assets/`, dibundel ke APK.
- **Pengolahan berat dilakukan saat build data (di luar HP):**
  - pemenggalan kata
  - romaji
  - indeks kanji
  - penanda waktu audio
  - kompresi audio

  Aplikasi hanya menampilkan.
- **Build APK:** repo GitHub **private** + GitHub Actions. APK diunduh dari halaman Actions/Release, lalu di-install manual (sideload).

### 6.2 Paket Flutter
**Prinsip (rev. 1.1):** eksekusi dilakukan oleh AI lain tanpa improvisasi, jadi dipilih paket sesedikit mungkin dan **tanpa generator kode** (tanpa `build_runner`, `freezed`, `json_serializable`).

| Kebutuhan | Paket |
|---|---|
| State | `flutter_riverpod` (provider manual, tanpa generator) |
| Navigasi | `go_router` |
| Audio | `just_audio`, `audio_session` |
| Pengaturan | `shared_preferences` |
| Progres, tersimpan, jawaban, cache AI | **file JSON lokal** lewat `path_provider` (tanpa Hive) |
| Backup / restore | `file_picker`, `share_plus` |
| Ikon | **file SVG Lucide** di `assets/icons/` + `flutter_svg` |
| Model JSON | **kelas Dart biasa** dengan `fromJson` tulisan tangan (disediakan lengkap) |
| AI (HTTP + streaming) | `http` (adapter per penyedia: Anthropic, Gemini, OpenAI) |
| Penyimpanan API key | `flutter_secure_storage` |
| Render jawaban AI | `flutter_markdown` |
| Suara pengucapan | `flutter_tts` (TTS bawaan Android) |

Versi paket yang dipakai dicatat di `docs/08_Build_Rilis.md`.

### 6.3 Flavor (satu kode, dua aplikasi)
| Flavor | App ID | Nama | Data |
|---|---|---|---|
| `book1` | `id.minnapocket.book1` | Minna Pocket | bab 1–25 |
| `book2` | `id.minnapocket.book2` | Minna Pocket II | bab 26–50 |

Keduanya bisa ter-install berdampingan. Progres dan indeks kanji terpisah per aplikasi.

### 6.5 Update aplikasi tanpa kehilangan progres
- **Cara update:** perbaikan (mis. hasil tandaan 🚩) dirilis sebagai APK baru yang di-install **di atas** versi lama. Data lokal (progres, tersimpan, cache AI, API key) tetap utuh.
- **Syaratnya:** setiap APK ditandatangani dengan **kunci tanda tangan (keystore) yang sama** dan nomor versi selalu naik.
- **Penyimpanan keystore:**
  - disimpan sebagai *secret* di repo GitHub private (dipakai GitHub Actions);
  - **cadangannya disimpan pengguna** di tempat aman (mis. Google Drive pribadi), terpisah dari repo.
- **Jika keystore hilang:** APK baru tidak bisa menimpa yang lama. Aplikasi harus di-uninstall dan progres hilang, kecuali sudah di-Backup. Karena itu aplikasi menampilkan **pengingat Backup** berkala (mis. tiap 30 hari).
- Detail langkahnya ada di Rencana Eksekusi.

### 6.4 Struktur folder (rev. 1.1)
Mengikuti **flutter-clean-architecture-riverpod** (Uuttssaavv): setiap fitur punya `data / domain / presentation`. Folder contoh yang tidak relevan (`authentication`, `dashboard`, `user_cache_service`) dibuang. Folder yang belum berisi diberi `.gitkeep`. Proyek Flutter berada **langsung di folder `Minna Pocket/`** (bukan subfolder `app/`). Rincian lengkap per file ada di `docs/02_Rencana_Eksekusi.md` §Struktur.

```
Minna Pocket/
├── AGENTS.md                 # aturan untuk AI eksekutor
├── docs/                     # dokumen 01–09 + mockups/
├── schema/                   # JSON Schema data konten
├── content-src/              # data hasil OCR (format penulisan §7.1)
├── tools/                    # skrip Python build & validasi data
├── assets/
│   ├── book1/                # hasil build: manifest.json, lessons/, mondaishuu/, img/, audio/ …
│   ├── fonts/  icons/  logo/
├── lib/
│   ├── configs/              # app_configs.dart (konstanta)
│   ├── main/                 # app.dart, app_env.dart (flavor), main_book1.dart, main_book2.dart, observers.dart
│   ├── routes/               # app_route.dart (go_router)
│   ├── features/             # onboarding, home, lesson, kaiwa, renshuu, mondai, bunpou, kosakata,
│   │                         # mondaishuu, practice_mix, hafalan, search, bookmarks, settings, ai_assist
│   ├── services/             # audio_service, tts_service, progress_service, content_service
│   └── shared/               # data/local, data/remote, domain/models, domain/providers,
│                             # exceptions, theme, widgets, utils, globals.dart
└── test/                     # cermin dari lib/
```

### 6.6 Alur data (assets → UI)
```
assets/book1/*.json → AssetContentDataSource → ContentRepository → Provider (Riverpod) → Widget
                      (baca + parse ke model)   (satu pintu data)   (cache + loading/error)
```
- **`manifest.json`** berisi ringkasan seluruh buku (daftar bab, bagian yang ada, jumlah nomor, judul, path file). Beranda dan daftar bab hanya membaca manifest.
- **File bab dimuat saat dibutuhkan** (`L03.json` dibaca saat Bab 3 dibuka) lalu disimpan di memori oleh provider.
- **Model Dart bertipe**: UI tidak pernah membaca map JSON mentah.
- **Data pengguna** (progres, tersimpan, jawaban, skor, SRS, tandaan, cache AI) lewat `ProgressRepository` → file JSON lokal. Isi buku dan data pengguna digabung di provider (mis. daftar subtitle + status centang).
- **Setiap item punya ID tetap** (mis. `L03.renshuu_b.4`), sehingga perbaikan data tidak merusak progres. `manifest.json` memuat `data_version`.
- **Semua data divalidasi sebelum masuk APK** (skrip `tools/validate.py`): skema, file gambar/audio ada, nomor berurutan.

---

## 7. Skema data

### 7.1 Format penulisan teks Jepang (hasil OCR)
Hasil OCR ditulis dalam format ringkas yang mudah dibaca dan diperbaiki:

```
{会社員|かいしゃいん}です。 {日本|にほん}から {来|き}ました。
```

- `{kanji|bacaan}` = kata berkanji beserta furigana persis seperti di buku.
- Teks kana di luar kurung ditulis apa adanya.
- `[[img:L01_rb3_1]]` = sisipan gambar. `___` = tempat kosong (isian).

### 7.2 Format terkompilasi (dibaca aplikasi)
Skrip build mengubah format §7.1 menjadi token:

```json
{
  "jp": "会社員です。",
  "tokens": [
    { "s": "会社員", "r": "かいしゃいん", "ro": "kaishain", "k": true },
    { "s": "です",   "r": "です",         "ro": "desu" },
    { "s": "。",     "ro": "." }
  ]
}
```
- `s` teks tampilan, `r` bacaan, `ro` romaji, `k` = token kanji (bisa ditekan, diberi garis bawah di mode romaji).
- Aplikasi menyusun baris romaji dari `ro` (dipisah spasi). Pasangan kanji↔romaji diketahui dari token yang sama.

> Selanjutnya, setiap field bertipe **JpText** = objek token di atas.

### 7.3 File bab (`L01.json`)
```json
{
  "book": 1,
  "lesson": 1,
  "title": "はじめまして",
  "sections": {
    "kosakata": [
      { "kana": "わたし", "kanji": null, "meaning": "saya" },
      { "kana": "かいしゃいん", "kanji": "会社員", "meaning": "karyawan perusahaan" }
    ],
    "bunkei": [
      { "no": 1, "jp": "JpText", "tr": "Saya Mike Miller." }
    ],
    "reibun": [
      { "no": 1, "q": "JpText", "a": "JpText", "tr_q": "…", "tr_a": "…" }
    ],
    "kaiwa": {
      "title": "JpText", "title_tr": "Perkenalan",
      "image": "img/L01/kaiwa.png",
      "audio": "audio/L01_kaiwa.m4a",
      "lines": [
        { "speaker": "佐藤", "jp": "JpText", "tr": "…", "t": [3.20, 5.85] }
      ]
    },
    "renshuu_a": [ "RenshuuA" ],
    "renshuu_b": [ "RenshuuB" ],
    "renshuu_c": [ "RenshuuC" ],
    "mondai":    [ "Mondai" ],
    "bunpou":    [ "Bunpou" ],
    "sankou":    [ "Sankou" ]
  },
  "source_pages": { "main": [34, 41], "translation": [18, 23] }
}
```
`t` = penanda waktu [mulai, selesai] dalam detik untuk sinkron baris Kaiwa.

### 7.4 Tipe per bagian
```jsonc
// RenshuuA — tabel substitusi
{ "no": 1,
  "rows": [
    [ { "text": "JpText" },
      { "choices": ["JpText", "JpText", "JpText"], "highlight": true },
      { "text": "JpText" } ]
  ] }

// RenshuuB — satu nomor = satu pola
{ "no": 3,
  "example": { "prompt": "JpText", "answer": "JpText", "image": "img/L01/rb3_ex.png" },
  "items": [ { "no": 1, "prompt": "JpText", "image": "img/L01/rb3_1.png" } ] }

// RenshuuC — dialog latihan dengan bagian yang diganti
{ "no": 1, "image": "img/L01/rc1.png",
  "dialog": [ { "speaker": "A", "jp": "JpText", "slots": ["s1"] } ],
  "substitutions": [ { "s1": "JpText" }, { "s1": "JpText" } ] }

// Mondai
{ "no": 1, "kind": "listening_answer | listening_choice | fill | choice | write",
  "audio": "audio/L01_mondai1.m4a",
  "instruction": "JpText",
  "example": { "prompt": "JpText", "answer": "JpText" },
  "items": [ { "no": 1, "prompt": "JpText", "choices": ["…"], "image": "…" } ] }

// Bunpou — penjelasan tata bahasa (blok kaya)
{ "no": 1, "title": "Kata Benda₁ は Kata Benda₂ です",
  "blocks": [ { "type": "p", "text": "…" },
              { "type": "example", "jp": "JpText", "tr": "…" },
              { "type": "note", "text": "…" },
              { "type": "table", "rows": [["…"]] } ] }

// Sankou — kata referensi tematik
{ "title": "Negara, Orang, Bahasa", "items": [ { "kana": "…", "kanji": "…", "meaning": "…" } ] }
```

### 7.5 Mondaishuu (`mondaishuu/MS01-02.json`)
```jsonc
{ "id": "MS01-02", "lessons": [1, 2], "title": "第1・2課",
  "exercises": [
    { "no": 1, "instruction": "JpText", "image": "…",
      "example": { "prompt": "JpText", "answer": "JpText" },
      "items": [
        { "no": 1, "prompt": "JpText",
          "answer_type": "choice | fill | sentence",
          "choices": ["…"],
          "answers": ["正答", "variasi jawaban lain yang tertulis di 解答"] }
      ] }
  ] }
```
- `choice` dan `fill` dikoreksi otomatis (setelah normalisasi spasi dan tanda baca).
- `sentence` memakai mode cek sendiri.

### 7.6 Indeks kanji (`kanji_index.json`) — dibuat otomatis
```json
[
  { "word": "会社員", "readings": ["かいしゃいん"], "meaning": "karyawan perusahaan",
    "first_lesson": 1, "occurrences": [ { "lesson": 1, "section": "bunkei", "no": 2 } ] }
]
```

### 7.7 Progres (lokal, file `user_data.json` di folder dokumen aplikasi)
```jsonc
{ "last_opened": { "route": "/lesson/3/renshuu_b/4", "at": "2026-11-12T08:00:00" },
  "sections": { "L03.kaiwa": true, "L03.renshuu_b.4": true },
  "mondaishuu": { "MS03.ex2": { "best": 8, "last": 6, "total": 10 } },
  "hafalan": {
    "hira.あ":     { "due": "2026-11-20", "interval": 7, "ease": 2.5, "reps": 4, "lapses": 0 },
    "kanji.会社員": { "due": "2026-11-12", "interval": 1, "ease": 2.3, "reps": 1, "lapses": 1 }
  },
  "onboarding_done": true,
  "bookmarks": [ { "ref": "L05.bunpou.2", "note": "bedanya へ dan に", "at": "…" } ],
  "search_history": ["kaishain", "karyawan"],
  "flags": [ { "ref": "L03.reibun.2.a", "note": "", "at": "…" } ] }
```
Backup/Restore = mengekspor/mengimpor objek ini sebagai satu file `.json`.

### 7.8 Cache AI (lokal, terpisah dari progres)
```jsonc
{ "explain|L03.reibun.2.a": { "provider": "anthropic", "model": "…", "at": "…", "text": "…markdown…" } }
```
API key **tidak** disimpan di sini dan **tidak** ikut backup.

---

## 8. Kualitas data

**OCR**
- OCR dilakukan dengan membaca gambar halaman langsung (bukan Tesseract).
- Tiap halaman dibaca **dua kali secara terpisah**. Selisih antar-pembacaan dicek ulang ke gambar.

**Cek otomatis**
- Kata berkanji di teks dicocokkan dengan Kosa Kata (bentuk dan bacaan).
- Nomor bagian dan soal harus berurutan.
- Semua gambar dan audio yang dirujuk harus ada.
- Penanda waktu Kaiwa harus monoton.

**Audio dan gambar**
- Penanda waktu Kaiwa dibuat dari deteksi jeda suara, lalu dicocokkan dengan jumlah baris dialog.
- Gambar soal dan ilustrasi dipotong dari scan dengan resolusi cukup, dirapikan (latar diputihkan), dan disimpan sebagai PNG/WebP.

**Di aplikasi**
- Sisa kesalahan dikumpulkan lewat tombol 🚩.

---

## 9. Keputusan kecil (diambil oleh perencana)
| Hal | Keputusan |
|---|---|
| Sistem romaji | Hepburn modifikasi; vokal panjang ditulis apa adanya (おう → ou, ええ → ee, ー → huruf vokal diulang) agar sama dengan kana |
| Renshuu A | Ditampilkan sebagai tabel substitusi; pilihan bisa digeser satu per satu |
| Terjemahan | Default disembunyikan |
| 復習 A–H (buku utama) | Disisipkan di daftar bab sesuai posisinya di daftar isi; template sama seperti Mondai/Renshuu |
| まとめ (副詞・接続詞・会話表現) | Halaman tersendiri dari menu bab, diletakkan sesuai posisi di buku |
| Lampiran (bentuk kata kerja, indeks) | Masuk menu "Lampiran" di Beranda |
| Gambar | Diambil dari scan, tidak digambar ulang |
| Bahasa UI | Indonesia |

---

## 10. Pengembangan ke buku II
- Data punya kolom `book`. Nomor bab tidak dikunci ke 1–25.
- Template layar, pemutar, indeks kanji, dan progres semuanya generik.
- Untuk *Minna Pocket II* cukup: PDF buku utama II, terjemahan II, Mondaishuu II, dan CD II → OCR → `assets/book2/` → build flavor `book2`.

---

## 11. Gambaran tahapan (detail di Rencana Eksekusi)
1. Persetujuan dokumen ini
2. Skema final + contoh lengkap Bab 1 (pilot OCR)
3. Fondasi aplikasi Flutter + template layar memakai data Bab 1
4. OCR massal Bab 2–25, 復習, まとめ, Introduksi, Mondaishuu
5. Audio: kompresi + penanda waktu Kaiwa + segmen soal Mondai
6. Hafalan (+ spaced repetition), indeks kanji, suara 🔊, Latihan Campuran, panduan awal
7. Fitur AI opsional (BYOK)
8. Verifikasi, build APK, rilis

---

## 12. Lampiran — ringkasan keputusan
- Nama **Minna Pocket**; Android; Flutter; tanpa backend; offline; GitHub private + Actions.
- Isi 100% dari buku; romaji, indeks kanji, dan penanda waktu adalah turunan otomatis.
- Navigasi: Bab → subtitle → (pilih nomor jika perlu) → konten; satu nomor latihan per layar.
- Kanji tanpa furigana, ditekan untuk melihat bacaan (per kata).
- あ|Ro mode romaji: romaji utama + teks Jepang kecil, pasangan kanji↔romaji bergaris bawah.
- Audio: play/pause di dekat konten, pengaturan global lewat 🎧; Kaiwa sinkron per baris.
- Mondaishuu menu terpisah, koreksi otomatis dari 解答; ↻ coba lagi per soal, 💡 lihat jawaban kapan saja, ulangi nomor/latihan/yang salah, riwayat skor tersimpan.
- Renshuu & Mondai buku utama tanpa koreksi; bantuan: 例 menempel, panel Tata Bahasa, jalan pintas ke Mondaishuu.
- Hafalan: hiragana, katakana, kanji per kata dari buku.
- Progres lokal + Backup/Restore; laporan salah 🚩.
- AI opsional (BYOK: Claude / Gemini / OpenAI) hanya untuk penjelasan; tombol ✨ kontekstual; berlabel "bukan dari buku"; tersembunyi jika key kosong.
- 🔊 suara pengucapan via TTS Android untuk huruf, kosakata, dan kalimat (berlabel "suara sintetis"; audio CD diutamakan).
- Panduan awal dari "Cara Penggunaan Efektif" buku; semua bab terbuka; pengguna lama bisa menandai bab yang sudah dipelajari.
- Hafalan dengan spaced repetition ("Ulasan hari ini"); tanpa latihan menulis.
- Latihan Campuran: soal acak lintas bab dari isi buku, dengan opsi fokus kelemahan.
- 🔎 Pencarian (kana/kanji/romaji/Indonesia) dan ⭐ Tersimpan dengan catatan pribadi.
- Update lewat APK baru dengan keystore yang sama; progres aman; pengingat Backup berkala.

---

## 13. Catatan revisi
| Versi | Tanggal | Perubahan |
|---|---|---|
| 1.0 | 11 Nov 2026 | Versi awal |
| 1.1 | 11 Nov 2026 | Tombol romaji → あ \| Ro; audio Mondai dibagi per soal + jeda otomatis; paket disederhanakan (tanpa generator kode, tanpa Hive, ikon SVG); struktur folder mengikuti clean-architecture-riverpod; alur data (§6.6); proyek di folder `Minna Pocket/`; git lokal dulu; dokumen dibekukan |
- Palet dari buku: merah sampul, hitam tinta, krem kertas, salem, cokelat emas, kuning CD.
