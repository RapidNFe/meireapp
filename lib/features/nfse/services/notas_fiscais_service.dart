import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketbase/pocketbase.dart';
import '../../../core/services/pocketbase_service.dart';
import '../../auth/services/auth_service.dart';

class NotasFiscaisService {
  final PocketBase _pb;
  final AuthService _auth;

  NotasFiscaisService(this._pb, this._auth);

  Future<void> addNotaFiscal({
    required String clientName,
    required String clientCnpj,
    required double amount,
    required String description,
  }) async {
    final body = <String, dynamic>{
      "tomador_nome": clientName,
      "tomador_documento": clientCnpj,
      "valor": amount,
      "descricao": description,
      "status": "Emitida",
      "emissao": DateTime.now().toIso8601String(),
    };

    if (_auth.isAuthenticated && _auth.currentUser != null) {
      body["user"] = _auth.currentUser!.id;
    }

    await _pb.collection('notas_fiscais').create(body: body);
  }
}

final notasFiscaisServiceProvider = Provider<NotasFiscaisService>((ref) {
  return NotasFiscaisService(
      ref.watch(pbProvider), ref.watch(authServiceProvider));
});
