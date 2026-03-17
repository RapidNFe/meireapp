import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class Validators {
  static final cnpjMask = MaskTextInputFormatter(
      mask: '##.###.###/####-##', filter: {"#": RegExp(r'[0-9]')});

  static final phoneMask = MaskTextInputFormatter(
      mask: '(##) #####-####', filter: {"#": RegExp(r'[0-9]')});

  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'E-mail é obrigatório';
    }
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(value)) {
      return 'Digite um e-mail válido';
    }
    return null;
  }

  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName é obrigatório';
    }
    return null;
  }

  static String? validateCnpj(String? value) {
    if (value == null || value.isEmpty) {
      return 'CNPJ é obrigatório';
    }
    final cleanValue = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanValue.length != 14) {
      return 'CNPJ inválido';
    }
    return null;
  }
}
