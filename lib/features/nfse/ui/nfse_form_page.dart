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
import 'package:meire/features/clients/provider/client_provider.dart';
import 'package:meire/features/clients/models/tomador_model.dart';
import 'package:meire/core/ui/widgets/tomador_selector_lux.dart';
import 'package:shimmer/shimmer.dart';
import 'package:meire/core/services/pocketbase_service.dart';

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
  DateTime? _mesCompetencia;
  TomadorModel? _selectedClient;
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
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is TomadorModel) {
        _selectedClient = args;
        _documentController.text = args.cnpj;
        _nameController.text = args.razaoSocial;
      } else if (args is Map<String, dynamic>) {
        if (args['serviceId'] != null) {
          _selectedServiceId = args['serviceId'];
          Future.microtask(() {
            final favoriteServices = ref.read(favoriteServicesProvider);
            try {
              final selectedService = favoriteServices.firstWhere((s) => s.id == _selectedServiceId);
              if (mounted) {
                setState(() {
                  _descriptionController.text = _processarDescricaoInteligente(selectedService.descricaoBase);
                  if (selectedService.valorBase != null) {
                    _valueController.text = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$ ').format(selectedService.valorBase);
                  }
                });
              }
              if (selectedService.idClientePadrao != null) {
                ref.read(clientListProvider).whenData((clients) {
                  try {
                    final cliente = clients.firstWhere((c) => c.id == selectedService.idClientePadrao);
                    if (mounted) {
                      setState(() {
                        _selectedClient = cliente;
                        _documentController.text = cliente.cnpj;
                        _nameController.text = cliente.razaoSocial;
                      });
                    }
                  } catch (_) {}
                });
              }
            } catch (_) {}
          });
        }
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

  Future<void> _excluirServico(String recordId) async {
    bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Excluir Serviço?", style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text("Tem certeza que deseja remover este modelo de serviço?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancelar")),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text("Excluir", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
          ),
        ],
      ),
    );

    if (confirmar == true) {
      if (!mounted) return;
      setState(() => _isLoading = true);
      try {
        await ref.read(favoriteServicesProvider.notifier).removeService(recordId);
        if (mounted) {
          setState(() {
            _selectedServiceId = null;
            _descriptionController.clear();
            _valueController.clear();
            _documentController.clear();
            _nameController.clear();
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Serviço removido com sucesso!", style: TextStyle(color: Colors.white)), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Erro ao excluir: $e")),
          );
        }
      }
    }
  }



  void _submitNfse() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (_mesCompetencia == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Por favor, selecione a Data da Competência.')),
        );
        return;
      }

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
        final favoriteServices = ref.read(favoriteServicesProvider);
        final selectedService = favoriteServices.firstWhere((s) => s.id == _selectedServiceId);
        
        final responseData = await ref.read(notasFiscaisServiceProvider).addNotaFiscal(
              clientName: _nameController.text,
              clientCnpj: _documentController.text,
              amount: amount,
              description: _descriptionController.text,
              competencia: _mesCompetencia!.toIso8601String().split('T')[0],
              clientModel: _selectedClient,
              codigoTributacao: selectedService.codigoNacional, // Mapeado!
              itemNbs: selectedService.itemNbs, 
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
              'competencia': DateFormat("dd 'de' MMMM 'de' yyyy", "pt_BR").format(_mesCompetencia!).toUpperCase(),
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

  @override
  Widget build(BuildContext context) {
    final favoriteServices = ref.watch(favoriteServicesProvider);

    final user = ref.watch(userProvider);
    final possuiCertificado = user?.getBoolValue('possui_certificado') ?? false;

    if (!possuiCertificado) {
       return _buildBlockedState();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Emitir NFS-e'),
        backgroundColor: Colors.white,
        foregroundColor: MeireTheme.primaryColor,
        elevation: 1,
      ),
      body:
          _isLoading ? _buildLoadingState() : _buildFormState(favoriteServices),
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
                _buildSectionTitle('1. Dados do Tomador (Cliente)'),
                _buildCard(
                  child: TomadorSelectorLux(
                    onSelected: (client) {
                      setState(() {
                        _selectedClient = client;
                        _documentController.text = client.cnpj;
                        _nameController.text = client.razaoSocial;
                      });
                    },
                    onNovoCliente: () => Navigator.pushNamed(context, '/add_client'),
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
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
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
                                    
                                    // 1. Preenchimento Automático da Descrição com Inteligência de Quinzena
                                    _descriptionController.text = _processarDescricaoInteligente(
                                        selectedService.descricaoBase);

                                    // 2. Preenchimento Automático do Valor (se houver)
                                    if (selectedService.valorBase != null) {
                                      _valueController.text = NumberFormat.currency(
                                              locale: 'pt_BR', symbol: 'R\$ ')
                                          .format(selectedService.valorBase);
                                    } else {
                                      _valueController.clear();
                                    }

                                    // 3. Auto-seleção do Cliente (se houver ID padrão e estiver na lista)
                                    if (selectedService.idClientePadrao != null && selectedService.idClientePadrao!.isNotEmpty) {
                                      clientsAsync.whenData((clients) {
                                        try {
                                          final cliente = clients.firstWhere(
                                              (c) => c.id == selectedService.idClientePadrao);
                                          if (mounted) {
                                            setState(() {
                                              _selectedClient = cliente;
                                              _documentController.text = cliente.cnpj;
                                              _nameController.text = cliente.razaoSocial;
                                            });
                                          }
                                        } catch (_) {}
                                      });
                                    }
                                  }
                                });
                              },
                            ),
                          ),
                          if (_selectedServiceId != null) ...[
                            const SizedBox(width: 8),
                            Padding(
                              padding: const EdgeInsets.only(top: 6.0),
                              child: IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                tooltip: "Excluir Serviço Favorito",
                                onPressed: () => _excluirServico(_selectedServiceId!),
                              ),
                            ),
                          ],
                        ]
                      ),
                      const SizedBox(height: 16),
                      

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
            initialDate: _mesCompetencia ?? DateTime.now(),
            firstDate: DateTime(2024),
            lastDate: DateTime.now(),
            locale: const Locale("pt", "BR"),
            initialDatePickerMode: DatePickerMode.day,
            helpText: "SELECIONE A DATA DA COMPETÊNCIA",
          );

          if (picked != null) {
            setState(() {
              _mesCompetencia = picked;
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
                  _mesCompetencia != null 
                    ? DateFormat("dd/MM/yyyy").format(_mesCompetencia!)
                    : "⚠️ Selecionar Data",
                  style: TextStyle(
                    fontSize: 16, 
                    fontWeight: FontWeight.bold,
                    color: _mesCompetencia == null ? Colors.redAccent : MeireTheme.primaryColor,
                  ),
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

  // === MOTOR DE INTELIGÊNCIA FISCAL (NICHO BELEZA) ===

  String _calcularQuinzenaPassada() {
    DateTime hoje = DateTime.now();

    if (hoje.day <= 15) {
      // 2ª Quinzena do mês passado
      DateTime mesPassado = DateTime(hoje.year, hoje.month - 1, 1);
      int ultimoDia = DateTime(hoje.year, hoje.month, 0).day;
      String mesStr = mesPassado.month.toString().padLeft(2, '0');
      return "16/$mesStr a $ultimoDia/$mesStr";
    } else {
      // 1ª Quinzena deste mês
      String mesStr = hoje.month.toString().padLeft(2, '0');
      return "01/$mesStr a 15/$mesStr";
    }
  }

  String _processarDescricaoInteligente(String template) {
    String texto = template;
    if (texto.contains('{QUINZENA_PASSADA}')) {
      texto = texto.replaceAll('{QUINZENA_PASSADA}', _calcularQuinzenaPassada());
    }
    return texto;
  }
  Widget _buildBlockedState() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emitir NFS-e'),
        backgroundColor: Colors.white,
        foregroundColor: MeireTheme.primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_person_outlined, size: 80, color: MeireTheme.accentColor),
              const SizedBox(height: 24),
              const Text(
                'Emissão bloqueada',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: MeireTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Para emitir notas fiscais pelo Sistema Nacional, você precisa de um Certificado Digital A1 ativo no seu perfil.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(200, 50),
                ),
                child: const Text('Voltar ao Dashboard'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
