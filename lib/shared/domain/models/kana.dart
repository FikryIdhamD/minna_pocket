// Tabel kana (assets/<book>/extras/kana.json, dari はじめに buku utama).
// FILE INI DISEDIAKAN LENGKAP. JANGAN DIUBAH.

import 'json_utils.dart';

class KanaCell {
  const KanaCell({required this.kana, required this.romaji});
  final String kana;
  final String romaji;
  factory KanaCell.fromJson(JsonMap j) => KanaCell(kana: j['kana'] as String, romaji: j['ro'] as String);
}

class KanaTable {
  const KanaTable({required this.id, required this.title, required this.rows});
  final String id; // "seion" | "dakuon" | "youon" | "youon_dakuon"
  final String title; // label Indonesia
  /// Baris tabel. Sel null = kosong (mis. baris や: や (い) ゆ (え) よ).
  final List<List<KanaCell?>> rows;
  factory KanaTable.fromJson(JsonMap j) => KanaTable(
        id: j['id'] as String,
        title: j['title'] as String,
        rows: (j['rows'] as List)
            .map((r) => (r as List).map((c) => c == null ? null : KanaCell.fromJson(c as JsonMap)).toList(growable: false))
            .toList(growable: false),
      );
  Iterable<KanaCell> get cells => rows.expand((r) => r).whereType<KanaCell>();
}

class KanaChart {
  const KanaChart({required this.hiragana, required this.katakana, required this.sourcePage});
  final List<KanaTable> hiragana;
  final List<KanaTable> katakana;
  final int sourcePage;
  factory KanaChart.fromJson(JsonMap j) => KanaChart(
        hiragana: parseList(j['hiragana'], KanaTable.fromJson),
        katakana: parseList(j['katakana'], KanaTable.fromJson),
        sourcePage: j['source_pdf_page'] as int,
      );
}
