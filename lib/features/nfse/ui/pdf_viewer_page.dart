import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:meiri/core/ui/theme.dart';
import 'package:meiri/features/nfse/services/notas_fiscais_service.dart';
import 'package:pdf/pdf.dart';
import 'dart:typed_data';

class PdfViewerPage extends ConsumerStatefulWidget {
  const PdfViewerPage({super.key});

  @override
  ConsumerState<PdfViewerPage> createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends ConsumerState<PdfViewerPage> {
  Uint8List? _pdfData;
  String? _chaveAcesso;
  bool _isLoading = true;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_chaveAcesso == null) {
      _chaveAcesso = ModalRoute.of(context)?.settings.arguments as String?;
      if (_chaveAcesso != null) {
        _fetchPdf();
      } else {
        setState(() {
          _error = "Chave de acesso não encontrada.";
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchPdf() async {
    try {
      final data = await ref.read(notasFiscaisServiceProvider).getDanfsePdf(_chaveAcesso!);
      if (mounted) {
        setState(() {
          _pdfData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  void _sharePdf() async {
    if (_pdfData == null) return;
    
    final xFile = XFile.fromData(
      _pdfData!,
      name: 'NFS-e_${_chaveAcesso?.substring(0, 8)}.pdf',
      mimeType: 'application/pdf',
    );

    await Share.shareXFiles(
      [xFile],
      text: 'Olá! Segue em anexo a Nota Fiscal de Serviço (NFS-e) oficial emitida no Meiri App.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nota Fiscal Oficial'),
        backgroundColor: Colors.white,
        foregroundColor: MeiriTheme.primaryColor,
        elevation: 1,
        actions: [
          if (_pdfData != null)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _sharePdf,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: MeiriTheme.primaryColor),
                  SizedBox(height: 16),
                  Text("Buscando PDF oficial no Governo...", style: TextStyle(color: MeiriTheme.primaryColor)),
                ],
              ),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 60, color: Colors.orange),
                        const SizedBox(height: 16),
                        Text(_error!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _isLoading = true;
                              _error = null;
                            });
                            _fetchPdf();
                          },
                          child: const Text("Tentar Novamente"),
                        )
                      ],
                    ),
                  ),
                )
              : PdfPreview(
                  build: (format) => _pdfData!,
                  allowPrinting: true,
                  allowSharing: false,
                  canChangeOrientation: false,
                  canChangePageFormat: false,
                  canDebug: false,
                  pdfFileName: 'NFS-e_meiri.pdf',
                  initialPageFormat: PdfPageFormat.a4,
                ),
      floatingActionButton: _pdfData == null ? null : FloatingActionButton.extended(
        onPressed: _sharePdf,
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.share),
        label: const Text('Compartilhar'),
      ),
    );
  }
}
