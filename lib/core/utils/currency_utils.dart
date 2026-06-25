import 'package:intl/intl.dart';

class CurrencyUtils {
  static final NumberFormat _formatter = NumberFormat('#,##0.00');
  static final NumberFormat _formatterNoDecimal = NumberFormat('#,##0');

  static String format(double amount, {String symbol = 'PKR'}) {
    return '$symbol ${_formatter.format(amount)}';
  }

  static String formatCompact(double amount, {String symbol = 'PKR'}) {
    if (amount >= 1000000) {
      return '$symbol ${(amount / 1000000).toStringAsFixed(2)}M';
    } else if (amount >= 1000) {
      return '$symbol ${(amount / 1000).toStringAsFixed(1)}K';
    }
    return '$symbol ${_formatterNoDecimal.format(amount)}';
  }

  static String formatNumber(double number) => _formatter.format(number);

  static double parse(String value) {
    final cleaned = value.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(cleaned) ?? 0.0;
  }
}

class DateUtils2 {
  static final DateFormat _displayFormat = DateFormat('dd MMM yyyy');
  static final DateFormat _dbFormat = DateFormat('yyyy-MM-dd');
  static final DateFormat _fullFormat = DateFormat('dd MMM yyyy, hh:mm a');

  static String toDisplay(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final date = DateTime.parse(dateStr);
      return _displayFormat.format(date);
    } catch (_) {
      return dateStr;
    }
  }

  static String toDb(DateTime date) => _dbFormat.format(date);
  static String toFull(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final date = DateTime.parse(dateStr);
      return _fullFormat.format(date);
    } catch (_) {
      return dateStr;
    }
  }

  static String today() => _dbFormat.format(DateTime.now());
  static String monthStart() => _dbFormat.format(DateTime(DateTime.now().year, DateTime.now().month, 1));
  static String yearStart() => _dbFormat.format(DateTime(DateTime.now().year, 1, 1));

  static String weekStart() {
    final now = DateTime.now();
    final weekday = now.weekday;
    return _dbFormat.format(now.subtract(Duration(days: weekday - 1)));
  }
}
