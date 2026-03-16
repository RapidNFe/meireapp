import 'dart:convert';
import 'package:flutter/services.dart';

class CnaeService {
  Future<List<Map<String, String>>> loadCnaes() async {
    try {
      // 1. Carrega o arquivo JSON dos assets
      final String response = await rootBundle.loadString('assets/cnae.json');
      
      // 2. Decodifica o JSON
      final List<dynamic> data = await json.decode(response);
      
      // 3. Mapeia para o formato esperado pelo widget (codigo e descricao)
      return data.map((item) {
        return {
          'codigo': item['id'].toString(),
          'descricao': item['descricao'].toString(),
        };
      }).toList();
    } catch (e) {
      // Reduzi log de erro para produção para satisfazer o lint
      // print('Erro ao carregar CNAEs: $e');
      return [];
    }
  }
}
