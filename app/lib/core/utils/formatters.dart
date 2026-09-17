import 'package:intl/intl.dart';

/// Money and date formatting for the ru locale.
///
/// Amounts are always formatted through [NumberFormat] — never assembled from
/// strings — so that the decimal separator and grouping stay consistent.
abstract final class Formatters {
  static const String locale = 'ru';

  static const Map<String, String> _currencySymbols = {
    'MDL': 'L',
    'EUR': '€',
    'USD': '\$',
  };

  static String currencySymbol(String currency) =>
      _currencySymbols[currency] ?? currency;

  /// `1 234,50 L` — the amount without a direction sign.
  static String money(double amount, String currency) {
    return NumberFormat.currency(
      locale: locale,
      symbol: currencySymbol(currency),
      decimalDigits: 2,
    ).format(amount);
  }

  /// `+1 234,50 L` / `−1 234,50 L`, using a real minus sign.
  static String signedMoney(
    double amount,
    String currency, {
    bool isIncome = true,
  }) {
    final formatted = money(amount.abs(), currency);
    return isIncome ? '+$formatted' : '−$formatted';
  }

  /// `1 235 L` — rounded, for compact places such as chart legends.
  static String compactMoney(double amount, String currency) {
    return NumberFormat.currency(
      locale: locale,
      symbol: currencySymbol(currency),
      decimalDigits: 0,
    ).format(amount);
  }

  /// `31,7 %`
  static String percent(double ratio) {
    return NumberFormat.decimalPercentPattern(
      locale: locale,
      decimalDigits: ratio >= 0.1 ? 0 : 1,
    ).format(ratio);
  }

  /// `18 сентября 2026`
  static String fullDate(DateTime date) =>
      DateFormat('d MMMM y', locale).format(date.toLocal());

  /// `18 сент.`
  static String shortDate(DateTime date) =>
      DateFormat('d MMM', locale).format(date.toLocal());

  /// `18 сентября, 16:05`
  static String dateWithTime(DateTime date) =>
      DateFormat('d MMMM, HH:mm', locale).format(date.toLocal());

  /// `Сентябрь 2026`
  static String monthTitle(DateTime month) {
    final formatted = DateFormat('LLLL y', locale).format(month);
    return formatted.isEmpty
        ? formatted
        : formatted[0].toUpperCase() + formatted.substring(1);
  }

  /// `2026-09` — the month key used by budgets.
  static String monthKey(DateTime month) =>
      DateFormat('yyyy-MM').format(DateTime(month.year, month.month));

  /// Date header for the grouped transaction list: `Сегодня`, `Вчера`
  /// or `18 сентября`.
  static String dayHeader(DateTime date, {DateTime? today}) {
    final now = today ?? DateTime.now();
    final local = date.toLocal();
    final day = DateTime(local.year, local.month, local.day);
    final reference = DateTime(now.year, now.month, now.day);
    final difference = reference.difference(day).inDays;

    if (difference == 0) {
      return 'Сегодня';
    }
    if (difference == 1) {
      return 'Вчера';
    }
    if (day.year == reference.year) {
      return DateFormat('d MMMM', locale).format(day);
    }
    return DateFormat('d MMMM y', locale).format(day);
  }
}
