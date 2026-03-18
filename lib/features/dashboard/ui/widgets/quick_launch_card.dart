import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meire/core/ui/theme.dart';

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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: MeireTheme.primaryColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Row(
            children: [
              Icon(Icons.bolt, color: MeireTheme.accentColor, size: 16),
              SizedBox(width: 8),
              Text(
                "LANÇAMENTO RÁPIDO",
                style: TextStyle(
                    color: Colors.white38,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.0),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(
                color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1),
            decoration: InputDecoration(
              prefixText: "R\$ ",
              prefixStyle: const TextStyle(color: MeireTheme.accentColor, fontSize: 20),
              hintText: "0,00",
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.1)),
              border: InputBorder.none,
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submitLancamento,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF50C878), // Esmeralda Sucesso
                foregroundColor: MeireTheme.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: MeireTheme.primaryColor))
                  : const Text("SALVAR SERVIÇO",
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitLancamento() async {
    if (_controller.text.isEmpty) return;

    setState(() => _isLoading = true);
    HapticFeedback.lightImpact(); // Feedback físico Quiet Luxury

    try {
      // Simulação de salvamento dinâmico usando as preferências do perfil
      await Future.delayed(const Duration(milliseconds: 800));
      
      if (mounted) {
        _controller.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Serviço lançado com sua comissão padrão!"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
