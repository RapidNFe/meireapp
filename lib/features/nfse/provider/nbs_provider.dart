import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meire/core/services/pocketbase_service.dart';

// ---------------------------------------------------------------------------
// Modelo retornado pela busca no PocketBase (mapeamento Goiânia)
// ---------------------------------------------------------------------------
class ServicoTributario {
  final String codigoBusca;      // Código original (CNAE ou NBS)
  final String descricaoBusca;   // Descrição original
  final String codigoLc116;      // Código da Lei 116 (Municipal Goiânia)
  final String descricaoLc116;   // Nome da Atividade no LC 116

  const ServicoTributario({
    required this.codigoBusca,
    required this.descricaoBusca,
    required this.codigoLc116,
    required this.descricaoLc116,
  });

  factory ServicoTributario.fromNbsRecord(Map<String, dynamic> json) {
    return ServicoTributario(
      codigoBusca:    json['codigo_nbs']?.toString() ?? '',
      descricaoBusca: json['descricao_nbs']?.toString() ?? '',
      codigoLc116:    json['codigo_lc116']?.toString() ?? '',
      descricaoLc116: json['descricao_lc116']?.toString() ?? '',
    );
  }

  factory ServicoTributario.fromCnaeRecord(Map<String, dynamic> json) {
    return ServicoTributario(
      codigoBusca:    json['codigo_cnae']?.toString() ?? '',
      descricaoBusca: json['descricao_cnae']?.toString() ?? '',
      codigoLc116:    json['codigo_lc116']?.toString() ?? '',
      descricaoLc116: json['descricao_lc116']?.toString() ?? '',
    );
  }

  /// Texto formatado para o campo NBS (se for NBS)
  String get itemNbsFormatado => '$codigoBusca - $descricaoBusca';

  /// Texto formatado para o campo Código de Tributação ( Municipal )
  String get codigoTributacaoFormatado => '$codigoLc116 - $descricaoLc116';
}

// ---------------------------------------------------------------------------
// Provider de busca inteligente (CNAE ou NBS)
// ---------------------------------------------------------------------------
final buscarServicosProvider =
    FutureProvider.family<List<ServicoTributario>, String>((ref, query) async {
  if (query.trim().length < 3) return [];

  final pb = ref.read(pbProvider);
  final queryEscaped = query.replaceAll('"', '\\"');

  try {
    // 1. Tenta buscar primeiro na NBS (Nomenclatura Brasileira de Serviços)
    final nbsResult = await pb.collection('nbs_correlacao').getList(
      page: 1,
      perPage: 10,
      filter: 'descricao_nbs ~ "$queryEscaped" || codigo_nbs ~ "$queryEscaped"',
    );

    List<ServicoTributario> servicos = nbsResult.items
        .map((e) => ServicoTributario.fromNbsRecord(e.toJson()))
        .toList();

    // 2. Se trouxer poucos resultados, busca também na CNAE (Classificação de Atividades)
    if (servicos.length < 5) {
      final cnaeResult = await pb.collection('cnae_correlacao').getList(
        page: 1,
        perPage: 10,
        filter: 'descricao_cnae ~ "$queryEscaped" || codigo_cnae ~ "$queryEscaped"',
      );
      
      final deCnae = cnaeResult.items
          .map((e) => ServicoTributario.fromCnaeRecord(e.toJson()));
      
      servicos.addAll(deCnae);
    }

    return servicos;
  } catch (e) {
    return [];
  }
});
