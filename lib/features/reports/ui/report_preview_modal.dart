import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:meire/core/ui/theme.dart';
import 'package:meire/features/hub/provider/notas_fiscais_provider.dart';
import 'package:meire/features/reports/utils/pdf_generator_helper.dart';
import 'package:share_plus/share_plus.dart';

void mostrarModalRelatorio(BuildContext context, String periodo, List<NotaFiscal> notas) {
  final formatoData = DateFormat('dd/MM/yyyy', 'pt_BR');
  final formatoMoeda = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  double valorTotal = notas.fold(0.0, (soma, nota) => soma + nota.valor);

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. CABEÇALHO
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Visualização do Relatório",
                          style: TextStyle(
                            fontSize: 18, 
                            fontWeight: FontWeight.bold,
                            color: MeireTheme.primaryColor,
                          ),
                        ),
                        Text(
                          periodo,
                          style: TextStyle(
                            fontSize: 14, 
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              
              // 2. LISTA DE NOTAS
              Flexible(
                child: notas.isEmpty 
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text("Nenhuma nota encontrada no período."),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: notas.length,
                      separatorBuilder: (context, index) => Divider(color: Colors.grey.shade100, height: 1),
                      itemBuilder: (context, index) {
                        final nota = notas[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            nota.servico.isNotEmpty ? nota.servico : nota.tomadorNome,
                            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            formatoData.format(nota.competencia),
                            style: const TextStyle(fontSize: 11),
                          ),
                          trailing: Text(
                            formatoMoeda.format(nota.valor),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600, 
                              fontSize: 14,
                              color: MeireTheme.primaryColor,
                            ),
                          ),
                        );
                      },
                    ),
              ),
              
              const Divider(height: 1),
              const SizedBox(height: 16),

              // 3. RODAPÉ
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "TOTAL:",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    formatoMoeda.format(valorTotal),
                    style: const TextStyle(
                      fontSize: 20, 
                      fontWeight: FontWeight.bold, 
                      color: MeireTheme.accentColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              Row(
                children: [
                  // 🟢 BOTÃO DO WHATSAPP (Resumo em Texto)
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366), 
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        )
                      ),
                      icon: const Icon(Icons.wechat_outlined), 
                      label: const Text("WhatsApp", style: TextStyle(fontSize: 14)),
                      onPressed: () async {
                        // 1. Gerar os Bytes do PDF
                        final bytes = await PdfGeneratorHelper.generatePDFBytes(periodo, notas);
                        final safePeriodo = periodo.replaceAll('/', '_');

                        // 2. Montando o texto do Resumo
                        String mensagem = "*Resumo do Período - Meiri*\n\n";
                        mensagem += "📅 Período: $periodo\n";
                        mensagem += "📊 Notas: ${notas.length}\n";
                        mensagem += "💰 Faturamento: *${formatoMoeda.format(valorTotal)}*\n\n";
                        mensagem += "_Gerado pelo App Meiri._";

                        // 3. Compartilhando arquivo + texto via share_plus
                        // Isso permite selecionar o WhatsApp e enviar o PDF com a legenda
                        await Share.shareXFiles(
                          [
                            XFile.fromData(
                              bytes,
                              name: 'Relatorio_Meiri_$safePeriodo.pdf',
                              mimeType: 'application/pdf',
                            )
                          ],
                          text: mensagem,
                        );
                      },
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // 📄 BOTÃO DO PDF (Documento Completo)
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: MeireTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        )
                      ),
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text("PDF Completo", style: TextStyle(fontSize: 14)),
                      onPressed: () {
                        PdfGeneratorHelper.gerarEBaixarPDF(periodo, notas);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}
