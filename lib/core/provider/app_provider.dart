import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AuthStatus {
  unauthenticated,
  registering,
  authenticated
}

class AppState {
  final AuthStatus authStatus;
  final bool isFiscallyActive; // 'Fiscalmente Ativo'
  
  // Dados do usuário (simplificado para o mock)
  final String userName;

  AppState({
    this.authStatus = AuthStatus.unauthenticated,
    this.isFiscallyActive = false,
    this.userName = '',
  });

  AppState copyWith({
    AuthStatus? authStatus,
    bool? isFiscallyActive,
    String? userName,
  }) {
    return AppState(
      authStatus: authStatus ?? this.authStatus,
      isFiscallyActive: isFiscallyActive ?? this.isFiscallyActive,
      userName: userName ?? this.userName,
    );
  }
}

class AppStateNotifier extends StateNotifier<AppState> {
  AppStateNotifier() : super(AppState());

  void setAuthenticated({required String name, bool fiscallyActive = true}) {
    state = state.copyWith(
      authStatus: AuthStatus.authenticated,
      isFiscallyActive: fiscallyActive,
      userName: name,
    );
  }

  void logout() {
    state = AppState();
  }
}

final appProvider = StateNotifierProvider<AppStateNotifier, AppState>((ref) {
  return AppStateNotifier();
});
