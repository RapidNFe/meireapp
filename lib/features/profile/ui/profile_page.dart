import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:meire/core/ui/theme.dart';
import 'package:meire/features/auth/services/auth_service.dart';
import 'package:meire/features/auth/ui/gov_integration_page.dart';
import 'package:meire/core/services/pocketbase_service.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  bool _isLoadingSwitch = false;

  bool _validarRequisitosProducao(RecordModel user) {
    List<String> pendencias = [];

    final cnpj = user.getStringValue('cnpj');
    final razaoSocial = user.getStringValue('razao_social');
    final im = user.getStringValue('inscricao_municipal');
    final cep = user.getStringValue('cep');
    // final cnae = user.getStringValue('cnae_padrao'); // Placeholder if you add later

    if (cnpj.isEmpty || cnpj.length != 14) pendencias.add("CNPJ inválido");
    if (razaoSocial.isEmpty) pendencias.add("Razão Social ausente");
    
    // Trava de Segurança: A IM é obrigatória para nota real na maioria das prefeituras
    if (im.isEmpty) pendencias.add("Inscrição Municipal (IM) ausente");
    if (cep.isEmpty) pendencias.add("CEP ausente");

    if (pendencias.isNotEmpty) {
      _mostrarAlertaPendencias(pendencias);
      return false;
    }
    return true;
  }

  void _mostrarAlertaPendencias(List<String> pendencias) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('Cadastro Incompleto'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Para ativar o Modo Real, corrija as seguintes pendências no seu perfil:'),
            const SizedBox(height: 16),
            ...pendencias.map((p) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text('• $p', style: const TextStyle(fontWeight: FontWeight.bold, color: MeireTheme.primaryColor)),
            )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Entendi', style: TextStyle(color: MeireTheme.accentColor, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = ref.watch(authServiceProvider);
    final user = authService.currentUser;

    if (user == null) {
      return const Center(child: Text('Nenhum dado do usuário encontrado.'));
    }

    final cnpj = user.getStringValue('cnpj');
    var displayName = user.getStringValue('name');
    if (displayName.isEmpty) displayName = user.getStringValue('nome_fantasia');
    if (displayName.isEmpty) displayName = user.getStringValue('razao_social');
    
    final email = user.getStringValue('email');
    final statusRegistro = user.getStringValue('status_registro');
    final modoProducao = user.getBoolValue('producao');

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
              
              // 🎛️ NOVA SEÇÃO: CONTROLE DE AMBIENTE (KILL SWITCH)
              _buildCard(
                context: context,
                title: 'Configurações de Emissão',
                icon: Icons.settings_remote,
                isVault: true,
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Modo de Operação',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      modoProducao ? '🚀 PRODUÇÃO (Notas Reais)' : '🛠️ HOMOLOGAÇÃO (Testes)',
                      style: TextStyle(
                        color: modoProducao ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    value: modoProducao,
                    activeThumbColor: Colors.green,
                    inactiveThumbColor: Colors.orange,
                    onChanged: _isLoadingSwitch ? null : (bool value) async {
                      if (value == true) {
                        if (!_validarRequisitosProducao(user)) return;
                      }

                      setState(() => _isLoadingSwitch = true);
                      try {
                        await ref.read(pbProvider).collection('users').update(user.id, body: {
                          'producao': value,
                        });
                        
                        // Forçamos o refresh do record para atualizar o provider global
                        await ref.read(pbProvider).collection('users').authRefresh();
                        
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(value ? '🚀 Meire em Produção!' : '🛠️ Modo de Testes Ativado.'),
                              backgroundColor: value ? Colors.green : Colors.orange,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Erro ao atualizar ambiente. Verifique sua conexão.')),
                          );
                        }
                      } finally {
                        if (mounted) setState(() => _isLoadingSwitch = false);
                      }
                    },
                  ),
                  const Divider(height: 32),
                  const Text(
                    'Dica: Em Modo de Testes, as notas não possuem valor legal e servem apenas para validar o fluxo.',
                    style: TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              _buildCard(
                context: context,
                title: 'Informações Pessoais',
                icon: Icons.person_outline,
                children: [
                  _InfoRow(label: 'Nome Completo', value: displayName),
                  const Divider(height: 24),
                  _InfoRow(label: 'E-mail', value: email),
                  const Divider(height: 24),
                  _InfoRow(label: 'CPF', value: _formatDocument(user.getStringValue('cpf'))),
                  const Divider(height: 24),
                  _InfoRow(label: 'CNPJ', value: _formatDocument(cnpj)),
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
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    ref.read(authServiceProvider).logout();
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
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () => _mostrarModalDeExclusao(context, ref),
                  icon: const Icon(Icons.delete_forever, color: Colors.redAccent, size: 20),
                  label: const Text(
                    'Excluir Minha Conta e Dados',
                    style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 56),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarModalDeExclusao(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Excluir Conta Definitivamente?'),
          content: const Text(
            'Esta ação é irreversível. Todos os seus clientes, histórico de notas fiscais e cálculos de impostos serão apagados dos nossos servidores imediatamente, em conformidade com a LGPD.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                try {
                  final authService = ref.read(authServiceProvider);
                  final userId = authService.currentUser?.id;
                  
                  if (userId != null) {
                    await authService.deleteAccount(userId);
                    if (context.mounted) Navigator.of(context).pop();
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Erro ao excluir conta. Tente novamente.')),
                    );
                  }
                }
              },
              child: const Text('Sim, Excluir Tudo'),
            ),
          ],
        );
      },
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
