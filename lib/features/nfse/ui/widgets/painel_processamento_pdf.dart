import 'dart:async';
import 'package:flutter/material.dart';
import 'package:meire/core/ui/theme.dart';

class PainelProcessamentoPDF extends StatefulWidget {
  final String chaveAcesso;
  final VoidCallback onFinalizado;

  const PainelProcessamentoPDF({
    super.key, 
    required this.chaveAcesso, 
    required this.onFinalizado
  });

  @override
  _PainelProcessamentoPDFState createState() => _PainelProcessamentoPDFState();
}

class _PainelProcessamentoPDFState extends State<PainelProcessamentoPDF> {
  double progresso = 0.0;
  int segundosRestantes = 60;
  Timer? _timer;
  bool pronto = false;

  @override
  void initState() {
    super.initState();
    iniciarContagem();
  }

  void iniciarContagem() {
    const umSegundo = Duration(seconds: 1);
    _timer = Timer.periodic(umSegundo, (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (segundosRestantes > 0) {
          segundosRestantes--;
          // Calcula a porcentagem para a barra (de 0.0 a 1.0)
          progresso = (60 - segundosRestantes) / 60;
        } else {
          pronto = true;
          _timer?.cancel();
          widget.onFinalizado(); // Avisa a tela pai que pode liberar o botão
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: MeireTheme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: MeireTheme.primaryColor.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          if (!pronto) ...[
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: MeireTheme.primaryColor),
                ),
                SizedBox(width: 12),
                Text(
                  "Sincronizando com o Governo...",
                  style: TextStyle(color: MeireTheme.primaryColor, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 15),
            LinearProgressIndicator(
              value: progresso,
              backgroundColor: MeireTheme.iceGray,
              color: Colors.green, 
              minHeight: 8,
            ),
            const SizedBox(height: 10),
            Text(
              "O PDF oficial estará pronto em $segundosRestantes segundos",
              style: TextStyle(color: Colors.black54, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ] else ...[
            const Icon(Icons.check_circle, color: Colors.green, size: 40),
            const SizedBox(height: 10),
            const Text(
              "PDF Oficial Liberado!",
              style: TextStyle(color: MeireTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ],
      ),
    );
  }
}
