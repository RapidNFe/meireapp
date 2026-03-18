import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meire/core/ui/theme.dart';
import 'package:meire/core/services/pocketbase_service.dart';
import 'package:meire/features/salao_parceiro/provider/salao_parceiro_provider.dart';
import 'package:meire/features/salao_parceiro/services/extrato_generator.dart';

// Este provider fictício cuidará da lógica de soma dos valores pendentes
final resumoQuinzenaProvider = FutureProvider.family<Map<String, double>, String>((ref, salaoId) async {
  // Simulação de cálculo de soma. 
  // No mundo real, aqui você usaria o PocketBase para somar 'valor_servico' 
  // de todos onde status == 'pendente' && salão == salaoId
  await Future.delayed(const Duration(milliseconds: 800)); // Simula rede
  return {
    'total_servicos': 1200.00, // Bruto
    'valor_da_nota': 600.00,   // Cota-parte (50%)
  };
});

/// Widget Premium de Resumo de Quinzena.
/// Exibe para o profissional quanto ele tem 'pendente' para o salão parceiro.
class ResumoQuinzenaCard extends ConsumerWidget {
  final String salaoId;
  const ResumoQuinzenaCard({super.key, required this.salaoId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resumoAsync = ref.watch(resumoQuinzenaProvider(salaoId));

    return resumoAsync.when(
      data: (dados) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          image: const DecorationImage(
            image: AssetImage('assets/images/dashboard_noise.png'), // Se houver
            opacity: 0.1,
            fit: BoxFit.cover,
          ),
          gradient: const LinearGradient(
            colors: [Color(0xFF1A5A38), Color(0xFF01291B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 15,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: Column(
          children: [
            const Opacity(
              opacity: 0.6,
              child: Text(
                "VALOR PENDENTE (SUA PARTE)",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2.0,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "R\$ ${dados['valor_da_nota']?.toStringAsFixed(2)}",
              style: const TextStyle(
                color: MeireTheme.accentColor, // Ouro Meiri
                fontSize: 36,
                fontWeight: FontWeight.w900,
                letterSpacing: -1,
              ),
            ),
            const Divider(color: Colors.white10, height: 40, thickness: 1),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStat("Serviços Totais", "R\$ ${dados['total_servicos']?.toStringAsFixed(2)}"),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Botão Extrato
                    OutlinedButton.icon(
                      onPressed: () => _gerarExtrato(context, ref),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: const BorderSide(color: Colors.white24),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.picture_as_pdf, size: 16),
                      label: const Text("EXTRATO", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 8),
                    // Botão Emitir
                    ElevatedButton(
                      onPressed: () => _confirmarEmissao(context, ref, dados['valor_da_nota']!),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: MeireTheme.accentColor,
                        foregroundColor: Colors.white,
                        elevation: 10,
                        shadowColor: MeireTheme.accentColor.withValues(alpha: 0.3),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text(
                        "EMITIR NOTA",
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(color: MeireTheme.accentColor),
        ),
      ),
      error: (e, _) => Center(
        child: Text("Erro ao calcular resumo: $e", style: const TextStyle(color: Colors.red)),
      ),
    );
  }

  Future<void> _confirmarEmissao(BuildContext context, WidgetRef ref, double valor) async {
    // 🚀 INÍCIO DA COREOGRAFIA DA NOTA
    
    // 1. Mostra o Diálogo de Carregamento Ultra-Leve
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: MeireTheme.primaryColor,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: MeireTheme.accentColor),
                SizedBox(height: 24),
                Text(
                  "Finalizando acerto com o salão...",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      // 2. Dispara a lógica de emissão e baixa em massa
      await ref.read(salaoParceiroControllerProvider.notifier).emitirFechamento(
        salaoId: salaoId,
        salaoNome: "SALÃO PARCEIRO EXEMPLO", // No Real, viria da seleção do usuário
        salaoCnpj: "00.000.000/0001-91",     // No Real, viria do Tomador record
        valorNota: valor,
      );

      // 3. Fecha o diálogo e avisa o usuário (Sucesso!)
      if (context.mounted) {
        Navigator.pop(context); // Fecha loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Nota emitida e quinzena fechada com sucesso!"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Fecha loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ Falha no fechamento: $e"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _gerarExtrato(BuildContext context, WidgetRef ref) async {
    try {
      final pb = ref.read(pbProvider);
      final pendentes = await pb.collection('lancamentos_servicos').getFullList(
            filter: 'salao = "$salaoId" && status = "pendente"',
            sort: '-data_servico',
          );

      if (pendentes.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Nenhum serviço pendente para gerar extrato.")),
          );
        }
        return;
      }

      final userData = pb.authStore.record?.toJson() ?? {};
      final nomeProfissional = userData['nome'] ?? userData['username'] ?? "Profissional Meiri";

      // 🦅 DISPARO DO PDF SOBERANO
      await ExtratoGenerator.gerarEFalhar(
        pendentes.map((e) => e.toJson()).toList(),
        nomeProfissional,
        "SALÃO PARCEIRO", // Aqui você pode injetar o nome real do tomador
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao gerar PDF: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
