import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';

class PdfReceiptService {
  static Future<Uint8List> generateReceipt({
    required String clientName,
    required String clientCnpj,
    required double amount,
    required String description,
  }) async {
    final pdf = pw.Document();
    final NumberFormat currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final String dateString = DateFormat('dd/MM/yyyy HH:mm', 'pt_BR').format(DateTime.now());

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text("PREFEITURA MUNICIPAL", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                      pw.Text("Nota Fiscal de Serviço Eletrônica - NFS-e", style: const pw.TextStyle(fontSize: 12)),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                    ),
                    child: pw.Column(
                      children: [
                        pw.Text("Número da Nota", style: const pw.TextStyle(fontSize: 10)),
                        pw.Text("2024/0001", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
              pw.Divider(thickness: 1, color: PdfColors.grey300),
              pw.SizedBox(height: 16),
              
              // Prestador
              pw.Text("PRESTADOR DE SERVIÇOS", style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
              pw.SizedBox(height: 4),
              pw.Text("Fernando (MEI)"),
              pw.Text("CNPJ: 00.000.000/0001-00"),
              pw.SizedBox(height: 16),
              
              // Tomador
              pw.Text("TOMADOR DE SERVIÇOS", style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
              pw.SizedBox(height: 4),
              pw.Text("Nome/Razão Social: $clientName"),
              pw.Text("CPF/CNPJ: $clientCnpj"),
              pw.SizedBox(height: 16),

              // Discriminação
              pw.Text("DISCRIMINAÇÃO DOS SERVIÇOS", style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(12),
                margin: const pw.EdgeInsets.only(top: 8, bottom: 16),
                decoration: const pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                child: pw.Text(description),
              ),
              
              // Valor Total
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text("VALOR TOTAL DA NOTA: ", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  pw.Text(currencyFormat.format(amount), style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.green800)),
                ],
              ),
              pw.SizedBox(height: 32),

              // Footer
              pw.Divider(thickness: 1, color: PdfColors.grey300),
              pw.SizedBox(height: 8),
              pw.Center(
                child: pw.Text(
                  "Gerado por Meire App em $dateString.\nDocumento sem valor fiscal (Modo Simulação).",
                  textAlign: pw.TextAlign.center,
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }
}
