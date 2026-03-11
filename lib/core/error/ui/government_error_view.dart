import 'package:flutter/material.dart';
import 'package:meire/core/ui/theme.dart';

class GovernmentErrorView extends StatelessWidget {
  final VoidCallback onRetry;

  const GovernmentErrorView({
    super.key,
    required this.onRetry,
  });

  void _scheduleNotification(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
                child: Text(
                    "Tudo certo! A Meire vai te avisar quando o sistema voltar.")),
          ],
        ),
        backgroundColor: Color(0xFF388E3C), // Colors.green.shade700
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(10))),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MeireTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Ops, sistema instável'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Placeholder for an illustration (could be an SVG or Lottie)
              Container(
                width: 160,
                height: 160,
                decoration: const BoxDecoration(
                  color: MeireTheme.iceGray,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.cloud_off_rounded,
                  size: 80,
                  color: MeireTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                "Sistemas do Governo Indisponíveis",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: MeireTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Nesse momento o site da Prefeitura / Receita Federal está passando por instabilidades. Não se preocupe, seus dados estão salvos no aplicativo.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: MeireTheme.textBodyColor,
                ),
              ),
              const SizedBox(height: 48),
              ElevatedButton.icon(
                onPressed: () => _scheduleNotification(context),
                icon: const Icon(Icons.notifications_active_outlined),
                label: const Text("Me avise quando voltar"),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 54),
                  backgroundColor: MeireTheme.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, color: MeireTheme.primaryColor),
                label: const Text("Tentar novamente agora"),
                style: TextButton.styleFrom(
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: MeireTheme.primaryColor),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
