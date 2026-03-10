import 'package:flutter/services.dart';

/// Formatter untuk rupiah dengan pemisah ribuan
class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Hapus semua karakter non-digit
    String text = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    if (text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Format dengan pemisah ribuan
    String formatted = _formatCurrency(text);

    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  String _formatCurrency(String text) {
    // Konversi ke integer dan kembali ke string untuk hapus leading zeros
    int value = int.parse(text);
    String formatted = value.toString();

    // Tambah titik setiap 3 digit dari kanan
    List<String> parts = [];
    for (int i = formatted.length; i > 0; i -= 3) {
      int start = (i - 3) < 0 ? 0 : (i - 3);
      parts.insert(0, formatted.substring(start, i));
    }

    return parts.join('.');
  }
}

/// Extension untuk mendapatkan nilai numerik dari formatted currency
extension NumericValue on String {
  int getNumericValue() {
    return int.parse(replaceAll('.', ''));
  }
}
