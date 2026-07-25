/// Utilitários para trabalhar com datas "sem hora" (comparações de vencimento).
class DateOnly {
  static DateTime today() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  static DateTime of(DateTime d) => DateTime(d.year, d.month, d.day);

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Soma [months] meses preservando o dia (com ajuste para meses curtos).
  static DateTime addMonths(DateTime date, int months) {
    final zeroBased = date.month - 1 + months;
    // floor division para lidar corretamente com meses negativos.
    final year = date.year + (zeroBased / 12).floor();
    final month = zeroBased % 12 + 1; // % em Dart é sempre >= 0 para divisor > 0
    final lastDay = DateTime(year, month + 1, 0).day;
    final day = date.day > lastDay ? lastDay : date.day;
    return DateTime(year, month, day);
  }
}
