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

    String? municipioIbge;
    Map<String, dynamic>? finalData;

    try {
      // 1. Tentamos a Meire API (Proxy com cache/regras)
      final response = await _dio.get('$meireApiUrl/api/cnpj/$cnpjLimpo');
      
      if (response.statusCode == 200) {
        final data = response.data;
        if (data['sucesso'] != false && data['cnae_fiscal'] != null) {
          finalData = {
            'razao_social': data['razao_social'],
            'nome_fantasia': data['nome_fantasia'],
            'situacao': data['situacao'],
            'cep': data['cep'] ?? '',
            'cnae_fiscal': data['cnae_fiscal'].toString(),
            'cnae_fiscal_descricao': data['cnae_fiscal_descricao'] ?? '',
            'municipio_ibge': data['municipio_ibge']?.toString() ?? '',
          };
          municipioIbge = finalData['municipio_ibge'];
        }
      }
    } catch (_) {}

    // 2. Fallback Direto (BrasilAPI) ou Complementação via CEP
    if (finalData == null) {
      try {
        final directResponse = await _dio.get('https://brasilapi.com.br/api/cnpj/v1/$cnpjLimpo');
        if (directResponse.statusCode == 200) {
          final data = directResponse.data;
          finalData = {
            'razao_social': data['razao_social'],
            'nome_fantasia': data['nome_fantasia'],
            'situacao': data['descricao_situacao_cadastral'],
            'cep': data['cep'] ?? '',
            'cnae_fiscal': data['cnae_fiscal']?.toString() ?? '',
            'cnae_fiscal_descricao': data['cnae_fiscal_descricao'] ?? '',
            'cnaes_secundarios': data['cnaes_secundarios'] ?? [],
            'logradouro': data['logradouro'] ?? '',
            'numero': data['numero'] ?? 'S/N',
            'bairro': data['bairro'] ?? '',
            'municipio_ibge': '', // Ignoramos o TOM/SIAFI de 4 dígitos (codigo_municipio)
            'cidade_nome': data['municipio'] ?? '',
            'uf': data['uf'] ?? '',
          };
        }
      } catch (e) {
        throw Exception('Não foi possível validar o CNPJ. Tente preenchimento manual.');
      }
    }

    // 🛡️ GARANTIR IBGE DE 7 DÍGITOS (Double Match via CEP)
    if (finalData != null && (municipioIbge == null || municipioIbge.length != 7)) {
      try {
        final cepLimpo = finalData['cep'].replaceAll(RegExp(r'\D'), '');
        if (cepLimpo.length == 8) {
          final cepData = await buscarCep(cepLimpo);
          finalData['municipio_ibge'] = cepData['codigo_ibge']?.toString() ?? '';
        }
      } catch (_) {
        // Se falhar o lookup do CEP, mantemos o que tem
      }
    }

    if (finalData == null) throw Exception('Dados não encontrados.');
    return finalData;
  }

  // Retorna dados do CEP incluindo Código IBGE (Endpoint V2 da BrasilAPI)
  static Future<Map<String, dynamic>> buscarCep(String cep) async {
    final cepLimpo = cep.replaceAll(RegExp(r'\D'), '');
    try {
      final response = await _dio.get('https://brasilapi.com.br/api/cep/v2/$cepLimpo');
      if (response.statusCode == 200) {
        final data = response.data;
        String codigoIbge = data['ibge']?.toString() ?? '';

        // 🛡️ Fallback: Se a BrasilAPI V2 não retornar o IBGE direto
        if (codigoIbge.isEmpty && data['state'] != null && data['city'] != null) {
          try {
            final ibgeResponse = await _dio.get('https://brasilapi.com.br/api/ibge/municipios/v1/${data['state']}');
            if (ibgeResponse.statusCode == 200 && ibgeResponse.data is List) {
              final municipios = ibgeResponse.data as List;
              final municipio = municipios.firstWhere(
                  (m) => m['nome']?.toString().toUpperCase() == data['city']?.toString().toUpperCase(),
                  orElse: () => null);
              if (municipio != null) {
                codigoIbge = municipio['codigo_ibge']?.toString() ?? '';
              }
            }
          } catch (_) {
            // Ignora falha silenciosamente e mantém vazio ou o que tiver retornado
          }
        }

        return {
          'cep': data['cep'],
          'city': data['city'],
          'state': data['state'],
          'street': data['street'],
          'neighborhood': data['neighborhood'],
          'service': data['service'],
          'codigo_ibge': codigoIbge,
        };
      }
      throw Exception('Falha ao buscar CEP');
    } catch (e) {
      rethrow;
    }
  }
}
