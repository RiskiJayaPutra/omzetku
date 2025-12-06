import 'package:intl/intl.dart';

class CurrencyFormatter {
  static String format(double amount) {
    final formatter = NumberFormat('#,###', 'id_ID');
    return formatter.format(amount.abs()).replaceAll(',', '.');
  }

  static String formatWithPrefix(double amount) {
    final isNegative = amount < 0;
    final formatted = format(amount);
    return '${isNegative ? '-' : ''}Rp $formatted';
  }

  static String formatWithSign(double amount) {
    final isNegative = amount < 0;
    final formatted = format(amount);
    return '${isNegative ? '-' : '+'}Rp $formatted';
  }
}
