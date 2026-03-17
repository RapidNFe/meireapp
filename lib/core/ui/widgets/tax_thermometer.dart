import 'package:flutter/material.dart';

class TaxThermometer extends StatefulWidget {
  final double fillPercentage; // de 0.0 a 1.0

  const TaxThermometer({super.key, required this.fillPercentage});

  @override
  State<TaxThermometer> createState() => _TaxThermometerState();
}

class _TaxThermometerState extends State<TaxThermometer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this, 
      duration: const Duration(milliseconds: 1800),
    );
    
    // Curva "Decelerate" para passar a sensação de preenchimento pesado e luxuoso
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOutQuart);
    
    // Inicia a animação de preenchimento ao abrir
    _controller.forward();
  }

  @override
  void didUpdateWidget(TaxThermometer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fillPercentage != widget.fillPercentage) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 12, // Altura elegante e discreta
      child: RepaintBoundary(
        child: CustomPaint(
          // Passamos a animação DIRETAMENTE para o repaint do CustomPainter.
          // Isso evita que o widget inteiro sofra 'build' a cada frame.
          painter: _ThermometerPainter(
            animation: _animation,
            targetPercentage: widget.fillPercentage,
          ),
        ),
      ),
    );
  }
}

class _ThermometerPainter extends CustomPainter {
  final Animation<double> animation;
  final double targetPercentage;

  // Brand colors from the new palette
  static const Color forestGreen = Color(0xFF1A4D35);
  static const Color gold = Color(0xFFFFB700);


  _ThermometerPainter({required this.animation, required this.targetPercentage}) 
      : super(repaint: animation); // Aciona o paint() a cada tick da animação automaticamente

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Background (Trilha vazia)
    final bgPaint = Paint()
      ..color = forestGreen.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;
    
    final bgRRect = RRect.fromRectAndRadius(
      Offset.zero & size, 
      const Radius.circular(6), // Cantos arredondados
    );
    canvas.drawRRect(bgRRect, bgPaint);

    // 2. Foreground (Progresso animado com Gradiente Forest -> Gold)
    final currentWidth = size.width * (targetPercentage * animation.value);
    
    // Prevenção matemática: não desenhar se a largura for nula
    if (currentWidth <= 0) return;

    final progressRect = Rect.fromLTWH(0, 0, currentWidth, size.height);
    
    final fillPaint = Paint()
      ..shader = const LinearGradient(
        colors: [forestGreen, gold],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(progressRect) // O shader acompanha perfeitamente o crescimento da barra
      ..style = PaintingStyle.fill;

    final progressRRect = RRect.fromRectAndRadius(
      progressRect,
      const Radius.circular(6),
    );
    
    canvas.drawRRect(progressRRect, fillPaint);
  }

  @override
  bool shouldRepaint(covariant _ThermometerPainter oldDelegate) {
    return oldDelegate.targetPercentage != targetPercentage;
  }
}
