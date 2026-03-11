import 'package:dio/dio.dart';

class NbsService {
  final Dio _dio = Dio();

  Future<List<Map<String, dynamic>>> fetchNbsCodes() async {
    try {
      final response = await _dio.get('https://servicodados.ibge.gov.br/api/v1/produtos/nbs');
      if (response.statusCode == 200) {
        // Expected response is a List of dynamic objects representing the NBS nodes
        if (response.data is List) {
          return List<Map<String, dynamic>>.from(response.data);
        }
      }
      return [];
    } catch (e) {
      // Idealmente, dispararia um Log service / Crashlytics aqui
      // Retornamos lista vazia para o provider tratar/mostrar estado nulo
      return [];
    }
  }
}
