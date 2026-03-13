import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketbase/pocketbase.dart';
import '../../../core/services/pocketbase_service.dart';
import '../../auth/services/auth_service.dart';

class NotasFiscaisService {
  final PocketBase _pb;
  final AuthService _auth;
  final Dio _dio = Dio();

  NotasFiscaisService(this._pb, this._auth);

  Future<void> addNotaFiscal({
    required String clientName,
    required String clientCnpj,
    required double amount,
    required String description,
  }) async {
    final userId = _auth.currentUser?.id;
    if (userId == null) throw Exception("Usuário não autenticado");

    // 🚀 CHAMADA AO BACKEND SOBERANO (Node.js)
    // O backend irá processar o Serpro, criar o log no PB e retornar o status.
    final String emissionUrl = '${_pb.baseUrl}/api/notas/emitir';

    try {
      final response = await _dio.post(
        emissionUrl,
        data: {
          "userId": userId,
          "tomadorCnpj": clientCnpj.replaceAll(RegExp(r'[^0-9]'), ''),
          "tomadorNome": clientName,
          "valor": amount,
          "servico": description,
        },
      );

      if (response.data['sucesso'] != true) {
        throw Exception(response.data['erro'] ?? "Falha na emissão pelo Governo.");
      }
    } on DioException catch (e) {
      throw Exception("Erro de conexão com o Gateway: ${e.message}");
    }
  }
}

final notasFiscaisServiceProvider = Provider<NotasFiscaisService>((ref) {
  return NotasFiscaisService(
      ref.watch(pbProvider), ref.watch(authServiceProvider));
});
