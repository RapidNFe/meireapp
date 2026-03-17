import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/ui/theme.dart';
import '../provider/copiloto_provider.dart';

class DasnCopilotoPage extends ConsumerStatefulWidget {
  const DasnCopilotoPage({super.key});

  @override
  ConsumerState<DasnCopilotoPage> createState() => _DasnCopilotoPageState();
}

class _DasnCopilotoPageState extends ConsumerState<DasnCopilotoPage> {
  final int _selectedYear = DateTime.now().year - 1;

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(dasnCopilotoProvider(_selectedYear));

    return Scaffold(
      backgroundColor: MeiriTheme.backgroundColor,
      appBar: AppBar(
        title: const Text("Declaração Anual (DASN)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "RESUMO PARA DECLARAÇÃO",
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: MeiriTheme.accentColor,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            _buildMetricSummaryWidget(statsAsync),
            const SizedBox(height: 32),
            const Text(
              "DADOS PARA TRANSMISSÃO",
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Colors.grey,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            _buildMissionTarget(
              title: "Transmitir DASN-SIMEI",
              desc: "Acesse o portal oficial para declarar",
              url: "https://www8.receita.fazenda.gov.br/SimplesNacional/Aplicacoes/ATSPO/dasnsimei.app/Identificacao",
              icon: Icons.rocket_launch,
              color: MeiriTheme.primaryColor,
            ),
            const SizedBox(height: 48),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lock_outline, size: 20, color: Colors.blue),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "O Meiri gera o resumo com base nas notas emitidas pelo App. Confira se houve algum faturamento externo antes de declarar.",
                      style: TextStyle(fontSize: 12, color: Colors.blue, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricSummaryWidget(AsyncValue<DasnStats> statsAsync) {
    return statsAsync.when(
      data: (stats) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: MeiriTheme.iceGray),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Vendas de Mercadoria", style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                const Text(r"R$ 0,00", style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Prestação de Serviços", style: TextStyle(color: MeiriTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 14)),
                Text(NumberFormat.currency(locale: 'pt_BR', symbol: r"R$").format(stats.servicos), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              ],
            ),
            const Divider(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("RECEITA BRUTA TOTAL", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text(NumberFormat.currency(locale: 'pt_BR', symbol: r"R$").format(stats.total), style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w900, fontSize: 18)),
              ],
            ),
          ],
        ),
      ),
      loading: () => const LinearProgressIndicator(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildMissionTarget({required String title, required String desc, required String url, required IconData icon, required Color color}) {
    return InkWell(
      onTap: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(desc, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
          ],
        ),
      ),
    );
  }
}
