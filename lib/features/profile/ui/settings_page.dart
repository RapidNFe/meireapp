import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meire/core/ui/theme.dart';
import 'package:meire/core/services/pocketbase_service.dart';
import 'package:meire/features/profile/provider/settings_provider.dart';

/// Tela de Configurações do Meiri.
/// Permite definir a comissão padrão e o salão parceiro fixo para
/// lançamentos em 2 segundos.
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  double _currentComissao = 0.60;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Inicia com o valor do provider (se já carregado)
    Future.microtask(() {
      final settings = ref.read(settingsProvider).asData?.value;
      if (settings != null) {
        setState(() => _currentComissao = settings['comissao'] ?? 0.60);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MeireTheme.primaryColor,
      appBar: AppBar(
        title: const Text(
          "Configurações Meiri",
          style: TextStyle(color: MeireTheme.accentColor, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Opacity(
              opacity: 0.6,
              child: Text(
                "DEFINA SUA REGRA DE NEGÓCIO",
                style: TextStyle(
                    color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2.5),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "Qual é a sua comissão padrão com o salão parceiro?",
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),

            const SizedBox(height: 32),

            // Slider Premium de Comissão
            Container(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Column(
                children: [
                  Text(
                    "${(_currentComissao * 100).toInt()}%",
                    style: const TextStyle(
                        color: MeireTheme.accentColor,
                        fontSize: 64,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -2),
                  ),
                  const Text("COMISSÃO (%)",
                      style: TextStyle(color: Colors.white24, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 32),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      thumbColor: MeireTheme.accentColor,
                      activeTrackColor: const Color(0xFF50C878),
                      inactiveTrackColor: Colors.white10,
                      trackHeight: 6,
                    ),
                    child: Slider(
                      value: _currentComissao,
                      min: 0.1,
                      max: 0.9,
                      onChanged: (v) => setState(() => _currentComissao = v),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 48),

            // Botão de Salvar Soberano
            SizedBox(
              width: double.infinity,
              height: 64,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF50C878),
                  foregroundColor: MeireTheme.primaryColor,
                  elevation: 10,
                  shadowColor: const Color(0xFF50C878).withValues(alpha: 0.3),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _isSaving ? null : _saveSettings,
                child: _isSaving
                    ? const CircularProgressIndicator(color: MeireTheme.primaryColor)
                    : const Text(
                        "SALVAR CONFIGURAÇÕES",
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                      ),
              ),
            ),

            const SizedBox(height: 24),
            const Center(
              child: Text(
                "Essa configuração será aplicada automaticamente em todos os novos serviços que você lançar no seu Meiri.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    
    try {
      final pb = ref.read(pbProvider);
      
      await pb.collection('users').update(pb.authStore.record!.id, body: {
        'comissao_padrao': _currentComissao,
      });

      // Invalida o provider para refletir no app inteiro
      ref.invalidate(settingsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Configurações salvas com sucesso!"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Erro ao salvar: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
