// Helper parsing JSON. FILE INI DISEDIAKAN LENGKAP. JANGAN DIUBAH.

typedef JsonMap = Map<String, dynamic>;

List<T> parseList<T>(dynamic v, T Function(JsonMap) f) => v == null
    ? <T>[]
    : (v as List).map((e) => f(e as JsonMap)).toList(growable: false);

List<int> parseIntList(dynamic v) =>
    v == null ? const [] : (v as List).map((e) => e as int).toList(growable: false);

double? parseDouble(dynamic v) => v == null ? null : (v as num).toDouble();

/// Rentang waktu audio dalam detik.
class TimeRange {
  const TimeRange(this.start, this.end);
  final double start;
  final double end;

  static TimeRange? maybe(dynamic v) {
    if (v == null) return null;
    final l = v as List;
    return TimeRange((l[0] as num).toDouble(), (l[1] as num).toDouble());
  }

  Duration get startDuration => Duration(milliseconds: (start * 1000).round());
  Duration get endDuration => Duration(milliseconds: (end * 1000).round());
  bool contains(double sec) => sec >= start && sec < end;
}
