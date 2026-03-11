import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meire/core/ui/theme.dart';
import 'package:meire/features/auth/services/auth_service.dart';
import 'package:meire/features/auth/ui/gov_integration_page.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authService = ref.watch(authServiceProvider);
    final user = authService.currentUser;

    if (user == null) {
      return const Center(child: Text('Nenhum dado do usuário encontrado.'));
    }

    final cpf = user.getStringValue('cpf');
    final name = user.getStringValue('name');
    final email = user.getStringValue('email');

    // Gov data status
    final statusRegistro = user.getStringValue('status_registro');

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 32),
              _buildCard(
                context: context,
                title: 'Informações Pessoais',
                icon: Icons.person_outline,
                children: [
                  _InfoRow(label: 'Nome Completo', value: name),
                  const Divider(height: 24),
                  _InfoRow(label: 'E-mail', value: email),
                  const Divider(height: 24),
                  _InfoRow(label: 'CPF', value: _formatDocument(cpf)),
                ],
              ),
              const SizedBox(height: 24),
              _buildCard(
                context: context,
                title: 'Integração Governamental',
                icon: Icons.account_balance,
                children: [
                  if (statusRegistro == 'conta_criada')
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Você ainda não conectou o Emissor Nacional. Delegue sua permissão assinando a e-Procuração para emitir suas notas expressas.',
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const GovIntegrationPage()));
                          },
                          icon: const Icon(Icons.add_moderator),
                          label: const Text('Conectar ao Governo'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: MeireTheme.accentColor,
                            side:
                                const BorderSide(color: MeireTheme.accentColor),
                          ),
                        ),
                      ],
                    )
                  else if (statusRegistro == 'aguardando_procuracao')
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.hourglass_top, color: Colors.orange, size: 20),
                            SizedBox(width: 8),
                            Text('Análise Ocorrendo', style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text('Sua e-Procuração está sendo habilitada pelos nossos contadores. Isso costuma levar pouco tempo.', style: TextStyle(color: Colors.grey, height: 1.4)),
                      ],
                    )
                  else
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                         Row(
                          children: [
                            Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
                            SizedBox(width: 8),
                            Text('Acesso Delegado Ativo ✓', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                          ],
                        ),
                         SizedBox(height: 8),
                         Text('A Meire possui acesso seguro ao seu e-CAC para gerar e disparar suas Notas Fiscais no sistema federal de forma automática.', style: TextStyle(color: Colors.grey, height: 1.4))
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    ref.read(authServiceProvider).logout();
                    // Global auth listener in main.dart will handle navigation
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Sair da Conta'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDocument(String doc) {
    if (doc.length == 11) {
      return '${doc.substring(0, 3)}.${doc.substring(3, 6)}.${doc.substring(6, 9)}-${doc.substring(9, 11)}';
    } else if (doc.length == 14) {
      return '${doc.substring(0, 2)}.${doc.substring(2, 5)}.${doc.substring(5, 8)}/${doc.substring(8, 12)}-${doc.substring(12, 14)}';
    }
    return doc;
  }

  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Seu Perfil MEI",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: MeireTheme.primaryColor,
          ),
        ),
        SizedBox(height: 8),
        Text(
          "Gerencie suas informações e acesse seus dados com segurança.",
          style: TextStyle(color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required List<Widget> children,
    bool isVault = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isVault
              ? MeireTheme.accentColor.withValues(alpha: 0.5)
              : (isDark ? Colors.white10 : MeireTheme.iceGray),
          width: isVault ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isVault
                ? MeireTheme.accentColor.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon,
                  color: isVault
                      ? MeireTheme.accentColor
                      : MeireTheme.primaryColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (isVault) ...[
                const Spacer(),
                const Icon(Icons.lock, size: 16, color: Colors.grey),
              ]
            ],
          ),
          const SizedBox(height: 24),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(label,
              style: const TextStyle(
                  color: Colors.grey, fontWeight: FontWeight.w500)),
        ),
        Expanded(
          flex: 3,
          child:
              Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }
}
