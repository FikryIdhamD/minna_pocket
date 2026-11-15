// Semua teks UI tetap (Bahasa Indonesia). FILE INI DISEDIAKAN LENGKAP. JANGAN DIUBAH.
// Layar WAJIB memakai konstanta ini. Teks lain yang tidak ada di sini ditulis persis seperti
// di docs/05_Spesifikasi_Layar.md (dalam tanda kutip).

abstract final class S {
  // ---- nama bagian
  static const sectionNames = {
    'kosakata': 'Kosa Kata',
    'bunkei': 'Bunkei',
    'reibun': 'Reibun',
    'kaiwa': 'Kaiwa',
    'renshuu_a': 'Renshuu A',
    'renshuu_b': 'Renshuu B',
    'renshuu_c': 'Renshuu C',
    'mondai': 'Mondai',
    'bunpou': 'Tata Bahasa',
    'sankou': 'Kata Referensi',
  };
  static const sectionJp = {
    'bunkei': '文型',
    'reibun': '例文',
    'kaiwa': '会話',
    'renshuu_a': '練習A',
    'renshuu_b': '練習B',
    'renshuu_c': '練習C',
    'mondai': '問題',
  };
  static const sectionTile = {
    'kosakata': '語',
    'bunkei': '文',
    'reibun': '例',
    'kaiwa': '会',
    'renshuu_a': 'A',
    'renshuu_b': 'B',
    'renshuu_c': 'C',
    'mondai': '問',
    'bunpou': '法',
    'sankou': '参',
  };
  static const groupNames = {'materi': 'Materi', 'latihan': 'Latihan', 'penjelasan': 'Penjelasan'};

  // ---- navigasi bawah
  static const tabLearn = 'Belajar';
  static const tabPractice = 'Latihan';
  static const tabHafalan = 'Hafalan';
  static const tabMore = 'Lainnya';

  // ---- umum
  static const appName = 'Minna Pocket';
  static const continueLabel = 'Lanjutkan';
  static const lesson = 'Bab';
  static const number = 'Nomor';
  static const next = 'Berikutnya';
  static const prev = 'Sebelumnya';
  static const done = 'Selesai';
  static const markDone = 'Tandai selesai';
  static const markUndone = 'Batalkan selesai';
  static const retry = 'Coba lagi';
  static const cancel = 'Batal';
  static const save = 'Simpan';
  static const delete = 'Hapus';
  static const close = 'Tutup';
  static const example = '例';
  static const showTranslation = 'Tampilkan terjemahan';
  static const hideTranslation = 'Sembunyikan terjemahan';
  static const loadError = 'Data tidak bisa dimuat.';
  static const emptyBookmarks = 'Belum ada yang disimpan. Tekan ⭐ pada kalimat, kosakata, atau soal untuk menyimpannya.';
  static const emptySearch = 'Tidak ada hasil.';
  static const searchHint = 'Cari kana, kanji, romaji, atau arti…';
  static const syntheticVoice = 'suara sintetis';
  static const noKeyMondai = 'Buku tidak menyertakan kunci jawaban untuk bagian ini. Jawabanmu disimpan, tapi tidak dikoreksi.';
  static const goMondaishuu = 'Latihan bab ini di Mondaishuu';
  static const grammarPanel = 'Tata Bahasa';

  // ---- latihan / Mondaishuu
  static const check = 'Periksa';
  static const tryAgain = 'Coba lagi';
  static const showAnswer = 'Lihat jawaban';
  static const markCorrect = 'Anggap benar';
  static const assisted = 'dibantu';
  static const resetNumber = 'Ulangi nomor ini';
  static const repeatAll = 'Ulangi semua';
  static const repeatWrong = 'Ulangi yang salah/dibantu';
  static const shuffle = 'Acak urutan soal';
  static const typeAnswer = 'Tulis jawaban…';
  static const clearAnswers = 'Hapus jawaban & ulangi';
  static const bestScore = 'Skor terbaik';
  static const modelAnswer = 'Contoh jawaban dari buku';

  // ---- hafalan
  static const reviewToday = 'Ulasan hari ini';
  static const gradeLupa = 'Lupa';
  static const gradeSusah = 'Susah';
  static const gradeBisa = 'Bisa';
  static const gradeMudah = 'Mudah';
  static const showBack = 'Tampilkan jawaban';

  // ---- AI
  static const aiLabel = '✨ Penjelasan AI — bukan dari buku, bisa keliru';
  static const aiNeedsInternet = 'Butuh internet untuk fitur AI.';
  static const aiAskFollowUp = 'Tanya lanjutan…';
  static const aiRefresh = 'Minta ulang';

  // ---- 🚩 / ⭐
  static const flagWrong = 'Tandai salah ketik';
  static const flagNoteHint = 'Catatan (opsional), mis. "furigana seharusnya…"';
  static const flagSaved = 'Ditandai. Ekspor daftar dari Settings.';
  static const bookmarkAdd = 'Simpan';
  static const bookmarkRemove = 'Hapus dari Tersimpan';
  static const copyText = 'Salin teks';
  static const speak = 'Ucapkan';
}
