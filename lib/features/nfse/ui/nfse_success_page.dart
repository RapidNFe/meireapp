import 'package:flutter/material.dart';
import 'package:meire/core/ui/theme.dart';
import 'package:meire/features/nfse/ui/widgets/painel_processamento_pdf.dart';

class NfseSuccessPage extends StatefulWidget {
  const NfseSuccessPage({super.key});

  @override
  State<NfseSuccessPage> createState() => _NfseSuccessPageState();
}

class _NfseSuccessPageState extends State<NfseSuccessPage> {
  bool _canViewPdf = false;
  Map<String, dynamic>? _invoiceData;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _invoiceData = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      _initialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_invoiceData == null) {
      return const Scaffold(body: Center(child: Text("Erro: Dados da nota não encontrados.")));
    }

    final String chaveAcesso = _invoiceData!['chaveAcesso'] ?? 'N/A';
    final String idNota = _invoiceData!['idNota'] ?? 'N/A';

    return Scaffold(
      backgroundColor: MeireTheme.primaryColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  color: Colors.greenAccent,
                  size: 100,
                ),
                const SizedBox(height: 24),
                const Text(
                  'NFS-e Emitida com Sucesso!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Sua Nota Fiscal de Serviços foi gerada e enviada para o Sistema Nacional.',
                  style: TextStyle(fontSize: 14, color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                
                // 🕒 PAINEL DE SINCRONIZAÇÃO (Sala de Espera)
                PainelProcessamentoPDF(
                  chaveAcesso: chaveAcesso,
                  onFinalizado: () {
                    setState(() {
                      _canViewPdf = true;
                    });
                  },
                ),
                
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      _buildInfoRow('ID da Nota (Meire)', idNota),
                      const SizedBox(height: 16),
                      const Divider(color: MeireTheme.iceGray),
                      const SizedBox(height: 16),
                      _buildInfoRow('Chave de Acesso Nacional', chaveAcesso),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: _canViewPdf ? () {
                    Navigator.pushNamed(context, '/pdf_viewer', arguments: chaveAcesso);
                  } : null,
                  icon: Icon(
                    Icons.picture_as_pdf, 
                    color: _canViewPdf ? Colors.white : Colors.grey
                  ),
                  label: Text(
                    _canViewPdf ? 'Ver Nota Fiscal Oficial' : 'Gerando PDF Oficial...', 
                    style: TextStyle(
                      color: _canViewPdf ? Colors.white : Colors.grey,
                      fontWeight: FontWeight.bold
                    )
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _canViewPdf ? const Color(0xFF00E676) : Colors.white,
                    minimumSize: const Size(double.infinity, 54),
                    disabledBackgroundColor: Colors.white.withValues(alpha: 0.6),
                    elevation: _canViewPdf ? 4 : 0,
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _canViewPdf ? () {
                    Navigator.pushNamed(context, '/pdf_viewer', arguments: chaveAcesso);
                  } : null,
                  icon: const Icon(Icons.share, color: Colors.white),
                  label: const Text('Compartilhar Nota', style: TextStyle(color: Colors.white)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white38),
                    minimumSize: const Size(double.infinity, 54),
                  ),
                ),
                const SizedBox(height: 48),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/hub');
                  },
                  child: const Text('Voltar ao Dashboard', style: TextStyle(color: Colors.white70, fontSize: 16)),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(
          value, 
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: MeireTheme.primaryColor),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
