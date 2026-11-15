# AGENTS.md — Aturan untuk AI Eksekutor (WAJIB DIBACA SEBELUM SETIAP TASK)

Kamu adalah **pelaksana**. Semua keputusan desain, data, dan teknis **sudah diambil**. Tugasmu hanya mengerjakan task di `docs/02_Rencana_Eksekusi.md` **persis** seperti tertulis.

## 1. Aturan mutlak
1. **Kerjakan satu task saja**, sesuai urutan. Jangan mulai task berikutnya sebelum kriteria lulus task saat ini terpenuhi dan pemilik berkata "lanjut" (kecuali pemilik memberi izin mengerjakan beberapa task sekaligus).
2. **Hanya ubah/buat file yang disebut di task itu.** Dilarang menyentuh file lain.
3. **File bertanda `FILE INI DISEDIAKAN LENGKAP. JANGAN DIUBAH.` tidak boleh diubah sedikit pun.** Termasuk tidak boleh "dirapikan", diformat ulang, diganti nama, atau dipindah.
4. **Dilarang menambah, menghapus, atau mengganti paket** di `pubspec.yaml`. Dilarang menjalankan `flutter pub upgrade`.
5. **Dilarang mengubah apa pun di `assets/`, `content-src/`, `schema/`, `tools/`, `docs/`** kecuali menulis log di `docs/LOG_EKSEKUSI.md`.
6. **Dilarang mengarang** teks UI, warna, ukuran, ikon, fitur, atau perilaku yang tidak ada di dokumen. Teks UI diambil dari `lib/shared/utils/strings.dart` atau dari kutipan di `docs/05_Spesifikasi_Layar.md`.
7. **Jika ada yang ambigu, bertentangan, atau error yang tidak bisa diselesaikan hanya di file yang boleh diubah: BERHENTI.** Tulis laporan di `docs/LOG_EKSEKUSI.md` (format §4) dan tanyakan pemilik. **Jangan menebak. Jangan "memperbaiki" file terlarang.**
8. Jika `flutter analyze` atau `flutter test` gagal karena file `DISEDIAKAN LENGKAP`: **BERHENTI** dan laporkan pesan error lengkapnya. Jangan mengubah file itu.

## 2. Cara kerja per task
1. Baca task di `docs/02_Rencana_Eksekusi.md`, lalu semua bagian dokumen yang dirujuk task itu.
2. Kerjakan.
3. Jalankan pemeriksaan wajib:
   ```
   flutter analyze
   flutter test
   ```
   - `flutter analyze` **0 error dan 0 warning** (info boleh).
   - `flutter test` semua lulus.
4. Jika task meminta, jalankan aplikasi: `flutter run --flavor book1 -t lib/main/main_book1.dart`, lalu cocokkan dengan `docs/09_Checklist_QA.md`.
5. Commit dengan pesan persis seperti di task: `git add -A && git commit -m "<pesan>"`.
6. Tulis ringkasan di `docs/LOG_EKSEKUSI.md` (format §4), lalu berhenti dan laporkan ke pemilik.

## 3. Konvensi kode (untuk file yang kamu tulis)
- **State management:** Riverpod 2 (`flutter_riverpod`) dengan provider manual. **Tanpa** `riverpod_generator`, `freezed`, `build_runner`.
- **Layar:** `ConsumerWidget` / `ConsumerStatefulWidget`. Nama kelas & parameter konstruktor **persis** seperti di 05 (dipakai router).
- **Lokasi file:**
  - layar → `lib/features/<fitur>/presentation/screens/`;
  - widget khusus fitur → `.../presentation/widgets/`;
  - provider fitur → `.../domain/providers/`.
- **Tema:**
  - warna → `context.palette.<token>`;
  - huruf → `AppText.*`;
  - jarak → `Sp.*`, `Radii.*`, `Sizes.*`;
  - ikon → `AppIcon(AppIcons.*)`;
  - **dilarang** `Colors.red`, `Color(0x...)`, `Icons.*`, angka jarak di luar `Sp`, kecuali yang tertulis eksplisit di 05.
- **Teks Jepang dari data** → `JpTextView` / `JpLabel`. **Jangan** `Text(x.jp)` untuk konten utama.
- **Navigasi:** `context.push(...)` / `context.go(...)` dengan rute dari 05 / `sectionRoute()`.
- **Jangan memakai `ref` di `dispose()`.** Simpan notifier di `initState`.
- Format kode: `dart format` hanya untuk file yang kamu tulis.

## 4. Format log (`docs/LOG_EKSEKUSI.md`, tambahkan di paling bawah)
```
## <ID task> — <judul> — <tanggal jam>
Status: SELESAI | BERHENTI
File diubah: <daftar>
flutter analyze: <ringkasan>
flutter test: <ringkasan>
Catatan / pertanyaan untuk pemilik: <isi, atau "-">
```

## 5. Yang BUKAN tugasmu
- Membuat/memperbaiki data konten (OCR, JSON, gambar, audio), karena itu dikerjakan perencana.
- Membuat keystore atau mengatur GitHub, karena itu dikerjakan pemilik.
- Mengubah desain, menambah fitur, mengoptimalkan, atau merefaktor kode yang sudah ada.
