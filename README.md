# Minna Pocket

Aplikasi pendamping belajar bahasa Jepang berbasis *Minna no Nihongo Shokyu I* (Bab 1–25), dirancang *offline-first* dengan dukungan tutor AI opsional (Gemini).

## Fitur Utama

- **Materi per Bab (Bab 1–25):** Kosakata, Bunkei, Reibun, Kaiwa, Renshuu A/B/C, Mondai, Bunpou, dan Sankou.
- **Tampilan Teks Jepang Interaktif:** Mode `あ | Ro` (Kana/Kanji atau Romaji), ketuk kanji untuk melihat furigana, ukuran huruf yang dapat diatur, serta tekan lama untuk TTS, bookmark, dan salin.
- **Audio & Pengucapan:** Pemutar audio materi buku (kecepatan `0.75×` / `1×`, ulang baris) dan Text-to-Speech (TTS).
- **Latihan & Evaluasi:** Mondaishuu, Fukushuu/Matome, dan Latihan Campuran.
- **Hafalan (SRS):** Kartu hafalan & kuis untuk Hiragana, Katakana, dan Kanji per bab dengan penjadwalan SM-2 (`Lupa`, `Susah`, `Bisa`, `Mudah`).
- **Tutor AI (Opsional):** Integrasi Gemini API (BYOK) di Pengaturan AI untuk penjelasan kalimat, penyederhanaan tata bahasa, dan contoh jawaban sesuai konteks bab.

## Menjalankan & Build

```powershell
flutter pub get
flutter test
flutter run --flavor book1 -t lib/main/main_book1.dart
```

### Build APK (Book 1)

```powershell
flutter build apk --release --flavor book1 -t lib/main/main_book1.dart
```

Hasil build berada di `build/app/outputs/flutter-apk/app-book1-release.apk`.  
Untuk rilis produksi dengan tanda tangan *keystore* sendiri (bukan debug key), siapkan `android/key.properties` sesuai panduan di [docs/08_Build_Rilis.md](docs/08_Build_Rilis.md).
