import 'package:flutter/material.dart';
import 'package:meire/core/ui/theme.dart';

/// Card de Limite MEI.
/// Ajuda o profissional a não perder o enquadramento fiscal (81k/ano).
class LimiteMeiCard extends StatelessWidget {
  const LimiteMeiCard({super.key});

  @override
  Widget build(BuildContext context) {
    const double totalFaturado = 42000.00; // Simulação
    const double limiteAnual = 81000.00;
    const double percentual = (totalFaturado / limiteAnual) * 100;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: MeireTheme.primaryColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.shield_outlined, color: Color(0xFF50C878), size: 16),
              SizedBox(width: 8),
              Text(
                "LIMITE MEI (ANUAL)",
                style: TextStyle(
                    color: Colors.white38,
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
              const Text("Utilizado", style: TextStyle(color: Colors.white54, fontSize: 11)),
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
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              FractionallySizedBox(
                widthFactor: percentual / 100,
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
          const Text("Ainda restam", style: TextStyle(color: Colors.white38, fontSize: 10)),
          const Text(
            "R\$ 39.000,00",
            style: TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: -0.5),
          ),
        ],
      ),
    );
  }
}
