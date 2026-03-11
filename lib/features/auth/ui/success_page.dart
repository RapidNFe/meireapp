import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meire/core/ui/theme.dart';
import 'package:meire/core/provider/app_provider.dart';
import 'package:meire/features/auth/provider/auth_provider.dart';

class SuccessPage extends ConsumerWidget {
  const SuccessPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle_outline,
                size: 100,
                color: MeireTheme.accentColor,
              ),
              const SizedBox(height: 24),
              const Text(
                'Conta MEI Criada!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: MeireTheme.primaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Suas informações foram validadas com sucesso.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Integração UX Bridge: Marca como autenticado e fiscalmente ativo
                    final userName = ref.read(registrationProvider).fullName;
                    ref.read(appProvider.notifier).setAuthenticated(
                          name: userName.isNotEmpty ? userName : 'Usuário',
                          fiscallyActive: true,
                        );
                    Navigator.pushReplacementNamed(context, '/hub');
                  },
                  child: const Text('Ir para o Business Hub'),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
