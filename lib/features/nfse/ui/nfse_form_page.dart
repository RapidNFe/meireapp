import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meire/core/ui/theme.dart';
import 'package:meire/core/utils/currency_input_formatter.dart';
import 'package:meire/core/utils/validators.dart';
import 'package:meire/features/nfse/services/notas_fiscais_service.dart';
import 'package:meire/features/hub/provider/notas_fiscais_provider.dart';
import 'package:meire/features/nfse/provider/favorite_services_provider.dart';
import 'package:meire/features/shared/ui/widgets/meire_assistant_widget.dart';
import 'package:meire/features/clients/provider/client_provider.dart';
import 'package:meire/features/clients/models/client_model.dart';
import 'package:shimmer/shimmer.dart';

// ZELADORIA: Ativando suporte a competência retroativa no formulário
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
  DateTime _mesCompetencia = DateTime.now();
  bool _isLoading = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _documentController.addListener(_onDocumentChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final client = ModalRoute.of(context)?.settings.arguments as ClientModel?;
      if (client != null) {
        _documentController.text = client.cnpj;
        _nameController.text = client.razaoSocial;
      }
      _initialized = true;
    }
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
    // Se quiser voltar o auto-fill mock aqui, ok.
  }

  void _showClientSelector(List<ClientModel> clients) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Selecionar Cliente',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: MeireTheme.primaryColor),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: clients.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.people_outline, size: 64, color: Colors.grey.shade300),
                              const SizedBox(height: 16),
                              Text('Nenhum cliente cadastrado.', style: TextStyle(color: Colors.grey.shade600)),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pop(context);
                                  Navigator.pushNamed(context, '/add_client');
                                },
                                icon: const Icon(Icons.add),
                                label: const Text('Cadastrar Novo Cliente'),
                              )
                            ],
                          ),
                        )
                      : ListView.separated(
                          controller: scrollController,
                          itemCount: clients.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final client = clients[index];
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                              leading: CircleAvatar(
                                backgroundColor: MeireTheme.accentColor.withValues(alpha: 1.0),
                                child: Text(client.apelido.substring(0, 1).toUpperCase(), style: const TextStyle(color: MeireTheme.accentColor, fontWeight: FontWeight.bold)),
                              ),
                              title: Text(client.apelido, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('${client.razaoSocial}\nCNPJ: ${client.cnpj}'),
                              isThreeLine: true,
                              onTap: () {
                                setState(() {
                                  _documentController.text = client.cnpj;
                                  _nameController.text = client.razaoSocial;
                                });
                                Navigator.pop(context);
                              },
                            );
                          },
                        ),
                ),
                if (clients.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/add_client');
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Cadastrar Novo Cliente'),
                    ),
                  )
              ],
            );
          },
        );
      },
    );
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

      // 🚀 Chamada síncrona real agora disponível via VORTEX
      // await Future.delayed(const Duration(seconds: 3));

      // Parse amount
      final cleanValue = _valueController.text
          .replaceAll('R\$', '')
          .replaceAll('.', '')
          .replaceAll(',', '.')
          .trim();
      final double amount = double.tryParse(cleanValue) ?? 0.0;

      // Add to PocketBase via Service
      try {
        final responseData = await ref.read(notasFiscaisServiceProvider).addNotaFiscal(
              clientName: _nameController.text,
              clientCnpj: _documentController.text,
              amount: amount,
              description: _descriptionController.text,
              competencia: _mesCompetencia.toIso8601String().split('T')[0],
            );

        // Refresh dashboard data
        ref.invalidate(revenueStatsProvider);
        ref.invalidate(impostoEstimativaProvider);
        ref.invalidate(historicoFaturamentoProvider);

        if (mounted) {
          HapticFeedback.lightImpact();
          await Future.delayed(const Duration(milliseconds: 50));
          HapticFeedback.mediumImpact();

          if (!mounted) return;
          Navigator.pushReplacementNamed(
            context, 
            '/nfse_success', 
            arguments: {
              ...?responseData as Map<String, dynamic>?,
              'competencia': DateFormat("MMMM 'de' yyyy", "pt_BR").format(_mesCompetencia).toUpperCase(),
            },
          );
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
    final clientsAsync = ref.watch(clientListProvider);

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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSectionTitle('1. Dados do Tomador (Cliente)'),
                    TextButton.icon(
                      onPressed: () {
                        clientsAsync.whenData((clients) {
                           _showClientSelector(clients);
                        });
                      },
                      icon: const Icon(Icons.search, size: 18),
                      label: const Text('Buscar Salvo'),
                      style: TextButton.styleFrom(
                        foregroundColor: MeireTheme.accentColor,
                        padding: EdgeInsets.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
                _buildCard(
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _documentController,
                        inputFormatters: [Validators.cnpjMask],
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'CPF ou CNPJ (apenas números)'),
                        validator: Validators.validateCpfCnpj,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: 'Nome/Razão Social do Cliente'),
                        validator: (val) => Validators.validateRequired(val, 'Nome/Razão Social'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('2. Mês de Referência (Competência)'),
                _buildSeletorCompetencia(),
                const SizedBox(height: 24),
                _buildSectionTitle('3. Informações da DPS (Serviço)'),
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

  Widget _buildSeletorCompetencia() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MeireTheme.accentColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MeireTheme.accentColor.withValues(alpha: 0.2)),
      ),
      child: InkWell(
        onTap: () async {
          final DateTime? picked = await showDatePicker(
            context: context,
            initialDate: _mesCompetencia,
            firstDate: DateTime(2024),
            lastDate: DateTime.now(),
            locale: const Locale("pt", "BR"),
            initialDatePickerMode: DatePickerMode.year,
            helpText: "SELECIONE O MÊS DO SERVIÇO",
          );

          if (picked != null) {
            setState(() {
              _mesCompetencia = DateTime(picked.year, picked.month, 1);
            });
          }
        },
        child: Row(
          children: [
            const Icon(Icons.calendar_month, color: MeireTheme.accentColor),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Mês que o serviço foi realizado",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  DateFormat("MMMM 'de' yyyy", "pt_BR").format(_mesCompetencia).toUpperCase(),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Spacer(),
            const Text(
              "Alterar",
              style: TextStyle(color: MeireTheme.accentColor, fontWeight: FontWeight.bold),
            ),
          ],
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
