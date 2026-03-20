import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketbase/pocketbase.dart';
import '../../../core/services/pocketbase_service.dart';
import '../../auth/services/auth_service.dart';

class CertificateService {
  final PocketBase _pb;
  final AuthService _auth;
  final Dio _dio = Dio();

  CertificateService(this._pb, this._auth);

  Future<void> depositCertificate(File pfxFile, String password) async {
    final userId = _auth.currentUser?.id;
    if (userId == null) throw Exception("Usuário não autenticado");

    // Endpoint do Vault Blindado no Node.js
    final String url = '${_pb.baseURL}/api/vault/deposit';

    try {
      String fileName = pfxFile.path.split('/').last;
      
      final formData = FormData.fromMap({
        'userId': userId,
        'senha_pfx': password,
        'arquivo_pfx': await MultipartFile.fromFile(pfxFile.path, filename: fileName),
      });

      final response = await _dio.post(
        url,
        data: formData,
      );

      if (response.statusCode != 201) {
        throw Exception(response.data['erro'] ?? "Erro ao enviar certificado.");
      }

      // 💡 Atualização Crítica: Recarrega a sessão para que o `possui_certificado` seja refletido no app
      await _pb.collection('users').authRefresh();
    } on DioException catch (e) {
      throw Exception(e.response?.data?['erro'] ?? "Erro de conexão com o servidor.");
    }
  }

  Future<void> updateOnboardingStatus(String status) async {
    final userId = _auth.currentUser?.id;
    if (userId == null) return;

    await _pb.collection('users').update(userId, body: {
      'status_onboarding_nota': status,
    });
  }
}

final certificateServiceProvider = Provider<CertificateService>((ref) {
  return CertificateService(ref.watch(pbProvider), ref.watch(authServiceProvider));
});
