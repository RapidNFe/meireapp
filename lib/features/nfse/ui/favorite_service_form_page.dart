import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meire/core/ui/theme.dart';
import 'package:meire/core/utils/validators.dart';
import 'package:meire/core/ui/widgets/service_selector.dart';
import 'package:meire/core/ui/widgets/nbs_selector.dart';
import 'package:meire/features/nfse/provider/favorite_services_provider.dart';

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

  @override
  void dispose() {
    _municipioController.dispose();
    _apelidoController.dispose();
    _codigoTributacaoController.dispose();
    _itemNbsController.dispose();
    _descricaoBaseController.dispose();
    super.dispose();
  }

  void _saveFavorite() {
    if (_formKey.currentState?.validate() ?? false) {
      final newService = FavoriteService(
        municipio: _municipioController.text,
        apelido: _apelidoController.text.toUpperCase(),
        codigoTributacao: _codigoTributacaoController.text,
        itemNbs: _itemNbsController.text,
        descricaoBase: _descricaoBaseController.text,
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
        foregroundColor: MeireTheme.primaryColor,
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
                  border: Border.all(color: MeireTheme.iceGray),
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
                    const Text('Selecione a Classificação Tributária (CNAE) *',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: MeireTheme.primaryColor)),
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
                            color: MeireTheme.primaryColor)),
                    const SizedBox(height: 8),
                    NbsSelector(onNbsSelected: (nbsSelection) {
                      setState(() {
                        _itemNbsController.text =
                            "${nbsSelection.id} - ${nbsSelection.nome}";
                      });
                    }),
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
}
