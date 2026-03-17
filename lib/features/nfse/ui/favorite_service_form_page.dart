import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meiri/core/ui/theme.dart';
import 'package:meiri/core/utils/validators.dart';
import 'package:meiri/core/ui/widgets/service_selector.dart';
import 'package:meiri/core/ui/widgets/nbs_selector.dart';
import 'package:meiri/core/utils/currency_input_formatter.dart';
import 'package:meiri/features/nfse/data/catalogo_beleza.dart';
import 'package:meiri/features/nfse/provider/favorite_services_provider.dart';

class FavoriteServiceFormPage extends ConsumerStatefulWidget {
  const FavoriteServiceFormPage({super.key});

  @override
  ConsumerState<FavoriteServiceFormPage> createState() =>
      _FavoriteServiceFormPageState();
}

class _FavoriteServiceFormPageState
    extends ConsumerState<FavoriteServiceFormPage> {
  final _formKey = GlobalKey<FormState>();

  final _municipioController = TextEditingController();
  final _apelidoController = TextEditingController();
  final _codigoTributacaoController = TextEditingController();
  final _itemNbsController = TextEditingController();
  final _descricaoBaseController = TextEditingController();
  final _valorBaseController = TextEditingController();
  bool _isNichoBeleza = true; // Inicia true para o foco atual

  @override
  void dispose() {
    _municipioController.dispose();
    _apelidoController.dispose();
    _codigoTributacaoController.dispose();
    _itemNbsController.dispose();
    _descricaoBaseController.dispose();
    _valorBaseController.dispose();
    super.dispose();
  }

  void _saveFavorite() {
    if (_formKey.currentState?.validate() ?? false) {
      final cleanValue = _valorBaseController.text
          .replaceAll('R\$', '')
          .replaceAll('.', '')
          .replaceAll(',', '.')
          .trim();
      final double? valorBase = double.tryParse(cleanValue);

      final newService = FavoriteService(
        municipio: _municipioController.text,
        apelido: _apelidoController.text.toUpperCase(),
        codigoTributacao: _codigoTributacaoController.text,
        itemNbs: _itemNbsController.text,
        descricaoBase: _descricaoBaseController.text,
        valorBase: valorBase,
        isNichoBeleza: _isNichoBeleza,
      );

      ref.read(favoriteServicesProvider.notifier).addService(newService);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Serviço Favorito salvo com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cadastrar Serviço Favorito'),
        backgroundColor: Colors.white,
        foregroundColor: MeiriTheme.primaryColor,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Form(
              key: _formKey,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: MeiriTheme.iceGray),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _municipioController,
                      decoration:
                          const InputDecoration(labelText: 'Município *'),
                      validator: (val) =>
                          Validators.validateRequired(val, 'Município'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _apelidoController,
                      decoration: const InputDecoration(
                        labelText: 'Apelido *',
                        helperText: 'Ex: PRESTAÇÃO DE SERVIÇO',
                        helperMaxLines: 2,
                      ),
                      validator: (val) =>
                          Validators.validateRequired(val, 'Apelido'),
                    ),
                    const SizedBox(height: 16),
                    _buildNichoBelezaSection(),
                    if (!_isNichoBeleza) ...[
                      const SizedBox(height: 24),
                      const Text('Configuração Tributária Avançada',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey)),
                      const SizedBox(height: 12),
                      const Text(
                          'Selecione a Classificação Tributária (CNAE) *',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: MeiriTheme.primaryColor)),
                      const SizedBox(height: 8),
                      ServiceSelector(
                        onServiceSelected: (selection) {
                          setState(() {
                            _codigoTributacaoController.text =
                                "${selection['tributacao_codigo']} - ${selection['tributacao_descricao']}";
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      const Text('Selecione a Classificação NBS (IBGE) *',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: MeiriTheme.primaryColor)),
                      const SizedBox(height: 8),
                      NbsSelector(onNbsSelected: (nbsSelection) {
                        setState(() {
                          _itemNbsController.text =
                              "${nbsSelection.id} - ${nbsSelection.nome}";
                        });
                      }),
                    ],
                    // Campos ocultos mas obrigatórios para submissão validada
                    Offstage(
                      offstage: true,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _codigoTributacaoController,
                            validator: (val) => Validators.validateRequired(
                                val, 'Código de Tributação'),
                          ),
                          TextFormField(
                            controller: _itemNbsController,
                            validator: (val) =>
                                Validators.validateRequired(val, 'Item NBS'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descricaoBaseController,
                      maxLines: 4,
                      maxLength: 2000,
                      decoration: const InputDecoration(
                          labelText: 'Descrição do Serviço base *',
                          alignLabelWithHint: true,
                          helperText:
                              'Este texto será importado automaticamente na hora da emissão'),
                      validator: (val) =>
                          Validators.validateRequired(val, 'Descrição Base'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _valorBaseController,
                      inputFormatters: [CurrencyInputFormatter()],
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Valor Base (Opcional)',
                        hintText: 'R\$ 0,00',
                      ),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _saveFavorite,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 54),
                      ),
                      child: const Text('Salvar Serviço Favorito',
                          style: TextStyle(fontSize: 16)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNichoBelezaSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Nicho de Beleza / Salão Parceiro',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: MeiriTheme.primaryColor)),
                Text('Habilita automação de quinzena', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            Switch(
              value: _isNichoBeleza,
              activeThumbColor: MeiriTheme.accentColor,
              onChanged: (val) => setState(() => _isNichoBeleza = val),
            ),
          ],
        ),
        if (_isNichoBeleza) ...[
          const SizedBox(height: 16),
          Autocomplete<Map<String, dynamic>>(
            displayStringForOption: (Map<String, dynamic> option) => option['titulo_amigavel'],
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text.isEmpty) {
                return const Iterable<Map<String, dynamic>>.empty();
              }
              String busca = textEditingValue.text.toLowerCase();
              return catalogoBeleza.where((servico) {
                bool bateuTitulo = servico['titulo_amigavel'].toString().toLowerCase().contains(busca);
                List<String> tags = List<String>.from(servico['palavras_chave']);
                bool bateuTag = tags.any((tag) => tag.contains(busca));
                return bateuTitulo || bateuTag;
              });
            },
            onSelected: (Map<String, dynamic> selection) {
              setState(() {
                _codigoTributacaoController.text = "${selection['codigo_nacional']} - ${selection['titulo_amigavel']}";
                // Fixamos NBS para beleza se for o nicho
                _itemNbsController.text = "126021000 - Serviços de cabeleireiros e barbeiros";
                
                if (_descricaoBaseController.text.isEmpty) {
                  _descricaoBaseController.text = "Nota fiscal referente a serviços de estética e beleza (Salão Parceiro) prestados no período de {QUINZENA_PASSADA}.";
                }
              });
            },
            fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
              return TextFormField(
                controller: controller,
                focusNode: focusNode,
                onEditingComplete: onEditingComplete,
                decoration: InputDecoration(
                  labelText: 'O que você faz? (Ex: unha, cabelo, cílios)',
                  prefixIcon: const Icon(Icons.search, color: MeiriTheme.accentColor),
                  filled: true,
                  fillColor: MeiriTheme.accentColor.withValues(alpha: 0.05),
                ),
              );
            },
          ),
        ],
      ],
    );
  }
}
