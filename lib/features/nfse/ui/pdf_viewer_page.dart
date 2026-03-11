import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:meire/core/ui/theme.dart';
import 'package:meire/features/nfse/services/pdf_receipt_service.dart';
import 'package:pdf/pdf.dart';
import 'dart:typed_data';

class PdfViewerPage extends StatefulWidget {
  final String clientName;
  final String clientCnpj;
  final double amount;
  final String description;

  const PdfViewerPage({
    super.key,
    required this.clientName,
    required this.clientCnpj,
    required this.amount,
    required this.description,
  });

  @override
  State<PdfViewerPage> createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  Uint8List? _pdfData;

  @override
  void initState() {
    super.initState();
    _generatePdf();
  }

  Future<void> _generatePdf() async {
    final data = await PdfReceiptService.generateReceipt(
      clientName: widget.clientName,
      clientCnpj: widget.clientCnpj,
      amount: widget.amount,
      description: widget.description,
    );
    setState(() {
      _pdfData = data;
    });
  }

  void _shareViaWhatsApp() async {
    if (_pdfData == null) return;
    
    // Convert Uint8List to XFile in memory for sharing
    final xFile = XFile.fromData(
      _pdfData!,
      name: 'nfse_${widget.clientName.replaceAll(' ', '_')}.pdf',
      mimeType: 'application/pdf',
    );

    await Share.shareXFiles(
      [xFile],
      text: 'Olá! Segue em anexo a Nota Fiscal de Serviço (NFS-e) emitida no Meire App.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recibo NFS-e'),
        backgroundColor: Colors.white,
        foregroundColor: MeireTheme.primaryColor,
        elevation: 1,
      ),
      body: _pdfData == null
          ? const Center(child: CircularProgressIndicator())
          : PdfPreview(
              build: (format) => _pdfData!,
              allowPrinting: true,
              allowSharing: false, // We will use our custom share button
              canChangeOrientation: false,
              canChangePageFormat: false,
              canDebug: false,
              pdfFileName: 'nfse_recibo.pdf',
              initialPageFormat: PdfPageFormat.a4,
            ),
      floatingActionButton: _pdfData == null ? null : FloatingActionButton.extended(
        onPressed: _shareViaWhatsApp,
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.share), // Can represent WhatsApp
        label: const Text('Compartilhar'),
      ),
    );
  }
}
