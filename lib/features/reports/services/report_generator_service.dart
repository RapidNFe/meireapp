import 'package:flutter/foundation.dart';
import 'package:meire/features/hub/provider/notas_fiscais_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pocketbase/pocketbase.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

class ReportGeneratorService {
  final PocketBase _pb;

  ReportGeneratorService(this._pb);

  Future<RecordModel?> generateAndUploadReport({
    required String userId,
    required DateTime start,
    required DateTime end,
    required List<NotaFiscal> allNotas,
    required String userName,
    required String userCnpj,
  }) async {
    final pdf = pw.Document();

    // Filtra as notas pelo período selecionado
    final filteredNotas = allNotas.where((n) {
      return n.created.isAfter(start.subtract(const Duration(minutes: 1))) &&
             n.created.isBefore(end.add(const Duration(days: 1)));
    }).toList();

    // TRAVA DE SEGURANÇA: Se não houver notas, não gera arquivo vazio
    if (filteredNotas.isEmpty) {
      throw Exception("Não existem notas fiscais emitidas neste período. Tente outro intervalo.");
    }

    double total = filteredNotas.fold(0, (sum, n) => sum + n.valor);

    final String periodoStr = 
        "${DateFormat('dd/MM/yyyy').format(start)} - ${DateFormat('dd/MM/yyyy').format(end)}";

    // 🎨 Layout do PDF
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header: Logo e Título
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('MEIRI', 
                      style: pw.TextStyle(
                        fontSize: 24, 
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.teal,
                      )
                    ),
                    pw.Text('Sua contabilidade inteligente', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('RELATÓRIO DE FATURAMENTO', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                    pw.Text(periodoStr, style: const pw.TextStyle(fontSize: 12, color: PdfColors.teal)),
                  ],
                ),
              ],
            ),
            pw.Divider(height: 32, thickness: 0.5),

            // User Info
            pw.Row(
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('EMPRESA: $userName', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text('CNPJ: $userCnpj'),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 24),

            // Sumário
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: const pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('NOTAS EMITIDAS: ${filteredNotas.length}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text('TOTAL BRUTO: R\$ ${NumberFormat("#,##0.00", "pt_BR").format(total)}', 
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.teal700, fontSize: 14)),
                ],
              ),
            ),
            pw.SizedBox(height: 24),

            // Tabela de Notas
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              children: [
                // Header
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.teal900),
                  children: [
                    _buildCell('Data', isHeader: true),
                    _buildCell('Cliente', isHeader: true),
                    _buildCell('Nº Nota', isHeader: true),
                    _buildCell('Valor (R\$)', isHeader: true),
                  ],
                ),
                // Linhas
                ...filteredNotas.map((n) => pw.TableRow(
                  children: [
                    _buildCell(DateFormat('dd/MM/yyyy').format(n.created)),
                    _buildCell(n.tomadorNome),
                    _buildCell(n.numeroNota),
                    _buildCell(NumberFormat("#,##0.00", "pt_BR").format(n.valor)),
                  ],
                )),
              ],
            ),

            pw.SizedBox(height: 40),
            pw.Center(
              child: pw.Text('Gerado em ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())} via Meiri App.',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
            ),
          ];
        },
      ),
    );

    try {
      // 🚀 Salva no PocketBase
      final bytes = await pdf.save();
      
      // Criar o MultipartFile
      final file = http.MultipartFile.fromBytes(
        'arquivo_pdf',
        bytes,
        filename: 'report_${DateFormat('yyyyMMdd').format(start)}.pdf',
      );

      // 📦 Blindagem do Body para Multipart
      final Map<String, dynamic> body = {
        'user_id': userId.toString(),
        'periodo': periodoStr.toString(),
        'valor_total': total.toString(), // PocketBase Multipart prefere strings
      };

      debugPrint('🚀 [Relatório] Enviando Payload Blindado: $body');

      final record = await _pb.collection('relatorios_faturamento').create(
        body: body,
        files: [file],
      );

      return record;
    } catch (e) {
      debugPrint('❌ Erro ao salvar relatório no PB: $e');
      return null;
    }
  }

  pw.Widget _buildCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 9,
          color: isHeader ? PdfColors.white : PdfColors.black,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }
}
