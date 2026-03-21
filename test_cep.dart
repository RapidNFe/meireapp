import 'package:flutter/foundation.dart';
import 'package:meire/core/services/brasil_api_service.dart';

void main() async {
  try {
    // Usando o CEP sugerido na mensagem original do Gemini
    const cep = '74255480';
    debugPrint('Teste de busca do CEP: $cep');
    final dados = await BrasilApiService.buscarCep(cep);
    
    debugPrint('Resultado da consulta:');
    debugPrint(dados.toString());
  } catch (e) {
    debugPrint('Erro ao buscar CEP: $e');
  }
}
