import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }

    // Only numbers
    String cleanText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    
    // Parse to double considering last two digits as cents
    double value = double.tryParse(cleanText) ?? 0;
    value = value / 100;

    final formatter = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    String formattedString = formatter.format(value);

    return TextEditingValue(
      text: formattedString,
      selection: TextSelection.collapsed(offset: formattedString.length),
    );
  }
}
