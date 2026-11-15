# 09 — Checklist QA

> Dipakai AI eksekutor di akhir setiap task layar (bagian yang relevan) dan oleh pemilik di ⛳.
> Centang hanya jika **benar-benar dicoba di HP/emulator**.

## Umum (berlaku untuk semua layar)
- [ ] Tidak ada teks, warna, atau ikon yang tidak tertulis di 04/05/strings.
- [ ] Mode gelap: semua teks terbaca, gambar scan tetap di kotak putih.
- [ ] Ukuran huruf "Sangat besar": tidak ada teks terpotong atau overflow (garis kuning-hitam).
- [ ] Tombol ← kembali ke layar sebelumnya. Tombol kembali Android juga berfungsi.
- [ ] Mode あ | Ro berpindah serentak di semua layar yang terbuka.
- [ ] Mengetuk kanji memunculkan furigana dengan sorot salem; ketuk lagi untuk menutup.
- [ ] Mode Ro: kanji bergaris bawah titik-titik di dua baris; mengetuk salah satu menyorot pasangannya.
- [ ] Tekan lama teks Jepang membuka menu (Ucapkan, Simpan, Salin, Tandai salah ketik, dan ✨ jika AI aktif).
- [ ] Tidak ada crash saat mode pesawat (kecuali fitur ✨ menampilkan pesan koneksi).
- [ ] Tutup paksa aplikasi lalu buka lagi: progres, jawaban, dan tersimpan tetap ada.

## S-02 Beranda
- [ ] Logo, nama, dan 🔎 tampil. 🔎 membuka Pencarian.
- [ ] Pertama kali: kartu "Mulai Bab 1". Setelah membuka satu bagian: kartu "Lanjutkan" membawa ke layar terakhir.
- [ ] Baris "Ulasan hari ini" hanya muncul jika ada kartu jatuh tempo.
- [ ] Daftar bab sesuai manifest; lingkaran progres Bab 1 naik setelah bagian selesai.

## S-03 Bab
- [ ] Hanya bagian yang ada di bab itu yang tampil, dikelompokkan Materi / Latihan / Penjelasan.
- [ ] Tile merah = buku utama; tile cokelat = buku terjemahan.
- [ ] Kaiwa & Mondai punya badge audio kuning.
- [ ] Bagian selesai bercentang hijau; bagian bernomor yang baru sebagian menampilkan "x/y".
- [ ] Jalan pintas Mondaishuu membuka set yang benar.

## S-04 Pilih nomor
- [ ] Jumlah kartu = jumlah nomor; ikon 🎧 hanya pada nomor dengar; centang pada nomor selesai.

## S-05 Kosa Kata
- [ ] 3 grup Bab 1 tampil (grup kedua berlabel 〈練習C〉, grup ketiga dipisah garis).
- [ ] Kata berkanji menampilkan kanji + kana kecil + arti. 🔊 mengucapkan bacaan.

## S-06/S-07 Bunkei & Reibun
- [ ] Terjemahan tersembunyi secara default; ikon terjemahan membuka semua; ketuk baris membuka baris itu.
- [ ] (では) tampil kecil di bawah kalimat Bunkei 2.
- [ ] Baris jawaban Reibun (……) menjorok.

## S-08 Kaiwa
- [ ] Ilustrasi tampil. MiniPlayer menempel di bawah dan tidak menutupi baris terakhir saat digulir habis.
- [ ] ▶ memutar audio; baris yang sedang diucapkan tersorot dan layar menggulir mengikuti.
- [ ] Ketuk baris → audio mulai dari baris itu.
- [ ] Tekan lama → "Ulangi baris ini terus" mengulang baris; ⏸ menghentikan.
- [ ] Label 0.75× ↔ 1× mengubah kecepatan, dan ikut berlaku di Mondai.
- [ ] Keluar dari layar → audio berhenti.

## S-09 Renshuu A
- [ ] Tabel 6 nomor Bab 1 sesuai buku: kotak salem, kotak pertanyaan lebih gelap (だれ（どなた）, なんさい（おいくつ）).
- [ ] Baris panjang bisa digeser ke samping. ‹ › berpindah nomor.

## S-10/S-11 Renshuu B & C
- [ ] Gambar tabel tokoh tampil di nomor 1, 2, 5, 6, 7 (B); gambar bisa diperbesar.
- [ ] Contoh 例 di kartu cokelat muda; soal tanpa teks tertulis "(lihat gambar)".
- [ ] C: tombol Contoh/1/2 mengganti gambar; bagian bergaris bawah terlihat.

