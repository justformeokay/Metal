import 'package:intl/intl.dart';

/// Currency formatter for Indonesian Rupiah.
String formatCurrency(double amount) {
  final formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );
  return formatter.format(amount);
}

/// Short currency (e.g. 1.5jt, 500rb).
String formatCurrencyShort(double amount) {
  if (amount >= 1000000) {
    return 'Rp ${(amount / 1000000).toStringAsFixed(1)}jt';
  } else if (amount >= 1000) {
    return 'Rp ${(amount / 1000).toStringAsFixed(0)}rb';
  }
  return 'Rp ${amount.toStringAsFixed(0)}';
}

/// Format date for display.
String formatDate(DateTime date) {
  return DateFormat('dd MMM yyyy', 'id_ID').format(date);
}

/// Format date with time.
String formatDateTime(DateTime date) {
  return DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(date);
}

/// Format time only.
String formatTime(DateTime date) {
  return DateFormat('HH:mm', 'id_ID').format(date);
}

/// Format date short (e.g. 09 Mar).
String formatDateShort(DateTime date) {
  return DateFormat('dd MMM', 'id_ID').format(date);
}
