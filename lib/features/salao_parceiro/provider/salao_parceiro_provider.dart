import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meire/core/services/pocketbase_service.dart';
import 'package:meire/features/nfse/services/notas_fiscais_service.dart';
import 'package:meire/features/salao_parceiro/services/fechamento_service.dart';
import 'package:meire/features/salao_parceiro/ui/widgets/resumo_quinzena_card.dart';
import 'package:meire/features/hub/provider/notas_fiscais_provider.dart';

/// Provider que gerencia o estado de fechamento de um salão parceiro.
final salaoParceiroControllerProvider =
    StateNotifierProvider<SalaoParceiroController, AsyncValue<void>>((ref) {
  return SalaoParceiroController(ref);
});

class SalaoParceiroController extends StateNotifier<AsyncValue<void>> {
  final Ref ref;

  SalaoParceiroController(this.ref) : super(const AsyncValue.data(null));

  /// Realiza o fluxo completo de fechamento:
  /// 1. Busca os serviços pendentes para gerar a descrição inteligente.
  /// 2. Emite a Nota Fiscal no Node.js (Vortex).
  /// 3. Se sucesso, marca os serviços como 'emitidos' no PocketBase.
  Future<void> emitirFechamento(
      {required String salaoId,
      required String salaoNome,
      required String salaoCnpj,
      required double valorNota}) async {
    state = const AsyncValue.loading();

    try {
      final pb = ref.read(pbProvider);

      final userId = pb.authStore.record?.id;
      // 1. Busca serviços para extrair o período (Data Início e Fim)
      final pendentes = await pb.collection('lancamentos_servicos').getFullList(
            filter: 'salao = "$salaoId" && status = "pendente" && users = "$userId"',
            sort: 'data_servico',
          );

      if (pendentes.isEmpty) throw Exception("Nenhum serviço pendente.");

      final dataInicio =
          pendentes.first.getStringValue('data_servico').substring(8, 10);
      final dataFim =
          pendentes.last.getStringValue('data_servico').substring(8, 10);
      final mes = DateTime.now().month.toString().padLeft(2, '0');

      // 2. Descrição Inteligente conforme a Lei do Salão Parceiro
      final descricao =
          "Cota-parte profissional parceiro. Ref. período $dataInicio a $dataFim/$mes. Lei 13.352/2016.";

      debugPrint("📝 [Fechamento] Iniciando emissão: $descricao");

      // 3. Chamada ao Node.js (Vortex)
      final response = await ref.read(notasFiscaisServiceProvider).addNotaFiscal(
            clientName: salaoNome,
            clientCnpj: salaoCnpj,
            amount: valorNota,
            description: descricao,
            competencia: DateTime.now().toIso8601String().split('T')[0],
          );

      final nfsId = response != null ? (response as Map)['idNote'] ?? '' : '';

      // 4. Batch Update (Baixa nos Pendentes)
      await ref.read(fechamentoServiceProvider).realizarFechamento(salaoId, nfsId);

      // 5. Atualiza o Dashboard Geral
      ref.invalidate(revenueStatsProvider);
      ref.invalidate(resumoQuinzenaProvider); // Invalida o resumo do card

      state = const AsyncValue.data(null);
    } catch (e, st) {
      debugPrint("❌ Erro no fluxo de fechamento: $e");
      state = AsyncValue.error(e, st);
    }
  }
}
