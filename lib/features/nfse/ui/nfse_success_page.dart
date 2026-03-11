import 'package:flutter/material.dart';
import 'package:meire/core/ui/theme.dart';

class NfseSuccessPage extends StatelessWidget {
  const NfseSuccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Generate mock random invoice numbers
    const String invoiceNumber = '000.003.542';
    const String verificationCode = 'B9A1-X4C2-93KL';

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
                const SizedBox(height: 48),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      _buildInfoRow('Número da Nota', invoiceNumber),
                      const SizedBox(height: 16),
                      const Divider(color: MeireTheme.iceGray),
                      const SizedBox(height: 16),
                      _buildInfoRow('Código de Verificação', verificationCode),
                    ],
                  ),
                ),
                const SizedBox(height: 48),
                ElevatedButton.icon(
                  onPressed: () {
                    // Mock View PDF
                  },
                  icon: const Icon(Icons.picture_as_pdf, color: MeireTheme.primaryColor),
                  label: const Text('Visualizar PDF', style: TextStyle(color: MeireTheme.primaryColor)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 54),
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () {
                    // Mock Share
                  },
                  icon: const Icon(Icons.share, color: Colors.white),
                  label: const Text('Compartilhar Recibo', style: TextStyle(color: Colors.white)),
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
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: MeireTheme.primaryColor)),
      ],
    );
  }
}
