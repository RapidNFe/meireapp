import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class VaultTunnelingLoading extends StatelessWidget {
  const VaultTunnelingLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      // CRÍTICO: Isola a animação. O Flutter cria uma textura separada (Display List)
      // para este widget. O loop não causará 'repaint' na tela de fundo.
      child: RepaintBoundary(
        child: Lottie.asset(
          'assets/animations/vault_scan.lottie',
          width: 80,
          height: 80,
          repeat: true, // Loop infinito
          // Mantém a animação suave e alinhada ao refresh rate nativo do device
          frameRate: FrameRate.max, 
          // Tratamento de falha silencioso (Fricção Zero)
          errorBuilder: (context, error, stackTrace) => const SizedBox(
            width: 80, 
            height: 80, 
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1A5A38)),
            ),
          ),
        ),
      ),
    );
  }
}
