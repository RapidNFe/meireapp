import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:meire/core/ui/theme.dart';
import 'package:meire/features/auth/services/auth_service.dart';
import 'package:meire/features/nfse/services/certificate_service.dart';
import 'package:meire/core/services/pocketbase_service.dart';

class CertificadoOnboardingPage extends ConsumerStatefulWidget {
  const CertificadoOnboardingPage({super.key});

  @override
  ConsumerState<CertificadoOnboardingPage> createState() => _CertificadoOnboardingPageState();
}

class _CertificadoOnboardingPageState extends ConsumerState<CertificadoOnboardingPage> {
  bool _isLoading = false;
  File? _selectedFile;
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pfx'],
      );

      if (result != null) {
        setState(() {
          _selectedFile = File(result.files.single.path!);
        });
        _showPasswordDialog();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erro ao selecionar arquivo.")),
      );
    }
  }

  void _showPasswordDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Senha do Certificado"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Digite a senha do arquivo .pfx para validarmos o acesso."),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Senha",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _uploadCertificate();
            },
            child: const Text("Validar e Salvar"),
          ),
        ],
      ),
    );
  }

  Future<void> _uploadCertificate() async {
    if (_selectedFile == null || _passwordController.text.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      await ref.read(certificateServiceProvider).depositCertificate(
        _selectedFile!,
        _passwordController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Certificado salvo com sucesso!")),
        );
        Navigator.of(context).pushNamedAndRemoveUntil('/hub', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro: ${e.toString().replaceAll('Exception: ', '')}")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _iniciarCompraParceiro() async {
    const String numeroVendedor = "5562999999999"; // TODO: Número real da certificadora
    const String mensagem = "Olá! Sou cliente do app Meiri. Vi que temos uma parceria com valor exclusivo para nós e quero garantir meu Certificado Digital A1 com esse desconto!";
    final Uri urlWhatsApp = Uri.parse("https://wa.me/$numeroVendedor?text=${Uri.encodeComponent(mensagem)}");

    try {
      if (await canLaunchUrl(urlWhatsApp)) {
        await launchUrl(urlWhatsApp, mode: LaunchMode.externalApplication);
        
        // Atualiza status para aguardando
        await ref.read(certificateServiceProvider).updateOnboardingStatus('comprando_parceiro');
        
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Aguardamos o seu retorno após a compra!")),
          );
          // Opcional: Recarrega a tela para mostrar estado de espera
          setState(() {});
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erro ao abrir WhatsApp.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final onboardingStatus = user?.getStringValue('status_onboarding_nota') ?? 'pendente';

    return Scaffold(
      backgroundColor: MeireTheme.primaryColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              const Icon(Icons.shield_outlined, color: Colors.greenAccent, size: 80),
              const SizedBox(height: 32),
              const Text(
                "Passo Final: Certificado Digital",
                style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                "Para emitir notas automaticamente pelo Sistema Nacional, você precisa de um Certificado Digital A1 ativo.",
                style: TextStyle(color: Colors.white70, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              if (onboardingStatus == 'comprando_parceiro') ...[
                _buildWaitingState(),
              ] else ...[
                _buildOptionA(),
                const SizedBox(height: 24),
                _buildOptionB(),
              ],

              const SizedBox(height: 48),
              TextButton(
                onPressed: () => ref.read(authServiceProvider).logout(),
                child: const Text("Sair da conta", style: TextStyle(color: Colors.white54)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionA() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Icon(Icons.file_upload_outlined, color: MeireTheme.primaryColor, size: 32),
          const SizedBox(height: 16),
          const Text(
            "Já tenho o arquivo",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 8),
          const Text(
            "Se você já possui o arquivo .pfx e a senha, faça o upload agora.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _pickFile,
              style: ElevatedButton.styleFrom(
                backgroundColor: MeireTheme.primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white))
                : const Text("Selecionar Arquivo .pfx"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionB() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF003D2A), // Fundo verde escuro premium
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.amber.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              "💎 BENEFÍCIO EXCLUSIVO MEIRI",
              style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "Adquirir com Desconto",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 8),
          const Text(
            "Garantimos um valor especial para clientes Meiri através da nossa certificadora parceira.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _iniciarCompraParceiro,
              icon: const Icon(Icons.chat_bubble_outline, size: 24),
              label: const Text("Garantir Certificado com Desconto", style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaitingState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        children: [
          const Icon(Icons.hourglass_empty_rounded, color: Colors.amber, size: 48),
          const SizedBox(height: 24),
          const Text(
            "Pronto! Você foi redirecionado.",
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            "Assim que finalizar a compra com nosso parceiro e receber seu arquivo .pfx, basta voltar aqui para cadastrá-lo.",
            style: TextStyle(color: Colors.white70, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          OutlinedButton(
            onPressed: () => setState(() {
               // Permite ao usuário voltar pro fluxo de upload caso tenha o arquivo
               ref.read(certificateServiceProvider).updateOnboardingStatus('pendente');
            }),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white38),
            ),
            child: const Text("Voltar para opções de envio"),
          ),
        ],
      ),
    );
  }
}
