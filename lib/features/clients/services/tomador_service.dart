import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meire/core/services/pocketbase_service.dart';
import 'package:meire/core/services/brasil_api_service.dart';
import 'package:meire/features/clients/models/tomador_model.dart';

class TomadorService {
  final Ref ref;
  TomadorService(this.ref);

  /// 🏛️ BUSCA INTELIGENTE (CÉREBRO 2.0)
  /// Ordem: 1. Cache Local (PocketBase) -> 2. BrasilAPI (Externo)
  Future<List<TomadorModel>> buscarInteligente(String query) async {
    final pb = ref.read(pbProvider);
    final userId = pb.authStore.record?.id;
    if (userId == null) return [];

    List<TomadorModel> list = [];

    // ── 1. TENTATIVA LOCAL (CACHE NO POCKETBASE) ───────────────────────────
    try {
      final queryEscaped = query.replaceAll('"', '\\"');
      // Procura em 'clientes_tomadores' (Coleção unificada)
      final localClients = await pb.collection('clientes_tomadores').getList(
            filter: '(cnpj ~ "$queryEscaped" || razao_social ~ "$queryEscaped") && user = "$userId"',
            perPage: 3,
          );
      
      list.addAll(localClients.items.map((e) => TomadorModel.fromRecord(e)));

      // Se temos muitos resultados locais, retornamos logo para velocidade
      if (list.length >= 3) return list;
    } catch (e) {
      debugPrint("⚠️ Erro na busca local: $e");
    }

    // ── 2. TENTATIVA EXTERNA (BRASILAPI) ──────────────────────────────────
    // Se a query parece um CNPJ (com 14 dígitos ou quase isso)
    final digits = query.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length == 14) {
      try {
        final apiResult = await BrasilApiService.buscarCnpj(digits);
        final tomador = TomadorModel.fromBrasilApi({
          'cnpj': digits,
          ...apiResult
        });
        
        // Verifica se já não inserimos (evitar duplicatas local/externo)
        if (!list.any((e) => e.cnpj == digits)) {
          list.add(tomador);
        }
      } catch (_) {
        // Ignora falhas de API externa para não quebrar a UX
      }
    }

    return list;
  }

  /// 🛡️ VALIDAÇÃO DE CONFORMANCE CNAE
  /// Verifica se o CNPJ é de fato de um salão (9602501 ou 9602502)
  bool isCnaeBeleza(String? cnae) {
    if (cnae == null) return false;
    final clean = cnae.replaceAll(RegExp(r'[^0-9]'), '');
    return clean == '9602501' || clean == '9602502';
  }
}

final tomadorServiceProvider = Provider((ref) => TomadorService(ref));

// Provider reativo para busca (Substitui o antigo)
final buscarTomadoresProvider = FutureProvider.family<List<TomadorModel>, String>((ref, query) {
  if (query.trim().length < 3) return []; // Começa a buscar com 3 caracteres
  return ref.read(tomadorServiceProvider).buscarInteligente(query);
});
