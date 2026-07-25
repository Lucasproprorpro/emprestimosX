import 'package:intl/intl.dart';

/// Formatação de moeda e datas. A moeda é configurável nas Configurações.
class Formatters {
  static String currencySymbol = 'R\$';
  static String locale = 'pt_BR';

  static String money(num value) {
    final f = NumberFormat.currency(
      locale: locale,
      symbol: '$currencySymbol ',
      decimalDigits: 2,
    );
    return f.format(value);
  }

  static String moneyCompact(num value) {
    if (value.abs() >= 1000000) {
      return '$currencySymbol ${(value / 1000000).toStringAsFixed(1)}M';
    }
    if (value.abs() >= 1000) {
      return '$currencySymbol ${(value / 1000).toStringAsFixed(1)}k';
    }
    return money(value);
  }

  static String percent(num value) =>
      '${value.toStringAsFixed(value == value.roundToDouble() ? 0 : 2)}%';

  static String date(DateTime d) => DateFormat('dd/MM/yyyy', locale).format(d);

  static String dateTime(DateTime d) =>
      DateFormat('dd/MM/yyyy HH:mm', locale).format(d);

  static String weekdayShort(DateTime d) =>
      DateFormat('EEE', locale).format(d);

  static String monthYear(DateTime d) => DateFormat('MMM/yy', locale).format(d);
}
