import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meire/core/ui/theme.dart';
import 'package:meire/core/services/pocketbase_service.dart';
import 'package:meire/features/dashboard/ui/widgets/soberania_chart_card.dart';
import 'package:meire/features/dashboard/ui/widgets/quick_launch_card.dart';
import 'package:meire/features/dashboard/ui/widgets/limite_mei_card.dart';
import 'package:meire/features/salao_parceiro/ui/widgets/resumo_quinzena_card.dart';

/// Home Page em Bento Grid.
/// A nova 'Soberania' do profissional de beleza: 
/// Organização, Fluidez e Rapidez em uma única tela.
class BentoHomePage extends ConsumerWidget {
  const BentoHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFF001F15),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(), // Scroll premium
            slivers: [
              _buildHeader(ref),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
              _buildBentoGrid(context, ref),
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(WidgetRef ref) {
    final username =
        ref.read(pbProvider).authStore.record?.getStringValue('username') ?? "Comandante";
        
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Opacity(
                  opacity: 0.5,
                  child: Text(
                    "BOM DIA, ",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  username.toUpperCase(),
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
    
    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isDesktop ? 2 : 1, // 2 colunas no desk, 1 no mobile
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: isDesktop ? 1.6 : 1.3,
      ),
      delegate: SliverChildListDelegate([
        // 1. Card Soberania (O Grande Hero)
        const SoberaniaChartCard(),
        
        // 2. Card de Lançamento Rápido (Ação imediata)
        const QuickLaunchCard(),

        // 3. Card de Limite MEI (Prevenção)
        const LimiteMeiCard(),

        // 4. Card de Pendências de Fechamento (A grana na mesa)
        const ResumoQuinzenaCard(salaoId: 'default'),
      ]),
    );
  }
}
