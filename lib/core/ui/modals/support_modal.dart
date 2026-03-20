import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:meire/core/ui/theme.dart';
import 'package:meire/core/services/pocketbase_service.dart';

class SupportModal {
  static const String numeroSuporte = "5562999999999";

  static final List<String> motivosSuporte = [
    "Dificuldade para emitir nota",
    "Problema com o Certificado Digital",
    "Dúvida sobre impostos/cálculos",
    "Erro no aplicativo",
    "Outros assuntos"
  ];

  static void show(BuildContext context, WidgetRef ref) {
    String? motivoSelecionado;
    final TextEditingController outroMotivoController = TextEditingController();
    final TextEditingController detalhesController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                top: 24, left: 24, right: 24,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Como podemos te ajudar?", 
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: MeireTheme.primaryColor),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Selecione o motivo para agilizarmos seu atendimento:",
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  
                  // Lista de Motivos
                  ...motivosSuporte.map((motivo) {
                    return ListTile(
                      title: Text(motivo),
                      leading: Radio<String>(
                        value: motivo,
                        // ignore: deprecated_member_use
                        groupValue: motivoSelecionado,
                        activeColor: MeireTheme.accentColor,
                        // ignore: deprecated_member_use
                        onChanged: (value) => setModalState(() => motivoSelecionado = value),
                      ),
                      contentPadding: EdgeInsets.zero,
                      onTap: () => setModalState(() => motivoSelecionado = motivo),
                    );
                  }),

                  // Campo dinâmico para "Outros"
                  if (motivoSelecionado == "Outros assuntos")
                    Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 16),
                      child: TextField(
                        controller: outroMotivoController,
                        decoration: const InputDecoration(
                          labelText: "Especifique o motivo",
                          hintText: "Ex: Dúvida sobre mensalidade",
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Detalhes adicionais
                  TextField(
                    controller: detalhesController,
                    decoration: const InputDecoration(
                      hintText: "Adicione mais detalhes se desejar...",
                    ),
                    maxLines: 2,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: motivoSelecionado == null 
                          ? null 
                          : () {
                              Navigator.pop(context);
                              _enviarMensagem(ref, motivoSelecionado!, outroMotivoController.text, detalhesController.text);
                            },
                      icon: const Icon(Icons.chat_bubble_outline, size: 24),
                      label: const Text("Iniciar Atendimento", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366), 
                        foregroundColor: Colors.white,
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  static Future<void> _enviarMensagem(WidgetRef ref, String motivo, String outro, String detalhes) async {
    final pb = ref.read(pbProvider);
    final user = pb.authStore.record;
    
    String nomeCliente = user?.getStringValue('name') ?? "Cliente Meiri";
    String cnpjCliente = user?.getStringValue('cnpj') ?? "Não informado";

    String motivoFinal = (motivo == "Outros assuntos" && outro.isNotEmpty) ? outro : motivo;

    String mensagem = "Olá, suporte da Meiri! 🚀\n\n"
        "👤 *Cliente:* $nomeCliente\n"
        "📄 *CNPJ:* $cnpjCliente\n"
        "🚨 *Motivo:* $motivoFinal\n";
    
    if (detalhes.isNotEmpty) {
      mensagem += "📝 *Detalhes:* $detalhes";
    }

    final Uri url = Uri.parse("https://wa.me/$numeroSuporte?text=${Uri.encodeComponent(mensagem)}");

    if (await launchUrl(url, mode: LaunchMode.externalApplication)) {
      // Sucesso
    }
  }
}
