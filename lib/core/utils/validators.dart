import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class Validators {
  static final cpfMask = MaskTextInputFormatter(
      mask: '###.###.###-##', filter: {"#": RegExp(r'[0-9]')});

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

  static String? validateCpf(String? value) {
    if (value == null || value.isEmpty) {
      return 'CPF é obrigatório';
    }
    final cleanValue = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanValue.length != 11) {
      return 'CPF inválido';
    }
    return isValidCPF(cleanValue) ? null : 'CPF inválido';
  }

  static String? validateCpfCnpj(String? value) {
    if (value == null || value.isEmpty) {
      return 'Documento é obrigatório';
    }
    final cleanValue = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanValue.length == 11) {
      return isValidCPF(cleanValue) ? null : 'CPF inválido';
    }
    if (cleanValue.length != 14) {
      return 'Documento inválido';
    }
    return null;
  }

  static bool isValidCPF(String cpf) {
    // Remove caracteres não numéricos
    cpf = cpf.replaceAll(RegExp(r'\D'), '');

    if (cpf.length != 11) return false;

    // Bloqueia sequências repetidas (ex: 111.111.111-11)
    if (RegExp(r'^(\d)\1+$').hasMatch(cpf)) return false;

    // Cálculo do primeiro dígito verificador
    int temp = 0;
    for (int i = 0; i < 9; i++) {
      temp += int.parse(cpf[i]) * (10 - i);
    }
    int d1 = 11 - (temp % 11);
    if (d1 > 9) d1 = 0;

    // Cálculo do segundo dígito verificador
    temp = 0;
    for (int i = 0; i < 10; i++) {
      temp += int.parse(cpf[i]) * (11 - i);
    }
    int d2 = 11 - (temp % 11);
    if (d2 > 9) d2 = 0;

    return cpf[9] == d1.toString() && cpf[10] == d2.toString();
  }
}
