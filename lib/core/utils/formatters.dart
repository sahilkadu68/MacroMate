import 'package:intl/intl.dart';

class Formatters {
  static final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 1,
  );

  static final NumberFormat _wholeCurrencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  static final NumberFormat _wholeNumberFormat = NumberFormat('#,##0', 'en_IN');

  static String currency(double? amount, {bool showDecimals = true}) {
    if (amount == null) return '₹0';
    if (showDecimals && amount % 1 != 0) {
      return _currencyFormat.format(amount);
    }
    return _wholeCurrencyFormat.format(amount);
  }

  static String calories(double? kcal) {
    if (kcal == null) return '0 kcal';
    return '${_wholeNumberFormat.format(kcal.round())} kcal';
  }

  static String grams(double? val, {int decimals = 1}) {
    if (val == null) return '0g';
    if (val % 1 == 0) {
      return '${val.toInt()}g';
    }
    return '${val.toStringAsFixed(decimals)}g';
  }

  static String ml(double? val) {
    if (val == null) return '0 ml';
    return '${val.round()} ml';
  }

  static String weight(double? kg) {
    if (kg == null) return '-- kg';
    return '${kg.toStringAsFixed(1)} kg';
  }

  static String efficiency(double? proteinPerRupee) {
    if (proteinPerRupee == null ||
        proteinPerRupee <= 0 ||
        proteinPerRupee.isInfinite ||
        proteinPerRupee.isNaN) {
      return 'N/A';
    }
    return '${proteinPerRupee.toStringAsFixed(2)} g/₹';
  }

  static String percentage(double? ratio) {
    if (ratio == null || ratio.isNaN || ratio.isInfinite) return '0%';
    return '${(ratio * 100).clamp(0, 999).round()}%';
  }

  static String formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);

    if (target == today) return 'Today';
    if (target == today.subtract(const Duration(days: 1))) return 'Yesterday';
    if (target == today.add(const Duration(days: 1))) return 'Tomorrow';

    if (date.year == now.year) {
      return DateFormat('EEE, d MMM').format(date);
    }
    return DateFormat('d MMM yyyy').format(date);
  }

  static String formatShortDate(DateTime date) {
    return DateFormat('d MMM').format(date);
  }

  static String formatDayOfWeek(DateTime date) {
    return DateFormat('E').format(date);
  }

  static String toIsoDateOnly(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  static DateTime parseIsoDate(String dateStr) {
    return DateTime.parse(dateStr);
  }
}
