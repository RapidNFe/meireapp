import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meire/core/ui/theme.dart';
import 'package:meire/features/dashboard/provider/performance_provider.dart';

/// Card de Performance 'Soberania Financeira'.
class SoberaniaChartCard extends ConsumerWidget {
  const SoberaniaChartCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dadosAsync = ref.watch(performanceSoberaniaProvider);

    return dadosAsync.when(
      data: (dados) {
        final faturamentoBruto = dados['bruto'] ?? 0;
        final faturamentoLiquido = dados['liquido'] ?? 0;
        final percentualRetencao = faturamentoBruto > 0 
            ? (faturamentoLiquido / faturamentoBruto) * 100 
            : 0;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF01291B),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "SOBERANIA FINANCEIRA",
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                    ),
                  ),
                  Icon(Icons.auto_graph, color: MeireTheme.accentColor, size: 16),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMetric("Bruto Total", faturamentoBruto, Colors.white70),
                  _buildMetric("Sua Cota-Parte", faturamentoLiquido, MeireTheme.accentColor),
                ],
              ),
              const SizedBox(height: 24),
              
              // Barra de Progresso Comparativa
              Stack(
                children: [
                  Container(
                    height: 8,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: (percentualRetencao / 100).clamp(0.0, 1.0),
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF50C878), MeireTheme.accentColor],
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  "Você fica com ${percentualRetencao.toInt()}% de tudo que gera no salão.",
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(color: MeireTheme.accentColor),
        ),
      ),
      error: (e, _) => const SizedBox(),
    );
  }

  Widget _buildMetric(String label, double valor, Color color) {
    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          "R\$ ${valor.toStringAsFixed(2)}",
          style: TextStyle(
            color: color,
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}
