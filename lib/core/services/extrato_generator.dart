import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:pocketbase/pocketbase.dart';

/// 🏛️ EXTRATO GENERATOR (PLATINUM EDITION)
/// Gera um documento PDF formal e imutável para conferência de ciclos de faturamento.
class ExtratoGenerator {
  static Future<Uint8List> gerarPdf({
    required String razaoSocialMei,
    required String tomadorNome,
    required String periodo,
    required double valorBruto,
    required double valorLiquido,
    required List<RecordModel> servicos,
    required bool isSalao,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // 🏙️ HEADER SOBERANO
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text("EXTRATO DE SERVIÇOS", 
                        // ignore: prefer_const_constructors
                        style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFF1E1E1E))),
                      pw.SizedBox(height: 4),
                      pw.Text("MEIRI PLATINUM v2.1", 
                        // ignore: prefer_const_constructors
                        style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600, letterSpacing: 1.2)),
                    ],
                  ),
                  pw.Container(
                    width: 40,
                    height: 40,
                    decoration: const pw.BoxDecoration(
                      color: PdfColor.fromInt(0xFFCC8B00), // Ouro Meiri
                      shape: pw.BoxShape.circle,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Divider(thickness: 1, color: PdfColors.grey300),
              pw.SizedBox(height: 20),
              
              // 📋 DADOS DO FATURAMENTO (Contexto)
              _buildContextRow("EMITENTE", razaoSocialMei.toUpperCase()),
              _buildContextRow("TOMADOR", tomadorNome.toUpperCase()),
              _buildContextRow("PERÍODO", periodo),
              pw.SizedBox(height: 30),

              // 📊 TABELA DE SERVIÇOS
              pw.Text("DETALHAMENTO DOS LANÇAMENTOS", 
                style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
              pw.SizedBox(height: 10),
              pw.TableHelper.fromTextArray(
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
                headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF1E1E1E)),
                cellStyle: const pw.TextStyle(fontSize: 10),
                cellAlignment: pw.Alignment.centerLeft,
                headers: isSalao 
                  ? <dynamic>['DATA', 'SERVIÇO', 'BRUTO (R\$)', 'MINHA PARTE (R\$)']
                  : <dynamic>['DATA', 'SERVIÇO', 'BRUTO (R\$)'],
                data: servicos.map((s) {
                  final List<dynamic> row = [
                    _formatDate(s.getStringValue('data_servico')),
                    s.getStringValue('descricao_servico').isEmpty ? "Serviço Prestado" : s.getStringValue('descricao_servico'),
                    s.getDoubleValue('valor_bruto').toStringAsFixed(2),
                  ];
                  if (isSalao) {
                    row.add(s.getDoubleValue('valor_liquido').toStringAsFixed(2));
                  }
                  return row;
                }).toList(),
              ),
              
              pw.Spacer(),

              // 💰 RESUMO FINANCEIRO (O Fechamento)
              pw.Container(
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey50,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
                  border: pw.Border.all(color: PdfColors.grey200),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                  children: [
                    pw.Text("RESUMO CONSOLIDADO", 
                      // ignore: prefer_const_constructors
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12, color: PdfColor.fromInt(0xFF1A5A38))),
                    pw.Divider(color: PdfColors.grey300),
                    _buildSummaryRow("Total Movimentado (Bruto)", "R\$ ${valorBruto.toStringAsFixed(2)}"),
                    if (isSalao) 
                      _buildSummaryRow("Retenção Parceiro (Cota-Parte)", "R\$ ${(valorBruto - valorLiquido).toStringAsFixed(2)}", isNegative: true),
                    pw.SizedBox(height: 10),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text("BASE PARA NFS-E (Soberania)", 
                          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                        pw.Text("R\$ ${valorLiquido.toStringAsFixed(2)}", 
                          // ignore: prefer_const_constructors
                          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFFCC8B00))),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 40),
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text("Este documento é um demonstrativo auxiliar de faturamento.", 
                      // ignore: prefer_const_constructors
                      style: pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
                    pw.Text("Gerado automaticamente pelo MEIRI - Bússola Financeira do MEI", 
                      style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              )
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildContextRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        children: [
          pw.SizedBox(width: 80, child: pw.Text(label, style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700, fontWeight: pw.FontWeight.bold))),
          pw.Text(value, style: const pw.TextStyle(fontSize: 9)),
        ],
      ),
    );
  }

  static pw.Widget _buildSummaryRow(String label, String value, {bool isNegative = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          pw.Text(value, style: pw.TextStyle(fontSize: 10, color: isNegative ? PdfColors.red800 : PdfColors.black)),
        ],
      ),
    );
  }

  static String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (_) {
      return dateStr;
    }
  }
}
