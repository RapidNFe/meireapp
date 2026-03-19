import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meire/core/services/pocketbase_service.dart';

/// Provider que controla o período de visualização do faturamento.
/// Padrão: Últimos 15 dias (Quinzena).
final periodoFiltroProvider = StateProvider<DateTimeRange>((ref) {
  final agora = DateTime.now();
  return DateTimeRange(
    start: agora.subtract(const Duration(days: 15)),
    end: agora.add(const Duration(days: 1)), // Inclui o dia de hoje
  );
});

/// Provider que consolida os dados de performance financeira baseados no filtro.
/// Separa o que é faturamento Bruto do que é a Cota-Parte (Líquido) do profissional.
final performanceVendasProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final pb = ref.read(pbProvider);
  final userId = pb.authStore.record?.id;
  final periodo = ref.watch(periodoFiltroProvider);

  if (userId == null) {
    return {
      'bruto': 0.0,
      'liquido': 0.0,
      'pendente': 0.0,
      'registros': [],
    };
  }

  final inicio = periodo.start.toIso8601String().split('T')[0];
  final fim = "${periodo.end.toIso8601String().split('T')[0]}T23:59:59";

  try {
    // 2. Busca lançamentos no período para o usuário logado
    final registros = await pb.collection('servicos').getFullList(
          filter: 'user_id = "$userId" && data_servico >= "$inicio" && data_servico <= "$fim"',
          sort: '-data_servico',
        );

    double faturamentoBruto = 0; // Total pago pelos clientes
    double minhaParteReal = 0;   // O que o profissional de fato ganhou (cota-parte)
    double pendenteNfe = 0;      // O que está 'aberto' mas não faturado ainda

    for (var reg in registros) {
      final status = reg.getStringValue('status_faturamento');
      final valBruto = (reg.data['valor_bruto'] ?? 0.0).toDouble();
      final valLiquido = (reg.data['valor_liquido'] ?? 0.0).toDouble();

      faturamentoBruto += valBruto;
      minhaParteReal += valLiquido;

      // 🦅 Lógica Soberana: Soma o que está 'aberto' para fechamento
      if (status == 'aberto') {
        pendenteNfe += valLiquido;
      }
    }

    return {
      'bruto': faturamentoBruto,
      'liquido': minhaParteReal,
      'pendente': pendenteNfe,
      'cota_parte': faturamentoBruto - minhaParteReal,
      'registros': registros,
    };
  } catch (e) {
    return {
      'bruto': 0.0,
      'liquido': 0.0,
      'pendente': 0.0,
      'registros': [],
    };
  }
});
