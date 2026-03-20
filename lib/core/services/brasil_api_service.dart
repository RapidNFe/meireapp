import 'package:dio/dio.dart';
import 'package:meire/core/services/pocketbase_service.dart';

class BrasilApiService {
  static final Dio _dio = Dio();

  // Retorna um Map com os dados da empresa via BrasilAPI (Direto ou via Gateway)
  static Future<Map<String, dynamic>> buscarCnpj(String cnpj) async {
    final cnpjLimpo = cnpj.replaceAll(RegExp(r'[^0-9]'), '');

    if (cnpjLimpo.length != 14) {
      throw Exception('CNPJ inválido. Digite os 14 números.');
    }

    try {
      // 1. Tentamos a Meire API (Proxy com cache/regras)
      final response = await _dio.get('$meireApiUrl/api/cnpj/$cnpjLimpo');
      
      if (response.statusCode == 200) {
        final data = response.data;
        if (data['sucesso'] != false && data['cnae_fiscal'] != null) {
          return {
            'razao_social': data['razao_social'],
            'nome_fantasia': data['nome_fantasia'],
            'situacao': data['situacao'],
            'cep': data['cep'] ?? '',
            'cnae_fiscal': data['cnae_fiscal'].toString(),
            'cnae_fiscal_descricao': data['cnae_fiscal_descricao'] ?? '',
          };
        }
      }
    } catch (_) {
      // Falha no proxy, tentamos direto
    }

    // 2. Fallback Direto (BrasilAPI) para garantir redundância no onboarding
    try {
      final directResponse = await _dio.get('https://brasilapi.com.br/api/cnpj/v1/$cnpjLimpo');
      if (directResponse.statusCode == 200) {
        final data = directResponse.data;
        return {
          'razao_social': data['razao_social'],
          'nome_fantasia': data['nome_fantasia'],
          'situacao': data['descricao_situacao_cadastral'],
          'cep': data['cep'] ?? '',
          'cnae_fiscal': data['cnae_fiscal']?.toString() ?? '',
          'cnae_fiscal_descricao': data['cnae_fiscal_descricao'] ?? '',
          'logradouro': data['logradouro'] ?? '',
          'numero': data['numero'] ?? 'S/N',
          'bairro': data['bairro'] ?? '',
          'municipio_ibge': data['codigo_municipio']?.toString() ?? '',
          'cidade_nome': data['municipio'] ?? '',
          'uf': data['uf'] ?? '',
        };
      }
      throw Exception('Status ${directResponse.statusCode}');
    } catch (e) {
      throw Exception('Não foi possível validar o CNPJ. Tente preenchimento manual.');
    }
  }
}
