import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meire/core/services/pocketbase_service.dart';

/// 🦎 PROVIDER DE INTERFACE CAMALEÃO
/// Adapta a UI (cores, textos, botões) baseado no perfil do MEI.
final vendasUiProvider = Provider<VendasUiColors>((ref) {
  final user = ref.watch(userProvider);
  final isSalaoParceiro = user?.getBoolValue('modulo_salao_ativo') ?? false;

  return VendasUiColors(
    isSalaoParceiro: isSalaoParceiro,
  );
});

class VendasUiColors {
  final bool isSalaoParceiro;

  VendasUiColors({required this.isSalaoParceiro});

  // 🎨 Cores SOBERANAS
  Color get corPrincipal => isSalaoParceiro 
      ? const Color(0xFFCC8B00) // Ouro (Salão)
      : const Color(0xFF1A5A38); // Verde Floresta (Direto)

  Color get corFundoInput => isSalaoParceiro 
      ? const Color(0xFFCC8B00).withValues(alpha: 0.1)
      : const Color(0xFF1A5A38).withValues(alpha: 0.1);

  // 📝 Micro-copy Adaptativo
  String get labelValorPrincipal => isSalaoParceiro ? "Minha Parte" : "Faturamento Integral";
  String get labelBotaoLaunch => isSalaoParceiro ? "Lançar Comissão 💎" : "Registrar Venda 💰";
  String get labelRetencao => isSalaoParceiro ? "Cota-Parte Salão" : "Descontos/Taxas";
  String get subLabelFechamento => isSalaoParceiro 
      ? "Gerar Extrato para o Salão" 
      : "Confirmar Faturamento Direto";
  
  // 🦅 Título da Aba
  String get tituloAba => isSalaoParceiro ? "VENDAS (PARCERIA)" : "FATURAMENTO DIRETO";
}
