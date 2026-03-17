import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class VortexSuccessCheck extends StatefulWidget {
  const VortexSuccessCheck({super.key});

  @override
  State<VortexSuccessCheck> createState() => _VortexSuccessCheckState();
}

class _VortexSuccessCheckState extends State<VortexSuccessCheck> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // Duração controlada nativamente; o controller dita o ritmo da GPU
    _controller = AnimationController(
      vsync: this, 
      duration: const Duration(milliseconds: 1200),
    )..forward();
  }

  @override
  void dispose() {
    // CRÍTICO: Prevenção de memory leaks ao fechar a tela de emissão
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Lottie.asset(
      'assets/animations/success.lottie', // Formato .lottie (zipado), menor I/O
      controller: _controller,
      width: 120,
      height: 120,
      fit: BoxFit.contain,
      // Fallback silencioso: se o arquivo corromper, exibe um ícone nativo sem quebrar a UI
      errorBuilder: (context, error, stackTrace) => const Icon(
        Icons.check_circle_outline, 
        color: Color(0xFFCC8B00), 
        size: 80,
      ),
      delegates: LottieDelegates(
        values: [
          // Injeção dinâmica da cor Ouro diretamente no pipeline de renderização
          ValueDelegate.color(
            const ['**'], // O curinga '**' aplica a cor a todos os nós de shape do arquivo
            value: const Color(0xFFCC8B00),
          ),
        ],
      ),
    );
  }
}
