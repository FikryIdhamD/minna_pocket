// Prompt AI kata per kata (docs/07_Fitur_AI.md §4). FILE INI DISEDIAKAN LENGKAP. JANGAN DIUBAH.

enum AiAction { explainSentence, whyWrong, exampleAnswer, simplerGrammar, moreExamples }

const kAiSystemPrompt = '''
Kamu adalah tutor bahasa Jepang untuk pelajar Indonesia yang memakai buku Minna no Nihongo Shokyu I.
Aturan:
1. Jawab dalam Bahasa Indonesia yang sederhana. Teks Jepang boleh ditulis dengan kanji, selalu diikuti bacaan hiragana dalam kurung pada kemunculan pertama.
2. Dasarkan penjelasan pada KUTIPAN BUKU yang diberikan. Jangan bertentangan dengan buku.
3. Jika kamu tidak yakin, katakan "Saya tidak yakin" dan jelaskan alasannya. Jangan mengarang aturan tata bahasa.
4. Pakai tata bahasa dan kosakata setingkat bab yang disebutkan atau sebelumnya. Hindari pola dari bab yang jauh lebih lanjut.
5. Tulis teks biasa tanpa format Markdown (tanpa #, **, atau tabel). Boleh memakai daftar bernomor "1." dan baris baru.
6. Maksimal sekitar 180 kata kecuali pengguna meminta lebih.
''';

String _quote(String bookContext) => 'KUTIPAN BUKU:\n"""\n${bookContext.trim()}\n"""';

/// [lesson] nomor bab; [target] teks yang dibahas; [bookContext] isi buku terkait (lihat 07 §4.2).
String buildUserPrompt({
  required AiAction action,
  required int lesson,
  required String target,
  required String bookContext,
  String? userAnswer,
  String? keyAnswer,
}) {
  switch (action) {
    case AiAction.explainSentence:
      return 'Bab $lesson.\nJelaskan kalimat berikut: arti keseluruhan, arti tiap kata/partikel, dan pola kalimatnya.\n'
          'Kalimat: $target\n\n${_quote(bookContext)}';
    case AiAction.whyWrong:
      return 'Bab $lesson.\nSaya mengerjakan soal latihan dan jawaban saya salah.\n'
          'Soal: $target\nJawaban saya: ${userAnswer ?? '-'}\nKunci jawaban buku: ${keyAnswer ?? '-'}\n'
          'Jelaskan kenapa jawaban saya salah dan kenapa kunci jawaban benar. Jangan memberi soal baru.\n\n${_quote(bookContext)}';
    case AiAction.exampleAnswer:
      return 'Bab $lesson.\nBuku tidak menyediakan kunci jawaban untuk soal berikut. Berikan SATU contoh jawaban yang paling wajar '
          'mengikuti pola contoh (例), lalu jelaskan singkat polanya. Tandai dengan jelas bahwa ini contoh dari AI, bukan kunci resmi.\n'
          'Soal: $target\n\n${_quote(bookContext)}';
    case AiAction.simplerGrammar:
      return 'Bab $lesson.\nJelaskan poin tata bahasa berikut dengan bahasa yang lebih sederhana dan beri analogi singkat bila membantu.\n'
          'Poin: $target\n\n${_quote(bookContext)}';
    case AiAction.moreExamples:
      return 'Bab $lesson.\nBerikan 3 contoh kalimat tambahan untuk poin tata bahasa berikut, memakai kosakata dari bab ini atau sebelumnya. '
          'Setiap contoh: kalimat Jepang, bacaan hiragana, arti Indonesia.\nPoin: $target\n\n${_quote(bookContext)}';
  }
}

String aiActionLabel(AiAction a) => switch (a) {
      AiAction.explainSentence => 'Jelaskan kalimat ini',
      AiAction.whyWrong => 'Kenapa salah?',
      AiAction.exampleAnswer => 'Contoh jawaban AI',
      AiAction.simplerGrammar => 'Jelaskan lebih sederhana',
      AiAction.moreExamples => 'Contoh lain',
    };
