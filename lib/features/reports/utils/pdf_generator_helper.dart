import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:meire/features/hub/provider/notas_fiscais_provider.dart';
import 'dart:typed_data';

class PdfGeneratorHelper {
  static Future<Uint8List> generatePDFBytes(String periodo, List<NotaFiscal> notas) async {
    // 1. Carregando a Logo
    pw.MemoryImage? logoImage;
    try {
      final logoBytes = await rootBundle.load('assets/images/logo.png');
      logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
    } catch (e) {
      // Logo opcional se falhar o carregamento
    }

    // 2. Preparando os Formatadores do pacote intl
    final formatoData = DateFormat('dd/MM/yyyy', 'pt_BR');
    final formatoMoeda = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    // 3. Ordenando as notas por data
    final sortedNotas = List<NotaFiscal>.from(notas);
    sortedNotas.sort((a, b) => b.competencia.compareTo(a.competencia));

    // 4. Calculando o Total Geral
    final double totalGeral = sortedNotas.fold(0, (sum, item) => sum + item.valor);

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            if (logoImage != null) 
              pw.Center(child: pw.Image(logoImage, width: 100)),
            
            pw.SizedBox(height: 16),
            
            pw.Center(
              child: pw.Text(
                "Relatório de Faturamento Meiri", 
                // ignore: prefer_const_constructors
                style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF004330)),
              ),
            ),
            
            pw.Center(
               child: pw.Text(
                "Período: $periodo", 
                style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700),
              ),
            ),
            
            pw.SizedBox(height: 24),

            pw.TableHelper.fromTextArray(
              headers: ['Data', 'Serviço', 'Valor'],
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF004330)),
              cellHeight: 30,
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.centerRight,
              },
              data: [
                ...sortedNotas.map((nota) {
                  return [
                    formatoData.format(nota.competencia),
                    nota.servico.isNotEmpty ? nota.servico : nota.tomadorNome,
                    formatoMoeda.format(nota.valor),
                  ];
                }),
                // Linha de Total
                ['', 'TOTAL GERAL', formatoMoeda.format(totalGeral)],
              ],
              cellStyle: const pw.TextStyle(fontSize: 10),
              oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
            ),
            
            pw.SizedBox(height: 32),
            
            pw.Divider(color: PdfColors.grey300),
            
            pw.Center(
              child: pw.Text(
                "Gerado automaticamente pelo Meire App em ${formatoData.format(DateTime.now())}",
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
              ),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static Future<void> gerarEBaixarPDF(String periodo, List<NotaFiscal> notas) async {
    final bytes = await generatePDFBytes(periodo, notas);
    final safePeriodo = periodo.replaceAll('/', '_');
    
    await Printing.sharePdf(
      bytes: bytes, 
      filename: 'Relatorio_Meiri_$safePeriodo.pdf',
    );
  }
}
