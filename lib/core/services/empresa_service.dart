import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class EmpresaService {
  final Dio _dio = Dio();

  /// Busca os CNAEs de um CNPJ usando a BrasilAPI
  Future<List<String>> buscarCnaesPorCnpj(String cnpj) async {
    final cleanCnpj = cnpj.replaceAll(RegExp(r'\D'), '');
    if (cleanCnpj.isEmpty) return [];

    try {
      final response = await _dio.get('https://brasilapi.com.br/api/cnpj/v1/$cleanCnpj');
      
      if (response.statusCode == 200) {
        final data = response.data;
        List<String> cnaes = [];

        // Adiciona CNAE Principal
        if (data['cnae_fiscal'] != null) {
          cnaes.add(data['cnae_fiscal'].toString());
        }

        // Adiciona CNAEs Secundários (se houver)
        if (data['cnaes_secundarios'] != null) {
          for (var item in data['cnaes_secundarios']) {
            if (item['codigo'] != null) {
              cnaes.add(item['codigo'].toString());
            }
          }
        }

        return cnaes;
      }
      return [];
    } catch (e) {
      // debugPrint é a forma correta de logar no Flutter evitando logs em produção
      debugPrint("❌ Erro ao consultar BrasilAPI: $e");
      return [];
    }
  }
}
