import 'package:flutter/material.dart';

/// 🛡️ CNAE VALIDATOR DIALOG (O Guardião)
/// Alerta o MEI quando um tomador não possui CNAE de Salão de Beleza.
class CnaeValidatorDialog extends StatelessWidget {
  final String razaoSocial;
  final String atividadePrincipal;
  final VoidCallback onConfirmarDireto;
  final VoidCallback onForcarSalao;

  const CnaeValidatorDialog({
    super.key,
    required this.razaoSocial,
    required this.atividadePrincipal,
    required this.onConfirmarDireto,
    required this.onForcarSalao,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E1E1E), // Dashboard Graphite
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Color(0xFFCC8B00)),
          SizedBox(width: 10),
          Text("Alerta de Conformidade", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            razaoSocial.toUpperCase(),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              "Atividade detectada:\n\"$atividadePrincipal\"",
              style: const TextStyle(color: Colors.white54, fontSize: 12, height: 1.4),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "A Lei do Salão Parceiro exige que o tomador seja um Salão de Beleza. Deseja seguir com faturamento 100% Direto?",
            style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
          ),
        ],
      ),
      actionsPadding: const EdgeInsets.all(16),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            onForcarSalao();
          },
          child: const Text("FORÇAR MODO SALÃO", style: TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A5A38), // Verde Floresta Elite
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            elevation: 0,
          ),
          onPressed: () {
            Navigator.pop(context);
            onConfirmarDireto();
          },
          child: const Text("FATURAR DIRETO (100%)", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
        ),
      ],
    );
  }
}
