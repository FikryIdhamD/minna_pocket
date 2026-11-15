# 08 — Build & Rilis

## 1. Lingkungan
| Komponen | Versi |
|---|---|
| Flutter | stable **≥ 3.24** (catat hasil `flutter --version` di `docs/LOG_EKSEKUSI.md`) |
| Java (Gradle) | 17 |
| Android minSdk | 24 · targetSdk/compileSdk = bawaan Flutter |
| Paket | persis seperti `pubspec.yaml` (jangan menambah/mengganti) |

## 2. Flavor
| Flavor | Entry point | applicationId | Nama | Aset |
|---|---|---|---|---|
| `book1` | `lib/main/main_book1.dart` | `id.minnapocket.book1` | Minna Pocket | `assets/book1/**` |
| `book2` | `lib/main/main_book2.dart` | `id.minnapocket.book2` | Minna Pocket II | `assets/book2/**` (nanti) |

**Perintah:**
- Jalankan (debug, HP tersambung / emulator): `flutter run --flavor book1 -t lib/main/main_book1.dart`
- Build APK rilis: `flutter build apk --release --flavor book1 -t lib/main/main_book1.dart`
  - Hasil: `build/app/outputs/flutter-apk/app-book1-release.apk`

Ikon aplikasi per flavor ada di `android/app/src/book1/res/` (disalin dari `assets/logo/android_res_book1/`).

## 3. Kunci tanda tangan (keystore) — dikerjakan PEMILIK, bukan AI
1. Di terminal PC (folder proyek):
   ```
   keytool -genkey -v -keystore android/app/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias minnapocket
   ```
2. Buat `android/key.properties`:
   ```
   storePassword=<password>
   keyPassword=<password>
   keyAlias=minnapocket
   storeFile=upload-keystore.jks
   ```
3. **Cadangkan** `upload-keystore.jks` + password ke tempat aman (mis. Google Drive pribadi). **Jika hilang, update APK tidak bisa dipasang di atas versi lama.**
4. `.gitignore` sudah mengecualikan `*.jks` dan `key.properties`. Jangan pernah meng-commit keduanya.

Tanpa keystore, build rilis memakai kunci debug. Hasilnya tetap bisa dipasang untuk uji coba, tapi tidak boleh dipakai sebagai rilis tetap.

## 4. Pemasangan di HP (sideload)
1. Salin APK ke HP (kabel / Google Drive).
2. Buka file APK. Izinkan "Instal aplikasi tidak dikenal" untuk aplikasi pembuka file.
3. **Update:** pasang APK baru di atas yang lama dengan keystore yang sama. Data tetap ada.

## 5. GitHub (nanti, saat repo dipindah ke GitHub private)
- Workflow `.github/workflows/build-apk.yml` berjalan saat tag `v*` di-push atau dijalankan manual.
- Secrets: `KEYSTORE_BASE64` (`base64 -w0 android/app/upload-keystore.jks`), `KEYSTORE_PASSWORD`, `KEY_ALIAS`, `KEY_PASSWORD`.
- APK diunduh dari tab **Actions** → run terakhir → **Artifacts**.

## 6. Versi
- `pubspec.yaml` `version: X.Y.Z+N`: **N wajib naik setiap rilis** (Android menolak versi lebih rendah).
- `manifest.json` `data_version` naik otomatis saat `tools/build_data.py` dijalankan.

## 7. Ukuran perkiraan APK book1
Font ±19 MB + audio ±35 MB + gambar ±5–10 MB + data ±3 MB + kode ±20 MB ≈ **80–90 MB**.
