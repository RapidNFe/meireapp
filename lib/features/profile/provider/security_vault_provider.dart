import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;

class SecurityVaultState {
  final bool isVoterTitleVisible;
  final bool isGovbrVisible;
  final bool isAuthenticating;
  final String? errorMessage;

  SecurityVaultState({
    this.isVoterTitleVisible = false,
    this.isGovbrVisible = false,
    this.isAuthenticating = false,
    this.errorMessage,
  });

  SecurityVaultState copyWith({
    bool? isVoterTitleVisible,
    bool? isGovbrVisible,
    bool? isAuthenticating,
    String? errorMessage,
  }) {
    return SecurityVaultState(
      isVoterTitleVisible: isVoterTitleVisible ?? this.isVoterTitleVisible,
      isGovbrVisible: isGovbrVisible ?? this.isGovbrVisible,
      isAuthenticating:
          isAuthenticating ?? false, // Reset after loading usually
      errorMessage: errorMessage,
    );
  }
}

class SecurityVaultNotifier extends StateNotifier<SecurityVaultState> {
  SecurityVaultNotifier() : super(SecurityVaultState());

  final LocalAuthentication auth = LocalAuthentication();

  Future<bool> _authenticate() async {
    state = state.copyWith(isAuthenticating: true, errorMessage: null);
    try {
      final bool canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await auth.isDeviceSupported();

      if (!canAuthenticate) {
        // Fallback or just allow if device has no security (simulated success)
        // For security apps, you might enforce setting up a PIN/biometrics.
        return true;
      }

      final bool didAuthenticate = await auth.authenticate(
        localizedReason:
            'Por favor, autentique-se para visualizar dados sensíveis',
        options: const AuthenticationOptions(
          biometricOnly: false,
          useErrorDialogs: true,
          stickyAuth: true,
        ),
      );

      state = state.copyWith(isAuthenticating: false);
      return didAuthenticate;
    } on PlatformException catch (e) {
      String msg = 'Erro de autenticação';
      if (e.code == auth_error.notAvailable) {
        // Fallback for missing hardware
        return true;
      } else if (e.code == auth_error.notEnrolled) {
        msg = 'Nenhuma biometria ou PIN cadastrado no aparelho.';
      }

      state = state.copyWith(isAuthenticating: false, errorMessage: msg);
      return false;
    } catch (e) {
      state = state.copyWith(
          isAuthenticating: false,
          errorMessage: 'Erro desconhecido ao autenticar.');
      return false;
    }
  }

  Future<void> revealVoterTitle() async {
    if (state.isVoterTitleVisible) {
      state = state.copyWith(isVoterTitleVisible: false);
      return;
    }
    final authenticated = await _authenticate();
    if (authenticated) {
      state = state.copyWith(isVoterTitleVisible: true);
    }
  }

  Future<void> revealGovbr() async {
    if (state.isGovbrVisible) {
      state = state.copyWith(isGovbrVisible: false);
      return;
    }
    final authenticated = await _authenticate();
    if (authenticated) {
      state = state.copyWith(isGovbrVisible: true);
    }
  }

  void hideAll() {
    state = SecurityVaultState(); // Resets to all hidden
  }
}

final securityVaultProvider =
    StateNotifierProvider<SecurityVaultNotifier, SecurityVaultState>((ref) {
  return SecurityVaultNotifier();
});
