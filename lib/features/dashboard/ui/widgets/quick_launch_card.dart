import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meire/core/ui/theme.dart';
import 'package:meire/core/services/pocketbase_service.dart';
import 'package:meire/features/dashboard/provider/performance_provider.dart';
import 'package:meire/features/salao_parceiro/ui/widgets/resumo_quinzena_card.dart';
import 'package:meire/features/hub/provider/notas_fiscais_provider.dart';
import 'package:meire/features/dashboard/provider/vendas_ui_provider.dart';
import 'package:meire/features/profile/provider/settings_provider.dart';
import 'package:meire/features/clients/models/tomador_model.dart';
import 'package:meire/core/ui/widgets/tomador_selector_lux.dart';

/// Card de Lançamento Rápido de Serviços.
/// Focado em velocidade absoluta: valor -> enter -> salvo.
class QuickLaunchCard extends ConsumerStatefulWidget {
  const QuickLaunchCard({super.key});

  @override
  ConsumerState<QuickLaunchCard> createState() => _QuickLaunchCardState();
}

class _QuickLaunchCardState extends ConsumerState<QuickLaunchCard> {
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;
  bool _isSalao = true;
  TomadorModel? _tomadorSelecionado;

  @override
  Widget build(BuildContext  context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ui = ref.watch(vendasUiProvider);
    
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.bolt, color: MeireTheme.accentColor, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    "LANÇAMENTO RÁPIDO",
                    style: TextStyle(
                        color: isDark ? Colors.white38 : Colors.black38,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0),
                  ),
                ],
              ),
              // 🎫 TOGGLE DE VIA (ELITE Logic)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    _buildNicheButton("SALÃO", _isSalao, isDark, () => setState(() => _isSalao = true)),
                    _buildNicheButton("DIRETO", !_isSalao, isDark, () => setState(() => _isSalao = false)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(
                color: isDark ? Colors.white : MeireTheme.primaryColor, 
                fontSize: 32, 
                fontWeight: FontWeight.w900, 
                letterSpacing: -1),
            decoration: InputDecoration(
              filled: false, // Remove fundo interno para usar o do card
              prefixText: "R\$ ",
              prefixStyle: const TextStyle(color: MeireTheme.accentColor, fontSize: 20, fontWeight: FontWeight.bold),
              hintText: "0,00",
              hintStyle: TextStyle(
                color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1)
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => _submitLancamento(),
          ),
          const SizedBox(height: 16),
          // 🏛️ SELETOR DE TOMADOR (Connection)
          TomadorSelectorLux(
            onSelected: (tomador) {
              setState(() {
                _tomadorSelecionado = tomador;
                _isSalao = tomador.isSalaoParceiro; // Auto-ajuste de via
              });
            },
            onNovoCliente: () => Navigator.pushNamed(context, '/customer_form'),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submitLancamento,
              style: ElevatedButton.styleFrom(
                backgroundColor: ui.corPrincipal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(ui.labelBotaoLaunch,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitLancamento() async {
    if (_controller.text.isEmpty) return;

    final String valStr = _controller.text.replaceAll(',', '.');
    final double absoluteValue = double.tryParse(valStr) ?? 0.0;
    if (absoluteValue <= 0) return;

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact(); // Feedback físico Quiet Luxury

    try {
      final pb = ref.read(pbProvider);
      final userId = pb.authStore.record?.id;
      if (userId == null) throw Exception("Sessão expirada.");

      // 1. Busca configurações (Comissão e Salão Padrão)
      final settingsAsync = await ref.read(settingsProvider.future);
      
      // 💎 TROCA DE CHAVE: Se não for Salão, a comissão é 100%
      final double comissaoTotal = _isSalao ? (settingsAsync['comissao'] ?? 0.60) : 1.0;
      final String salaoId = _isSalao ? (settingsAsync['salaoId'] ?? '') : '';

      // 2. Calcula a Cota-Parte (O que de fato fica com o profissional)
      final double valorCotaParte = absoluteValue * comissaoTotal;
      final String mesAnoAgrupador = "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}";

      // 3. Salva no novo schema SOBERANO: collection 'servicos'
      await pb.collection('servicos').create(body: {
        'user_id': userId, 
        'modalidade_fluxo': _isSalao ? 'quinzena' : 'venda_direta',
        'status_faturamento': 'aberto',
        'comissao_aplicada': comissaoTotal * 100, 
        'valor_bruto': absoluteValue,
        'valor_liquido': valorCotaParte,
        'id_agrupador': _isSalao 
            ? "${_tomadorSelecionado?.id ?? salaoId}_$mesAnoAgrupador" 
            : "direto_$mesAnoAgrupador",
        'tomador_id': _tomadorSelecionado?.id,
        'tomador_nome': _tomadorSelecionado?.displayName ?? (_isSalao ? 'Salão Parceiro' : 'Cliente Avulso'),
        'data_servico': DateTime.now().toIso8601String(),
      });

      // 4. Invalida os providers para atualizar os cards instantaneamente em todo o app
      ref.invalidate(performanceVendasProvider);
      ref.invalidate(revenueStatsProvider);
      if (salaoId.isNotEmpty) {
        ref.invalidate(resumoQuinzenaProvider(salaoId));
      } else {
        ref.invalidate(resumoQuinzenaProvider('default'));
      }
      
      if (mounted) {
        _controller.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("✅ R\$ ${absoluteValue.toStringAsFixed(2)} lançado! Sua parte: R\$ ${valorCotaParte.toStringAsFixed(2)}"),
            backgroundColor: const Color(0xFF50C878),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ Erro ao salvar lançamento: $e"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildNicheButton(String label, bool isActive, bool isDark, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive 
              ? (isDark ? MeireTheme.accentColor : MeireTheme.primaryColor) 
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : (isDark ? Colors.white38 : Colors.black38),
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }
}
