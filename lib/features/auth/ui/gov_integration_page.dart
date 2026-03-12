import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meire/core/ui/theme.dart';
import 'package:meire/features/auth/services/auth_service.dart';
import 'package:url_launcher/url_launcher.dart';

class GovIntegrationPage extends ConsumerStatefulWidget {
  const GovIntegrationPage({super.key});

  @override
  ConsumerState<GovIntegrationPage> createState() => _GovIntegrationPageState();
}

class _GovIntegrationPageState extends ConsumerState<GovIntegrationPage> {
  bool _isLoading = false;
  final String _cnpjContabilidade = '28.413.885/0001-70';

  Future<void> _launchGovPortal() async {
    final Uri url = Uri.parse('https://cav.receita.fazenda.gov.br/');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Não foi possível abrir o site oficial.')),
        );
      }
    }
  }

  void _copyCnpj() {
    Clipboard.setData(ClipboardData(text: _cnpjContabilidade));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('CNPJ copiado para a área de transferência!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _submitData() async {
    setState(() => _isLoading = true);

    final authService = ref.read(authServiceProvider);
    final user = authService.currentUser;

    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro: Usuário não logado.')),
        );
        setState(() => _isLoading = false);
      }
      return;
    }

    try {
      await authService.authorizeProcuration(user.id);
      if (mounted) {
        await authService.isServerAvailable();
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/hub');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception:', '').trim()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Autorização de Emissão'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: MeireTheme.primaryColor,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.security_outlined,
                size: 64,
                color: MeireTheme.accentColor,
              ),
              const SizedBox(height: 16),
              const Text(
                'Delegue sua Autorização',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: MeireTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Para que a Meire emita suas notas fiscais, você precisa nos autorizar no portal e-CAC da Receita Federal. É simples e leva apenas 1 minuto.',
                textAlign: TextAlign.center,
                style: TextStyle(height: 1.5, color: Colors.grey),
              ),
              const SizedBox(height: 32),

              // Botão de Copiar CNPJ
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: MeireTheme.accentColor.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: MeireTheme.accentColor.withValues(alpha: 0.2)),
                ),
                child: Column(
                  children: [
                    const Text(
                      'CNPJ DA CONTABILIDADE (MEIRE)',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: MeireTheme.accentColor),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _cnpjContabilidade,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: MeireTheme.primaryColor),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _copyCnpj,
                          icon: const Icon(Icons.copy, size: 20, color: MeireTheme.accentColor),
                          tooltip: 'Copiar CNPJ',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Steps
              _buildStep(1, 'Clique no botão abaixo para abrir o e-CAC.'),
              const SizedBox(height: 16),
              _buildStep(2, 'Ao entrar no e-CAC, clique em "Alterar Perfil de Acesso" no topo da tela e selecione o seu CNPJ.'),
              const SizedBox(height: 16),
              _buildStep(3, 'Vá em "Procurações" -> "Cadastrar Procuração".'),
              const SizedBox(height: 16),
              _buildStep(4, 'Cole nosso CNPJ e selecione a opção:\n"Todos os serviços existentes e os que vierem a ser disponibilizados".'),
              
              const SizedBox(height: 48),

              ElevatedButton.icon(
                onPressed: _launchGovPortal,
                icon: const Icon(Icons.launch),
                label: const Text('1. Acessar Portal e-CAC'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: MeireTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),

              const SizedBox(height: 16),

              ElevatedButton(
                onPressed: _isLoading ? null : _submitData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: MeireTheme.accentColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text(
                        '2. Já autorizei a Meire',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep(int number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: const BoxDecoration(
            color: MeireTheme.primaryColor,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            number.toString(),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14, height: 1.4, color: MeireTheme.primaryColor),
          ),
        ),
      ],
    );
  }
}
