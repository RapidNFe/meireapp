import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meire/core/ui/theme.dart';
import 'package:meire/core/services/pocketbase_service.dart';
import 'package:meire/features/dashboard/ui/widgets/vendas_chart_card.dart';
import 'package:meire/features/dashboard/ui/widgets/quick_launch_card.dart';
import 'package:meire/features/dashboard/ui/widgets/limite_mei_card.dart';
import 'package:meire/features/salao_parceiro/ui/widgets/resumo_quinzena_card.dart';
import 'package:meire/features/dashboard/ui/widgets/resumo_faturamento_card.dart';
import 'package:meire/features/dashboard/provider/vendas_ui_provider.dart';
import 'package:meire/features/dashboard/provider/performance_provider.dart';
import 'package:meire/features/profile/provider/settings_provider.dart';
import 'package:meire/services/faturamento_service.dart';
import 'package:flutter/services.dart';

/// Home Page em Bento Grid.
/// A nova área de 'Vendas' do profissional de beleza: 
/// Organização, Fluidez e Rapidez em uma única tela.
class BentoHomePage extends ConsumerWidget {
  const BentoHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ui = ref.watch(vendasUiProvider);
    
    // 🏛️ BentoHomePage como widget integrado (sem Scaffold próprio)
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildHeader(ref, ui.tituloAba),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          _buildBentoGrid(context, ref),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }

  Widget _buildHeader(WidgetRef ref, String tituloAba) {
    final userRecord = ref.watch(userProvider);
    var fullName = userRecord?.getStringValue('name') ?? '';
    if (fullName.isEmpty) fullName = userRecord?.getStringValue('nome_fantasia') ?? '';
    if (fullName.isEmpty) fullName = userRecord?.getStringValue('razao_social') ?? '';

    final userName = fullName.isNotEmpty ? fullName.split(' ').first : 'Comandante';
        
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Opacity(
                  opacity: 0.5,
                  child: Text(
                    tituloAba.toUpperCase(),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  userName.toUpperCase(),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: MeireTheme.primaryColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: MeireTheme.accentColor.withValues(alpha: 0.2)),
              ),
              child: const Icon(Icons.person_outline, color: MeireTheme.accentColor, size: 24),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBentoGrid(BuildContext context, WidgetRef ref) {
    final bool isDesktop = MediaQuery.of(context).size.width > 900;
    final settingsAsync = ref.watch(settingsProvider);
    final String salaoIdPadrao = settingsAsync.when(
      data: (s) => s['salaoId'] ?? '',
      loading: () => '',
      error: (_, __) => '',
    );
    
    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isDesktop ? 2 : 1, // 2 colunas no desk, 1 no mobile
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: isDesktop ? 1.6 : 1.3,
      ),
      delegate: SliverChildListDelegate([
        // 1. Card Vendas (O Grande Hero)
        const VendasChartCard(),
        
        // 2. Card de Lançamento Rápido (Ação imediata)
        const QuickLaunchCard(),

        // 3. Card de Limite MEI (Prevenção)
        const LimiteMeiCard(),

        // 4. 🏛️ CARD DE FECHAMENTO SOBERANO (Resumo Bento)
        _buildSoberaniaCard(ref),

        // 5. Card de Pendências de Fechamento (A grana na mesa)
        if (ref.watch(userProvider)?.getBoolValue('modulo_salao_ativo') ?? false)
          ResumoQuinzenaCard(salaoId: salaoIdPadrao),
      ]),
    );
  }

  Widget _buildSoberaniaCard(WidgetRef ref) {
    final perfAsync = ref.watch(performanceVendasProvider);
    final isSalao = ref.watch(userProvider)?.getBoolValue('modulo_salao_ativo') ?? false;

    return perfAsync.when(
      data: (stats) {
        if (stats['pendente']! <= 0) {
          return const SizedBox.shrink();
        }
        
        final ids = (stats['registros'] as List).map((e) => e.id.toString()).toList();

        return ResumoFaturamentoCard(
          valorBruto: stats['bruto'],
          cotaParte: stats['cota_parte'],
          suaParte: stats['liquido'],
          isSalaoParceiro: isSalao,
          onProcessarNfe: () async {
            HapticFeedback.mediumImpact();
            await ref.read(faturamentoServiceProvider).consolidarEFaturar(ids);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: MeireTheme.accentColor)),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