## S-12 Mondai
- [ ] Tab nomor 1–6; nomor 1–3 berikon 🎧.
- [ ] Bar segmen 例·1·2·3·4·5 (nomor 1); ketuk segmen memutar soal itu; dengan jeda otomatis, audio berhenti di akhir segmen.
- [ ] ▶ di samping soal memutar soal itu saja; 🔁 mengulang segmen.
- [ ] Jawaban ketikan tersimpan setelah keluar-masuk. Mengetik "watashi" berubah menjadi "わたし".
- [ ] Nomor 4–5: kotak isian muncul di dalam kalimat; nomor 6 (perkenalan) punya 2 kotak.
- [ ] Kotak info tanpa kunci jawaban tampil. "Hapus jawaban & ulangi" mengosongkan isian.

## S-13/S-14 Tata Bahasa & Referensi
- [ ] 6 poin Bab 1; contoh ①…⑩ beserta terjemahan; [Perhatian] di kotak cokelat muda.
- [ ] 📖 di layar latihan membuka panel Tata Bahasa tanpa keluar dari layar.
- [ ] Tabel Negara–Orang–Bahasa lengkap 24 baris; Kanada punya 2 bahasa.

## S-16–S-19 Mondaishuu
- [ ] Set 第1・2課 tampil dengan 8 latihan.
- [ ] Latihan 1: gambar + 9 isian; "tokei", "とけい", dan "時計" semuanya benar.
- [ ] Latihan 5: opsi a–i, d dicoret; memilih huruf lewat chip.
- [ ] Latihan 6: pilihan {A, B} di dalam kalimat.
- [ ] Periksa: hijau/merah; jawaban yang salah tidak langsung dibuka; "Coba lagi" hanya mengosongkan soal itu; 💡 membuka jawaban dan soal ditandai "dibantu".
- [ ] Latihan 4 nomor 3: "だれですか" dan "どなたですか" sama-sama benar.
- [ ] Latihan 8 nomor 2–3: tidak dinilai; 💡 menampilkan contoh buku.
- [ ] Skor terbaik & terakhir tersimpan; ringkasan menampilkan semua latihan; "Ulangi yang salah" hanya memuat soal salah/dibantu.

## S-22–S-26 Hafalan
- [ ] Tabel hiragana: baris や dan わ punya sel kosong; ketuk sel mengucapkan kana.
- [ ] Kartu dibalik dengan ketukan; 4 tombol nilai muncul setelah dibalik.
- [ ] Kuis: 4 pilihan, umpan balik langsung, ringkasan di akhir.
- [ ] Ulasan hari ini: kartu baru dibatasi sesuai pengaturan; kartu "Lupa" muncul lagi di akhir sesi.
- [ ] Kanji Bab 1 tampil dengan bacaan, romaji, arti (atau —), dan "Muncul di: Bab 1".

## S-27/S-28 Pencarian & Tersimpan
- [ ] "kaishain", "かいしゃいん", "会社員", dan "karyawan" sama-sama menemukan 会社員.
- [ ] Hasil membuka layar yang tepat. Riwayat tersimpan maksimal 10.
- [ ] ⭐ dari menu tekan-lama muncul di Tersimpan; catatan bisa diubah; filter berfungsi.

## S-30–S-32 Pengaturan
- [ ] Tema, ukuran huruf (dengan pratinjau), mode teks, dan terjemahan otomatis langsung berpengaruh.
- [ ] Cek suara Jepang memberi pesan yang sesuai.
- [ ] Backup menghasilkan file .json; Hapus semua data → Pulihkan → data kembali.
- [ ] AI: simpan key → tombol ✨ muncul; Tes koneksi memberi pesan sukses/galat yang jelas; Hapus key → ✨ hilang.
- [ ] Tandaan 🚩 bisa diekspor & dihapus.

## S-01 Onboarding & S-15 はじめに
- [ ] Muncul hanya saat pertama kali (atau dari Pengaturan → Tampilkan panduan awal).
- [ ] Halaman 1 berisi "Cara Penggunaan Efektif" + diagram dari buku.
- [ ] "Sudah, sampai bab 3" menandai Bab 1–3 selesai di Beranda.
- [ ] はじめに: tab Huruf menampilkan tabel; tab Panduan menampilkan isi (atau "Bagian ini belum tersedia.").

## S-20/S-21 Latihan Campuran
- [ ] Rentang bab & jenis soal dihormati; "Fokus kelemahan" memunculkan soal yang pernah salah lebih sering.
- [ ] Ringkasan akhir menampilkan bab yang paling sering salah, dengan tautan ke bab itu.
