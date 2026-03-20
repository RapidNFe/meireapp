import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketbase/pocketbase.dart';
import '../../../core/services/pocketbase_service.dart';
import '../../auth/services/auth_service.dart';

import '../../clients/models/tomador_model.dart';

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
    String? codigoTributacao,
    String? itemNbs,
    String? competencia,
    TomadorModel? clientModel, // Novo parâmetro!
  }) async {
    final user = _auth.currentUser;
    final userId = user?.id;
    if (userId == null) throw Exception("Usuário não autenticado");

    // 🚀 CHAMADA AO NOVO MOTOR VORTEX (Node.js)
    final String emissionUrl = '${_pb.baseURL}/api/nacional/emitir';
    
    final now = DateTime.now();
    final formattedDate = "${now.toIso8601String().substring(0, 19)}-03:00"; 

    final cleanCnpj = clientCnpj.replaceAll(RegExp(r'[^0-9]'), '');

    try {
      final response = await _dio.post(
        emissionUrl,
        data: {
          "userId": userId,
          "payload": {
            "numeroDPS": (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString(), 
            "numeroSerie": "900",
            "dataHoraEmissao": formattedDate,
            "competencia": competencia, 
            "codigoMunicipioEmissor": user?.getStringValue('codigo_municipio') ?? "5208707",
            "tomador": {
              "cnpj": cleanCnpj,
              "nome": clientName,
              "endereco": {
                "municipio": clientModel?.municipioIbge ?? "5208707", 
                "cep": clientModel?.cep.replaceAll(RegExp(r'[^0-9]'), '') ?? "74820090",
                "logradouro": clientModel?.logradouro ?? "Endereço Fixado",
                "numero": clientModel?.numero ?? "1",
                "bairro": clientModel?.bairro ?? "Centro"
              }
            },
            "servico": {
              "municipioPrestacao": clientModel?.municipioIbge ?? "5208707", 
              "codigoTribNacional": (codigoTributacao ?? "060101")
                  .split(' ')[0]
                  .replaceAll('.', '')
                  .padRight(6, '0'),
              "itemNbs": (itemNbs ?? "126021000")
                  .split(' ')[0]
                  .replaceAll('.', '')
                  .padRight(9, '0'),
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
