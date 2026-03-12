import 'package:pocketbase/pocketbase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/pocketbase_service.dart';

class AuthService {
  final PocketBase _pb;

  AuthService(this._pb);

  Future<bool> isServerAvailable() async {
    try {
      await _pb.health.check();
      return true;
    } catch (e) {
      if (e.toString().contains('Connection refused') ||
          e.toString().contains('SocketException')) {
        return false;
      }
      // If it's another error (like 404 but server responded), it's "connected" in this context
      return true;
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String nomeCompleto,
    required String razaoSocial,
    required String cpf,
    required String cnpj,
  }) async {
    try {
      final cleanCpf = cpf.replaceAll(RegExp(r'\D'), '');
      final cleanCnpj = cnpj.replaceAll(RegExp(r'\D'), '');

      // Check if email or CPF already exists locally on PB
      try {
        await _pb.collection('users').getFirstListItem('email="$email"');
        throw Exception('Este e-mail já está cadastrado.');
      } catch (e) {
        if (!e.toString().contains('404')) rethrow;
      }

      try {
        await _pb.collection('users').getFirstListItem('cpf="$cleanCpf"');
        throw Exception('Este CPF já está cadastrado.');
      } catch (e) {
        if (!e.toString().contains('404')) rethrow;
      }
      
      try {
        await _pb.collection('users').getFirstListItem('cnpj="$cleanCnpj"');
        throw Exception('Este CNPJ já está vinculado a uma conta.');
      } catch (e) {
        if (!e.toString().contains('404')) rethrow;
      }

      final body = <String, dynamic>{
        "username":
            email.split('@')[0].replaceAll(RegExp(r'[^a-zA-Z0-9]'), '') +
                DateTime.now().millisecondsSinceEpoch.toString().substring(8),
        "email": email,
        "emailVisibility": true,
        "password": password,
        "passwordConfirm": password,
        "name": nomeCompleto,
        "razao_social": razaoSocial,
        "cpf": cleanCpf,
        "cnpj": cleanCnpj,
        "status_registro": "conta_criada",
        "mei_ativo": true,
        "faturamento_anual": 0.0,
        "producao": false,
      };

      await _pb.collection('users').create(body: body);
      await login(email, password);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> login(String email, String password) async {
    try {
      await _pb.collection('users').authWithPassword(email, password);
    } catch (e) {
      rethrow;
    }
  }

  void logout() {
    _pb.authStore.clear();
  }

  Future<void> authorizeProcuration(String userId) async {
    try {
      await _pb.collection('users').update(userId, body: {
        'status_registro': 'aguardando_procuracao',
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteAccount(String userId) async {
    try {
      await _pb.collection('users').delete(userId);
      logout();
    } catch (e) {
      rethrow;
    }
  }

  bool get isAuthenticated => _pb.authStore.isValid;
  RecordModel? get currentUser => _pb.authStore.record;
}

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.watch(pbProvider));
});
