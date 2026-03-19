import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meire/core/ui/theme.dart';
import 'package:meire/features/dashboard/provider/performance_provider.dart';

class PendenteNfeCard extends ConsumerWidget {
  const PendenteNfeCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perfAsync = ref.watch(performanceVendasProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return perfAsync.when(
      data: (stats) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: MeireTheme.accentColor.withValues(alpha: 0.1),
          ),
          boxShadow: isDark ? [] : [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                const Icon(Icons.receipt_long_outlined, color: MeireTheme.accentColor, size: 16),
                const SizedBox(width: 8),
                Text(
                  "PENDENTE DE NOTA",
                  style: TextStyle(
                    color: isDark ? Colors.white38 : Colors.black38,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              "R\$ ${stats['pendente']?.toStringAsFixed(2)}",
              style: const TextStyle(
                color: MeireTheme.accentColor,
                fontSize: 32,
                fontWeight: FontWeight.w900,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "VALOR ACUMULADO PARA EMISSAO",
              style: TextStyle(
                color: isDark ? Colors.white24 : Colors.black26,
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Text("Erro ao carregar saldo"),
    );
  }
}
