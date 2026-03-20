import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:meire/core/ui/theme.dart';
import 'package:meire/core/services/pocketbase_service.dart';

class SupportModal {
  static const String numeroSuporte = "5562982339927";

  static final List<Map<String, dynamic>> categorias = [
    {
      'titulo': 'Certificado Digital',
      'icone': Icons.lock_outline,
      'subitens': [
        'Dúvida na compra do certificado parceiro',
        'Erro ao validar a senha do certificado',
        'Meu certificado expirou, como renovar?',
        'O sistema não reconhece meu arquivo PFX',
      ],
    },
    {
      'titulo': 'Emissão de Nota (NFS-e)',
      'icone': Icons.description_outlined,
      'subitens': [
        'A nota foi rejeitada pelo Governo',
        'Minha cidade não aparece na lista',
        'Dúvida sobre qual CNAE ou Código usar',
        'Como cancelar ou substituir uma nota?',
      ],
    },
    {
      'titulo': 'Dados Cadastrais & Perfil',
      'icone': Icons.business_outlined,
      'subitens': [
        'Meu CNPJ está com endereço errado',
        'Não sei o meu Código IBGE/Município',
        'Quero alterar e-mail ou telefone',
      ],
    },
    {
      'titulo': 'Assinatura e Pagamentos',
      'icone': Icons.credit_card_outlined,
      'subitens': [
        'Dúvida sobre o plano de R\$ 27,90',
        'Problema no pagamento do boleto/PIX',
      ],
    },
    {
      'titulo': 'Outros Assuntos',
      'icone': Icons.more_horiz,
      'subitens': ['Outros'],
    }
  ];

  static void show(BuildContext context, WidgetRef ref) {
    String? subitemSelecionado;
    final TextEditingController detalhesController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
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
                  
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          ...categorias.map((cat) {
                            return Card(
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                side: BorderSide(color: Colors.grey.shade200),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ExpansionTile(
                                leading: Icon(cat['icone'], color: MeireTheme.primaryColor),
                                title: Text(cat['titulo'], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                                shape: const RoundedRectangleBorder(side: BorderSide.none),
                                children: [
                                  Column(
                                    children: (cat['subitens'] as List<String>).map((sub) {
                                      return RadioListTile<String>(
                                        title: Text(sub, style: const TextStyle(fontSize: 14)),
                                        value: sub,
                                        // ignore: deprecated_member_use
                                        groupValue: subitemSelecionado,
                                        // ignore: deprecated_member_use
                                        onChanged: (val) {
                                          setModalState(() {
                                            subitemSelecionado = val;
                                            if (val != null) {
                                              detalhesController.text = "Olá, estou com problemas em: $val";
                                            }
                                          });
                                        },
                                        activeColor: MeireTheme.accentColor,
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            );
                          }),

                          const SizedBox(height: 16),

                          TextField(
                            controller: detalhesController,
                            maxLines: 3,
                            decoration: InputDecoration(
                              hintText: "Adicione mais detalhes se desejar...",
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.all(16),
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton.icon(
                              onPressed: subitemSelecionado == null 
                                  ? null 
                                  : () {
                                      Navigator.pop(context);
                                      _enviarMensagem(ref, subitemSelecionado!, detalhesController.text);
                                    },
                              icon: const Icon(Icons.chat_bubble_outline, size: 24),
                              label: const Text("Iniciar Atendimento", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF25D366), 
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ],
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

  static Future<void> _enviarMensagem(WidgetRef ref, String motivo, String detalhes) async {
    final pb = ref.read(pbProvider);
    final user = pb.authStore.record;
    
    String nomeCliente = user?.getStringValue('name') ?? "Cliente Meiri";
    String cnpjCliente = user?.getStringValue('cnpj') ?? "Não informado";

    String mensagem = "Olá, suporte da Meiri! 🚀\n\n"
        "👤 *Cliente:* $nomeCliente\n"
        "📄 *CNPJ:* $cnpjCliente\n";
    
    if (detalhes.isNotEmpty) {
      mensagem += "\n$detalhes";
    } else {
      mensagem += "🚨 *Motivo:* $motivo\n";
    }

    final Uri url = Uri.parse("https://wa.me/$numeroSuporte?text=${Uri.encodeComponent(mensagem)}");

    if (await launchUrl(url, mode: LaunchMode.externalApplication)) {
      // Sucesso
    }
  }
}
