import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meire/core/services/pocketbase_service.dart';
import 'package:meire/features/dashboard/provider/performance_provider.dart';

/// Serviço responsável por consolidar e faturar lançamentos.
class FaturamentoService {
  final Ref ref;

  FaturamentoService(this.ref);

  Future<void> consolidarEFaturar(List<String> ids) async {
    final pb = ref.read(pbProvider);

    try {
      // 1. Simulação de Integração NF-e (O "Pulo do Gato")
      // Aqui seria disparada a chamada para a BrasilAPI ou SEFAZ via Node.js
      await Future.delayed(const Duration(seconds: 2));

      // 2. Atualização em Lote no PocketBase
      for (var id in ids) {
        await pb.collection('servicos').update(id, body: {
          'status_faturamento': 'faturado',
          'data_faturamento': DateTime.now().toIso8601String(),
        });
      }

      // 3. Atualiza os Provedores
      ref.invalidate(performanceVendasProvider);
    } catch (e) {
      rethrow;
    }
  }
}

final faturamentoServiceProvider = Provider((ref) => FaturamentoService(ref));
