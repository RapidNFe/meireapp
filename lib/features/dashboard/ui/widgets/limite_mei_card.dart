import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meire/core/ui/theme.dart';
import 'package:meire/features/hub/provider/notas_fiscais_provider.dart';
import 'package:intl/intl.dart';

/// Card de Limite MEI.
/// Ajuda o profissional a não perder o enquadramento fiscal (81k/ano).
class LimiteMeiCard extends ConsumerWidget {
  const LimiteMeiCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final revenueAsync = ref.watch(revenueStatsProvider);
    final currencyFormatter = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return revenueAsync.when(
      data: (stats) {
        final double percentual = stats.percentage * 100;

        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark 
                ? MeireTheme.primaryColor.withValues(alpha: 0.5)
                : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)
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
            children: [
              Row(
                children: [
                  const Icon(Icons.shield_outlined, color: Color(0xFF50C878), size: 16),
                  const SizedBox(width: 8),
                  Text(
                    "LIMITE MEI (ANUAL)",
                    style: TextStyle(
                        color: isDark ? Colors.white38 : Colors.black38,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Utilizado", 
                      style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 11)),
                  Text("${percentual.toInt()}%",
                      style: const TextStyle(
                          color: Color(0xFF50C878), fontSize: 13, fontWeight: FontWeight.w900)),
                ],
              ),
              const SizedBox(height: 12),
              
              // Barra de Progresso Segura
              Stack(
                children: [
                  Container(
                    height: 6,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: stats.percentage,
                    child: Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: const Color(0xFF50C878),
                        borderRadius: BorderRadius.circular(3),
                        boxShadow: [
                          BoxShadow(
                              color: const Color(0xFF50C878).withValues(alpha: 0.3),
                              blurRadius: 4)
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              
              const Spacer(),
              Text("Ainda restam", 
                  style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 10)),
              Text(
                currencyFormatter.format(stats.remaining),
                style: TextStyle(
                    color: isDark ? Colors.white : MeireTheme.primaryColor, 
                    fontSize: 18, 
                    fontWeight: FontWeight.bold, 
                    letterSpacing: -0.5),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: MeireTheme.accentColor)),
      error: (e, _) => const Center(child: Icon(Icons.error_outline, color: Colors.red)),
    );
  }
}
