import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meire/core/services/pocketbase_service.dart';
import 'package:pocketbase/pocketbase.dart';

/// Service responsável por gerenciar o status dos lançamentos de serviços
/// após a emissão da NFS-e.
class FechamentoService {
  final PocketBase pb;
  FechamentoService(this.pb);

  /// Marca todos os lançamentos 'pendentes' de um salão como 'emitidos'
  /// e vincula o ID da nota fiscal gerada para auditoria.
  Future<void> realizarFechamento(String salaoId, String nfseId) async {
    try {
      final userId = pb.authStore.record?.id;
      // 1. Busca todos os registros pendentes vinculados a este salão e usuário
      final pendentes = await pb.collection('lancamentos_servicos').getFullList(
            filter: 'salao = "$salaoId" && status = "pendente" && users = "$userId"',
          );

      if (pendentes.isEmpty) {
        debugPrint("ℹ️ Nenhum lançamento pendente encontrado para o salão $salaoId.");
        return;
      }

      // 2. Atualização em Batch (Massa)
      // Usamos Future.wait para disparar as atualizações em paralelo
      await Future.wait(pendentes.map((registro) {
        return pb.collection('lancamentos_servicos').update(registro.id, body: {
          'status': 'emitido',
          'nfse_vinculada': nfseId, // Rastreabilidade total
        });
      }));

      debugPrint("✅ Fechamento concluído: ${pendentes.length} serviços marcados como emitidos.");
    } catch (e) {
      debugPrint("❌ Erro no fechamento: $e");
      rethrow;
    }
  }
}

// Provider para o Service
final fechamentoServiceProvider = Provider<FechamentoService>((ref) {
  final pb = ref.watch(pbProvider);
  return FechamentoService(pb);
});
