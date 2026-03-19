import 'package:flutter/material.dart';
import 'package:meire/core/ui/theme.dart';

/// 🏛️ RESUMO FATURAMENTO CARD (Bento Style)
/// Visualização SOBERANA do fechamento de período (Quinzena ou Vendas Diretas).
class ResumoFaturamentoCard extends StatelessWidget {
  final double valorBruto;
  final double cotaParte;
  final double suaParte;
  final bool isSalaoParceiro;
  final VoidCallback? onProcessarNfe;
  final bool isLoading;

  const ResumoFaturamentoCard({
    super.key,
    required this.valorBruto,
    required this.cotaParte,
    required this.suaParte,
    this.isSalaoParceiro = true,
    this.onProcessarNfe,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF161616), // Fundo Grafite Profundo
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 30,
            offset: const Offset(0, 15),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildBentoGrid(),
          const SizedBox(height: 24),
          _buildValorFinalSoberano(),
          if (onProcessarNfe != null) ...[
            const SizedBox(height: 24),
            _buildAcaoBotao(),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "DEMONSTRATIVO",
              style: TextStyle(
                color: Colors.white38,
                letterSpacing: 1.5,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 4),
            Text(
              "Fechamento de Ciclo",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Icon(Icons.verified_user_outlined, color: MeireTheme.accentColor, size: 20),
      ],
    );
  }

  Widget _buildBentoGrid() {
    return Row(
      children: [
        // Card Bruto
        Expanded(
          child: _bentoItem(
            label: "Total Bruto",
            valor: valorBruto,
            color: Colors.white,
            subtitle: "Total recebido",
          ),
        ),
        const SizedBox(width: 12),
        // Card Cota-Parte (Só aparece se for Salão)
        if (isSalaoParceiro)
          Expanded(
            child: _bentoItem(
              label: "Cota-Parte",
              valor: -cotaParte,
              color: const Color(0xFFE57373), // Vermelho Suave
              subtitle: "Repasse Salão",
            ),
          ),
      ],
    );
  }

  Widget _bentoItem({required String label, required double valor, required Color color, required String subtitle}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.02)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: const TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            "R\$ ${valor.abs().toStringAsFixed(2)}",
            style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: -0.5),
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: Colors.white24, fontSize: 9)),
        ],
      ),
    );
  }

  Widget _buildValorFinalSoberano() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            MeireTheme.accentColor.withValues(alpha: 0.15),
            MeireTheme.accentColor.withValues(alpha: 0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: MeireTheme.accentColor.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Column(
        children: [
          const Text(
            "SUA PARTE SOBERANA", 
            style: TextStyle(
              color: MeireTheme.accentColor, 
              fontSize: 12, 
              fontWeight: FontWeight.w900,
              letterSpacing: 2.0,
            )
          ),
          const SizedBox(height: 12),
          Text(
            "R\$ ${suaParte.toStringAsFixed(2)}",
            style: const TextStyle(
              color: Colors.white, 
              fontSize: 36, 
              fontWeight: FontWeight.w900, 
              letterSpacing: -1.5,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Base para emissão da NFS-e", 
            style: TextStyle(color: Colors.white30, fontSize: 10, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildAcaoBotao() {
    return SizedBox(
      width: double.infinity,
      height: 64,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1A5A38), // Verde Floresta Elite
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          elevation: 10,
          shadowColor: const Color(0xFF1A5A38).withValues(alpha: 0.3),
        ),
        onPressed: isLoading ? null : onProcessarNfe,
        child: isLoading 
          ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
          : const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("GERAR NOTA FISCAL 🚀", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                SizedBox(width: 8),
                Icon(Icons.bolt, size: 18),
              ],
            ),
      ),
    );
  }
}
