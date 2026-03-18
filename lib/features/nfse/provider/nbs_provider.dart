import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:meire/core/services/pocketbase_service.dart';
import 'package:meire/core/services/empresa_service.dart';

// ---------------------------------------------------------------------------
// Modelo retornado pela busca no PocketBase (mapeamento Goiânia)
// ---------------------------------------------------------------------------
class ServicoTributario {
  final String codigoBusca;
  final String descricaoBusca;
  final String codigoLc116;
  final String descricaoLc116;

  const ServicoTributario({
    required this.codigoBusca,
    required this.descricaoBusca,
    required this.codigoLc116,
    required this.descricaoLc116,
  });

  factory ServicoTributario.fromNbsRecord(Map<String, dynamic> json) {
    return ServicoTributario(
      codigoBusca: json['codigo_nbs']?.toString() ?? '',
      descricaoBusca: json['descricao_nbs']?.toString() ?? '',
      codigoLc116: json['codigo_lc116']?.toString() ?? '',
      descricaoLc116: json['descricao_lc116']?.toString() ?? '',
    );
  }

  factory ServicoTributario.fromCnaeRecord(Map<String, dynamic> json) {
    return ServicoTributario(
      codigoBusca: json['codigo_cnae']?.toString() ?? '',
      descricaoBusca: json['descricao_cnae']?.toString() ?? '',
      codigoLc116: json['codigo_lc116']?.toString() ?? '',
      descricaoLc116: json['descricao_lc116']?.toString() ?? '',
    );
  }

  String get itemNbsFormatado => '$codigoBusca - $descricaoBusca';
  String get codigoTributacaoFormatado => '$codigoLc116 - $descricaoLc116';
}

// ---------------------------------------------------------------------------
// Provider que obtém os CNAEs da Empresa via BrasilAPI (CNPJ logado)
// ---------------------------------------------------------------------------
final cnaesEmpresaProvider = FutureProvider<List<String>>((ref) async {
  final user = ref.watch(userProvider);
  if (user == null) return [];

  final cnpj = user.getStringValue('cnpj');
  if (cnpj.isEmpty) return [];

  return await EmpresaService().buscarCnaesPorCnpj(cnpj);
});

// ---------------------------------------------------------------------------
// Provider que traduz os CNAEs da Empresa em Códigos LC116 Permitidos (Goiânia)
// ---------------------------------------------------------------------------
final lc116PermitidosProvider = FutureProvider<List<String>>((ref) async {
  final cnaesResult = await ref.watch(cnaesEmpresaProvider.future);
  if (cnaesResult.isEmpty) return [];

  final pb = ref.read(pbProvider);

  try {
    // Monta o filtro: codigo_cnae = "9620501" || codigo_cnae = "..."
    final filtroCnaes =
        cnaesResult.map((c) => 'codigo_cnae = "$c"').join(' || ');

    final records = await pb.collection('cnae_correlacao').getFullList(
          filter: '($filtroCnaes)',
        );

    return records.map((e) => e.getStringValue('codigo_lc116')).toSet().toList();
  } catch (e) {
    debugPrint("❌ Erro ao buscar permissões no PocketBase: $e");
    return [];
  }
});

// ---------------------------------------------------------------------------
// Provider de busca inteligente BLINDADA (Filtra pelo que o CNAE permite)
// ---------------------------------------------------------------------------
final buscarServicosProvider =
    FutureProvider.family<List<ServicoTributario>, String>((ref, query) async {
  if (query.trim().length < 3) return [];

  final pb = ref.read(pbProvider);
  final queryEscaped = query.replaceAll('"', '\\"');

  // Aguarda a lista de permissões tributárias da empresa
  final permitidos = await ref.watch(lc116PermitidosProvider.future);

  try {
    // Se não tiver permissões (erro ou CNPJ novo), retornamos busca aberta por 
    // segurança ou mudamos para exibir lista zerada (blindagem total)
    String filterExtra = '';
    if (permitidos.isNotEmpty) {
      final filtroLc116 =
          permitidos.map((p) => 'codigo_lc116 = "$p"').join(' || ');
      filterExtra = ' && ($filtroLc116)';
    }

    // Busca apenas na NBS (que já contém o mapeamento para LC 116 de Goiânia)
    final nbsResult = await pb.collection('nbs_correlacao').getList(
          page: 1,
          perPage: 15,
          filter:
              '(descricao_nbs ~ "$queryEscaped" || codigo_nbs ~ "$queryEscaped")$filterExtra',
        );

    return nbsResult.items
        .map((e) => ServicoTributario.fromNbsRecord(e.toJson()))
        .toList();
  } catch (e) {
    debugPrint("❌ Erro na busca PocketBase: $e");
    return [];
  }
});
