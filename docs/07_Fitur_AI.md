# 07 — Fitur AI (BYOK)

> Kode inti **sudah jadi**:
> - `features/ai_assist/data/datasource/` — `ai_client.dart`, `ai_key_store.dart`, `ai_cache.dart`
> - `features/ai_assist/domain/` — `ai_prompts.dart`, `ai_session.dart`
> - `features/ai_assist/presentation/widgets/ai_panel.dart`
>
> AI eksekutor hanya membuat layar `ai_settings_screen.dart` (05 §S-31) dan memasang tombol ✨ sesuai 05.

## 1. Prinsip
- AI hanya **menjelaskan**. Semua jawaban tampil di panel berlabel `S.aiLabel` dengan tepi warna `secondary`. Tidak pernah tercampur dengan isi buku.
- Tombol ✨ hanya tampil jika `aiEnabledProvider` = true (penyedia terpilih punya key).
- API key tersimpan di `flutter_secure_storage` dan **tidak** ikut backup.

## 2. Penyedia & model default
| Penyedia | Endpoint | Model default (`kDefaultModels`) |
|---|---|---|
| Claude (Anthropic) | `POST https://api.anthropic.com/v1/messages` (stream SSE `content_block_delta`) | `claude-haiku-5-5` |
| Gemini (Google) | `POST …/v1beta/models/{model}:streamGenerateContent?alt=sse` | `gemini-2.5-flash` |
| OpenAI | `POST https://api.openai.com/v1/chat/completions` (stream) | `gpt-4.1-mini` |

Nama model bisa diketik bebas di Settings, karena nama model berganti dari waktu ke waktu. Jika muncul error 404, berarti nama model perlu diperbarui.

## 3. Pesan error (sudah di `AiClient`)
| Kondisi | Pesan |
|---|---|
| 401/403 | "API key ditolak. Periksa kembali key di Settings → AI." |
| 404 | "Nama model tidak ditemukan. Periksa nama model di Settings → AI." |
| 429 | "Batas pemakaian/kuota tercapai. Coba lagi nanti." |
| ≥ 500 | "Server penyedia AI sedang bermasalah. Coba lagi nanti." |
| Tanpa internet / timeout 30 dtk | "Tidak bisa terhubung. Periksa koneksi internet." |

## 4. Prompt
### 4.1 System prompt
Lihat `kAiSystemPrompt` (jawab Bahasa Indonesia, berdasar KUTIPAN BUKU, jujur saat tidak yakin, tanpa Markdown, ±180 kata).

### 4.2 Aksi & isi yang dikirim
| Aksi (`AiAction`) | Tempat | target | bookContext |
|---|---|---|---|
| `explainSentence` | tekan lama kalimat (K-4) | `jp` kalimat | judul Tata Bahasa bab + Bunkei bab (+ terjemahan kalimat itu) |
| `whyWrong` | Mondaishuu, soal salah | teks soal (`linesJp` digabung) | judul Tata Bahasa bab-bab set itu |
| `exampleAnswer` | Renshuu B, Mondai buku utama | teks soal / "Nomor q (lihat gambar)" | contoh 例 nomor itu + judul Tata Bahasa + Bunkei |
| `simplerGrammar`, `moreExamples` | layar Tata Bahasa | `titleRich.jp` | seluruh teks blok poin itu |

`bookContext` dipotong maksimal 1500 karakter (potong di akhir baris).

## 5. Panel
- `showAiPanel(context, AiRequest)`: bottom sheet 85% tinggi layar, berisi label AI, jawaban mengalir (streaming), tanya lanjutan, tombol "Minta ulang", dan tombol tutup.
- **Cache:** kunci = `aksi|refId|jawabanPengguna`. Cache dipakai saat membuka ulang; "Minta ulang" mengabaikan cache.
- Tekan lama gelembung jawaban = salin teks.
