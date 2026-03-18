import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meire/core/services/pocketbase_service.dart';

/// Provider que consolida os dados de performance financeira do mês atual.
/// Separa o que é Faturamento Bruto do que é a Cota-Parte (Líquido) do profissional.
final performanceSoberaniaProvider = FutureProvider<Map<String, double>>((ref) async {
  final pb = ref.read(pbProvider);
  final userId = pb.authStore.record?.id;

  if (userId == null) return {'bruto': 0, 'liquido': 0, 'repasse_salao': 0};

  // 1. Define o início do mês atual para o filtro
  final agora = DateTime.now();
  final inicioMes = DateTime(agora.year, agora.month, 1).toIso8601String();

  try {
    // 2. Busca todos os lançamentos do mês para o usuário logado
    final registros = await pb.collection('lancamentos_servicos').getFullList(
          filter: 'user = "$userId" && data_servico >= "$inicioMes"',
        );

    double faturamentoBruto = 0; // Total pago pelos clientes
    double minhaParteReal = 0;   // O que o profissional de fato ganhou (cota-parte)

    for (var reg in registros) {
      faturamentoBruto += (reg.data['valor_total_cliente'] ?? 0.0).toDouble();
      minhaParteReal += (reg.data['valor_cota_parte'] ?? 0.0).toDouble();
    }

    return {
      'bruto': faturamentoBruto,
      'liquido': minhaParteReal,
      'repasse_salao': faturamentoBruto - minhaParteReal,
    };
  } catch (e) {
    return {'bruto': 0, 'liquido': 0, 'repasse_salao': 0};
  }
});
