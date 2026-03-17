import 'package:dio/dio.dart';
import 'package:meiri/core/services/pocketbase_service.dart';

class BrasilApiService {
  static final Dio _dio = Dio();

  // Retorna um Map com os dados da empresa via nosso Backend Meiri
  static Future<Map<String, dynamic>> buscarCnpj(String cnpj) async {
    final cnpjLimpo = cnpj.replaceAll(RegExp(r'[^0-9]'), '');

    if (cnpjLimpo.length != 14) {
      throw Exception('CNPJ inválido. Digite os 14 números.');
    }

    try {
      // Usamos a Meiri API para centralizar a busca e evitar CORS/Bloqueios
      final response = await _dio.get('$meiriApiUrl/api/cnpj/$cnpjLimpo');

      if (response.statusCode == 200) {
        final data = response.data;
        
        if (data['sucesso'] == false) {
           throw Exception(data['erro'] ?? 'Erro desconhecido no CNPJ');
        }

        return {
          'razao_social': data['razao_social'],
          'nome_fantasia': data['nome_fantasia'],
          'situacao': data['situacao'],
        };
      } else {
        throw Exception('O servidor do CNPJ está instável. Tente novamente.');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('CNPJ não encontrado na base da Receita.');
      }
      final serverMsg = e.response?.data?['erro'];
      throw Exception(serverMsg ?? 'Sem conexão com o servidor Meiri.');
    } catch (e) {
      throw Exception('Erro ao validar CNPJ: $e');
    }
  }
}
