import 'package:flutter_riverpod/flutter_riverpod.dart';

class RegistrationState {
  final String fullName;
  final String email;
  final String phone;
  final String govPassword; // Sensitive - government access
  final String appPassword; // Password to login into Meiri
  final String ecacCode;
  final String cpf;

  RegistrationState({
    this.fullName = '',
    this.email = '',
    this.phone = '',
    this.govPassword = '',
    this.appPassword = '',
    this.ecacCode = '',
    this.cpf = '',
  });

  RegistrationState copyWith({
    String? fullName,
    String? email,
    String? phone,
    String? govPassword,
    String? appPassword,
    String? ecacCode,
    String? cpf,
  }) {
    return RegistrationState(
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      govPassword: govPassword ?? this.govPassword,
      appPassword: appPassword ?? this.appPassword,
      ecacCode: ecacCode ?? this.ecacCode,
      cpf: cpf ?? this.cpf,
    );
  }
}

class RegistrationNotifier extends StateNotifier<RegistrationState> {
  RegistrationNotifier() : super(RegistrationState());

  void updateField({
    String? fullName,
    String? email,
    String? phone,
    String? govPassword,
    String? appPassword,
    String? ecacCode,
    String? cpf,
  }) {
    state = state.copyWith(
      fullName: fullName,
      email: email,
      phone: phone,
      govPassword: govPassword,
      appPassword: appPassword,
      ecacCode: ecacCode,
      cpf: cpf,
    );
  }

  void submitData() {
    // Clear sensitive data after submission
    state = RegistrationState();
  }
}

final registrationProvider =
    StateNotifierProvider<RegistrationNotifier, RegistrationState>((ref) {
  return RegistrationNotifier();
});
