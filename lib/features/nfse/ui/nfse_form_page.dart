import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meire/core/ui/theme.dart';
import 'package:meire/core/utils/currency_input_formatter.dart';
import 'package:meire/core/utils/validators.dart';
import 'package:meire/features/nfse/services/notas_fiscais_service.dart';
import 'package:meire/features/hub/provider/notas_fiscais_provider.dart';
import 'package:meire/features/nfse/provider/favorite_services_provider.dart';
import 'package:meire/features/shared/ui/widgets/meire_assistant_widget.dart';
import 'package:shimmer/shimmer.dart';

class NfseFormPage extends ConsumerStatefulWidget {
  const NfseFormPage({super.key});

  @override
  ConsumerState<NfseFormPage> createState() => _NfseFormPageState();
}

class _NfseFormPageState extends ConsumerState<NfseFormPage> {
  final _formKey = GlobalKey<FormState>();

  final _documentController = TextEditingController();
  final _nameController = TextEditingController();

  final _valueController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _selectedServiceId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _documentController.addListener(_onDocumentChanged);
  }

  @override
  void dispose() {
    _documentController.removeListener(_onDocumentChanged);
    _documentController.dispose();
    _nameController.dispose();
    _valueController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _onDocumentChanged() {
    String text = _documentController.text;
    String cleanText = text.replaceAll(RegExp(r'[^0-9]'), '');

    // Auto-fill mock for CNPJ size (14 digits)
    if (cleanText.length == 14 && _nameController.text.isEmpty) {
      setState(() {
        _nameController.text = "EMPRESA MOCKADA DE TESTE LTDA";
      });
    }
  }

  void _submitNfse() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (_selectedServiceId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Por favor, selecione um Serviço Prestado.')),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      // Simulates SERPRO/Receita API delay
      await Future.delayed(const Duration(seconds: 3));

      // Parse amount
      final cleanValue = _valueController.text
          .replaceAll('R\$', '')
          .replaceAll('.', '')
          .replaceAll(',', '.')
          .trim();
      final double amount = double.tryParse(cleanValue) ?? 0.0;

      // Add to PocketBase via Service
      try {
        await ref.read(notasFiscaisServiceProvider).addNotaFiscal(
              clientName: _nameController.text,
              clientCnpj: _documentController.text,
              amount: amount,
              description: _descriptionController.text,
            );

        // Refresh dashboard data
        ref.invalidate(revenueStatsProvider);

        if (mounted) {
          Navigator.pushReplacementNamed(context, '/nfse_success');
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao emitir nota: $e')),
          );
        }
      }
    }
  }

  String get _meireMessage {
    if (_documentController.text.isEmpty) {
      return "Lembre-se de conferir o CNPJ do tomador.";
    } else if (_selectedServiceId == null) {
      return "Qual serviço você prestou hoje?";
    } else if (_valueController.text.isEmpty) {
      return "Não se esqueça de preencher o valor!";
    }
    return "Tudo pronto! Pode emitir.";
  }

  @override
  Widget build(BuildContext context) {
    final favoriteServices = ref.watch(favoriteServicesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Emitir NFS-e'),
        backgroundColor: Colors.white,
        foregroundColor: MeireTheme.primaryColor,
        elevation: 1,
      ),
      body:
          _isLoading ? _buildLoadingState() : _buildFormState(favoriteServices),
      floatingActionButton:
          _isLoading ? null : MeireAssistantWidget(message: _meireMessage),
    );
  }

  Widget _buildFormState(List<FavoriteService> favoriteServices) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSectionTitle('1. Dados do Tomador (Cliente)'),
                _buildCard(
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _documentController,
                        inputFormatters: [Validators.cnpjMask],
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: 'CPF ou CNPJ'),
                        validator: Validators.validateCpfCnpj,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                            labelText: 'Nome/Razão Social do Cliente'),
                        validator: (val) => Validators.validateRequired(
                            val, 'Nome/Razão Social'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('2. Informações da DPS (Serviço)'),
                _buildCard(
                  child: Column(
                    children: [
                      if (favoriteServices.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 16.0),
                          child: Text(
                            'Você ainda não possui Serviços Favoritos cadastrados. Vá até o Dashboard e cadastre um para simplificar a emissão.',
                            style: TextStyle(
                                color: Colors.orange,
                                fontStyle: FontStyle.italic),
                          ),
                        )
                      else
                        DropdownButtonFormField<String>(
                          initialValue: _selectedServiceId,
                          isExpanded: true,
                          decoration: const InputDecoration(
                              labelText: 'Serviço prestado *'),
                          items: favoriteServices.map((service) {
                            return DropdownMenuItem(
                              value: service.id,
                              child: Text(service.apelido,
                                  style: const TextStyle(fontSize: 14),
                                  overflow: TextOverflow.ellipsis),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedServiceId = val;
                              if (val != null) {
                                final selectedService = favoriteServices
                                    .firstWhere((s) => s.id == val);
                                _descriptionController.text =
                                    selectedService.descricaoBase;
                              }
                            });
                          },
                        ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 4,
                        maxLength: 2000,
                        decoration: const InputDecoration(
                          labelText: 'Descrição do serviço',
                          alignLabelWithHint: true,
                        ),
                        validator: (val) =>
                            Validators.validateRequired(val, 'Descrição'),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _valueController,
                        inputFormatters: [CurrencyInputFormatter()],
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Valor do serviço prestado *',
                          hintText: 'R\$ 0,00',
                        ),
                        validator: (val) =>
                            Validators.validateRequired(val, 'Valor'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _submitNfse,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 54),
                  ),
                  child: const Text('Emitir NFS-e',
                      style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Shimmer.fromColors(
            baseColor: MeireTheme.iceGray,
            highlightColor: Colors.white,
            child: const Icon(Icons.receipt_long,
                size: 80, color: MeireTheme.primaryColor),
          ),
          const SizedBox(height: 24),
          const Text(
            'Comunicando com a Receita Federal...',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: MeireTheme.primaryColor),
          ),
          const SizedBox(height: 8),
          const Text(
            'Assinando digitalmente e gerando a NFS-e Nacional.',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: MeireTheme.primaryColor,
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MeireTheme.iceGray),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
