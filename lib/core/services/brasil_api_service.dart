import 'package:dio/dio.dart';

class BrasilApiService {
  static const String _baseUrl = 'https://brasilapi.com.br/api/cnpj/v1';
  static final Dio _dio = Dio();

  // Retorna um Map com os dados da empresa ou lança uma exceção se der erro
  static Future<Map<String, dynamic>> buscarCnpj(String cnpj) async {
    // 1. Limpa o CNPJ (remove pontos, barras e traços)
    final cnpjLimpo = cnpj.replaceAll(RegExp(r'[^0-9]'), '');

    if (cnpjLimpo.length != 14) {
      throw Exception('CNPJ inválido. Digite os 14 números.');
    }

    try {
      final response = await _dio.get('$_baseUrl/$cnpjLimpo');

      if (response.statusCode == 200) {
        final data = response.data;
        
        // Verifica se a empresa está ativa
        if (data['descricao_situacao_cadastral'] != 'ATIVA') {
          throw Exception('Este CNPJ não está ATIVO na Receita Federal.');
        }

        String razaoSocialRaw = data['razao_social'] ?? '';
        String nomeFantasiaRaw = data['nome_fantasia'] ?? razaoSocialRaw;

        return {
          'razao_social': razaoSocialRaw.trim(),
          'nome_fantasia': nomeFantasiaRaw.trim(),
          'situacao': data['descricao_situacao_cadastral'],
        };
      } else {
        throw Exception('Erro ao consultar o CNPJ. Tente novamente mais tarde.');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('CNPJ não encontrado na base da Receita.');
      }
      throw Exception('Sem conexão com a internet ou erro na API: ${e.message}');
    } catch (e) {
      throw Exception('Erro inesperado: $e');
    }
  }
}
