import 'dart:convert';
import 'dart:typed_data';
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

  Future<dynamic> addNotaFiscal({
    required String clientName,
    required String clientCnpj,
    required double amount,
    required String description,
    String? competencia,
    String? cnae,
  }) async {
    final userId = _auth.currentUser?.id;
    if (userId == null) throw Exception("Usuário não autenticado");

    // 🚀 CHAMADA AO NOVO MOTOR VORTEX (Node.js)
    final String emissionUrl = '${_pb.baseURL}/api/nacional/emitir';
    
    final now = DateTime.now();
    final formattedDate = "${now.toIso8601String().substring(0, 19)}-03:00"; // Simplificado para teste

    try {
      final response = await _dio.post(
        emissionUrl,
        data: {
          "userId": userId,
          "payload": {
            "numeroDPS": (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString(), // Número único baseado em tempo
            "numeroSerie": "900",
            "dataHoraEmissao": formattedDate,
            "competencia": competencia ?? "${now.year}-${now.month.toString().padLeft(2, '0')}-01",
            "codigoMunicipioEmissor": _auth.currentUser?.getStringValue('codigo_municipio') ?? "5208707",
            "tomador": {
              "cnpj": clientCnpj.replaceAll(RegExp(r'[^0-9]'), ''),
              "nome": clientName,
              "endereco": {
                "municipio": "5208707", // Ideal seria vir do cadastro do cliente
                "cep": "74820090",
                "logradouro": "Endereço Fixado",
                "numero": "1",
                "bairro": "Centro"
              }
            },
            "servico": {
              "municipioPrestacao": "5208707",
              "codigoTribNacional": cnae?.replaceAll(RegExp(r'[^0-9]'), '') ?? "060101",
              "descricao": description,
              "valor": amount.toStringAsFixed(2),
            }
          }
        },
      );

      if (response.data['sucesso'] != true) {
        final erros = response.data['erros'] as List?;
        final msg = erros != null ? erros.map((e) => e['Descricao']).join(', ') : "Falha na emissão.";
        throw Exception(msg);
      }
      
      return response.data;
    } on DioException catch (e) {
      throw Exception("Erro de conexão com o Gateway: ${e.response?.data?['erro'] ?? e.message}");
    }
  }

  Future<Uint8List> getDanfsePdf(String chaveAcesso) async {
    final userId = _auth.currentUser?.id;
    if (userId == null) throw Exception("Usuário não autenticado");

    final String pdfUrl = '${_pb.baseURL}/api/nacional/danfse/$userId/$chaveAcesso';

    try {
      final response = await _dio.get(pdfUrl);

      if (response.data['sucesso'] == true && response.data['pdfBase64'] != null) {
        final String base64Pdf = response.data['pdfBase64'];
        return base64Decode(base64Pdf);
      } else {
        throw Exception(response.data['erro'] ?? "Falha ao obter o PDF da nota.");
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception("ERRO_404: O Governo ainda não gerou o PDF. Tente novamente em 1 minuto.");
      }
      throw Exception("Erro ao buscar PDF: ${e.message}");
    }
  }
}

final notasFiscaisServiceProvider = Provider<NotasFiscaisService>((ref) {
  return NotasFiscaisService(
      ref.watch(pbProvider), ref.watch(authServiceProvider));
});
