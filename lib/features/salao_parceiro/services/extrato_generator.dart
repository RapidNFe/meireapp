import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class ExtratoGenerator {
  static Future<void> gerarEFalhar(
      List<Map<String, dynamic>> lancamentos, 
      String nomeProfissional, 
      String nomeSalao) async {
    
    final pdf = pw.Document();
    final formatMoeda = NumberFormat.simpleCurrency(locale: 'pt_BR');
    final formatDate = DateFormat('dd/MM/yyyy');

    double totalBruto = 0.0;
    double totalCota = 0.0;

    final List<pw.TableRow> rows = [];
    
    // 1. Cabeçalho Simples
    rows.add(
      pw.TableRow(
        children: [
          pw.Text("DATA"),
          pw.Text("TOTAL"),
          pw.Text("COTA"),
        ],
      ),
    );

    // 2. Loop de Dados
    for (final l in lancamentos) {
      final bruto = (l['valor_total_cliente'] ?? 0.0).toDouble();
      final cota = (l['valor_cota_parte'] ?? 0.0).toDouble();
      totalBruto += bruto;
      totalCota += cota;
      
      final dataStr = l['data_servico'] ?? DateTime.now().toIso8601String();
      final dataFormatada = formatDate.format(DateTime.parse(dataStr));

      rows.add(
        pw.TableRow(
          children: [
            pw.Text(dataFormatada),
            pw.Text(formatMoeda.format(bruto)),
            pw.Text(formatMoeda.format(cota)),
          ],
        ),
      );
    }

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Text("EXTRATO MEIRI", style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Text("Profissional: $nomeProfissional"),
              pw.Text("Salao: $nomeSalao"),
              pw.SizedBox(height: 20),
              pw.Table(children: rows),
              pw.SizedBox(height: 30),
              pw.Divider(),
              pw.Text("TOTAL BRUTO: ${formatMoeda.format(totalBruto)}", 
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
              pw.SizedBox(height: 4),
              pw.Text("TOTAL A RECEBER: ${formatMoeda.format(totalCota)}", 
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }
}
