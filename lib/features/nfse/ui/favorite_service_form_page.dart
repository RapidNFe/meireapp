import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meire/core/ui/theme.dart';
import 'package:meire/core/utils/validators.dart';
import 'package:meire/core/services/pocketbase_service.dart';
import 'package:meire/core/utils/currency_input_formatter.dart';
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

  final _idMunicipioController = TextEditingController();
  final _apelidoController = TextEditingController();
  final _codigoNationalController = TextEditingController();
  final _descricaoBaseController = TextEditingController();
  final _valorBaseController = TextEditingController();

   bool _isFavorito = false;
   List<String> _cnaesOptions = [];
   String? _cnaeSelecionado;

   final Map<String, String> deParaCnaeNacional = {
     "9602501": "06.01.01",
     "9602502": "06.01.01",
     "8219999": "17.02.01",
     "9609206": "06.01.01",
   };
 
   @override
   void initState() {
     super.initState();

     // Inteligência: Se o usuário é do setor de Beleza/Estética (Setado no cadastro via BrasilAPI), 
     // já inicia com a opção de ISS Retido ATIVADA.
     Future.microtask(() {
        final user = ref.read(userProvider);
        if (user != null) {
          if (mounted) {
             setState(() {
               _idMunicipioController.text = user.getStringValue('codigo_ibge');
             });
          }

          // Busca de CNAEs
          final principal = user.getStringValue('cnae_principal');
          final scds = user.getListValue<String>('cnaes_cadastrados');
          
          final Set<String> opts = {};
          if (principal.isNotEmpty) opts.add(principal);
          opts.addAll(scds);
          
          if (mounted) setState(() => _cnaesOptions = opts.toList());
        }
     });
   }
 
   void _onCnaeSelecionado(String? cnae) {
     if (cnae == null) return;
     setState(() {
       _cnaeSelecionado = cnae;
       
       String trimCode = cnae.split(' - ').first.replaceAll(RegExp(r'\D'), '');
       final parts = cnae.split(' - ');
       
       if (parts.length > 1) {
         if (_apelidoController.text.isEmpty) {
           _apelidoController.text = parts[1].toUpperCase();
         }
         if (_descricaoBaseController.text.isEmpty) {
           _descricaoBaseController.text = _gerarDescricaoPadrao(parts[1].trim());
         }
       }
       
       if (deParaCnaeNacional.containsKey(trimCode)) {
         _codigoNationalController.text = deParaCnaeNacional[trimCode]!;
       }
     });
   }

   String _gerarDescricaoPadrao(String nomeServico) {
     return '''Prestação de serviços de $nomeServico.
  
Documento emitido por MEI - Optante pelo SIMEI. 
Não gera direito a crédito fiscal de IPI. 
Valor aproximado dos tributos: R\$ 0,00 (0,00%) Fonte: IBPT.
Lei 12.741/2012.''';
   }
 


  @override
  void dispose() {
    _idMunicipioController.dispose();
    _apelidoController.dispose();
    _codigoNationalController.dispose();
    _descricaoBaseController.dispose();
    _valorBaseController.dispose();
    super.dispose();
  }

  void _saveFavorite() {
    if (_formKey.currentState?.validate() ?? false) {
      final user = ref.read(userProvider);
      if (user == null) return;

      final cleanValue = _valorBaseController.text
          .replaceAll('R\$', '')
          .replaceAll('.', '')
          .replaceAll(',', '.')
          .trim();
      final double? valorBase = double.tryParse(cleanValue);

      final newService = FavoriteService(
        idMunicipio: _idMunicipioController.text,
        apelido: _apelidoController.text.toUpperCase(),
        codigoNacional: _codigoNationalController.text,
        descricaoBase: _descricaoBaseController.text,
        valorBase: valorBase,
        issRetido: false, // MEI is exempt
        userId: user.id,
        favorito: _isFavorito,
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
                      controller: _idMunicipioController,
                      readOnly: true,
                      style: const TextStyle(color: Colors.grey),
                      decoration: InputDecoration(
                        labelText: 'Município (Código IBGE)',
                        helperText: 'Preenchido automaticamente pelo seu cadastro de conta.',
                        filled: true,
                        fillColor: Colors.amber.withValues(alpha: 0.1),
                      ),
                      validator: (val) =>
                          Validators.validateRequired(val, 'Município'),
                    ),
                    const SizedBox(height: 16),
                    if (_cnaesOptions.isNotEmpty) ...[
                      DropdownButtonFormField<String>(
                        initialValue: _cnaeSelecionado,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Selecione o Serviço (CNAE)',
                          prefixIcon: Icon(Icons.content_cut),
                        ),
                        items: _cnaesOptions.map((cnae) {
                          return DropdownMenuItem(
                            value: cnae,
                            child: Text(cnae, overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: _onCnaeSelecionado,
                        validator: (val) => Validators.validateRequired(val, 'Serviço CNAE'),
                      ),
                      const SizedBox(height: 16),
                    ],
                    TextFormField(
                      controller: _apelidoController,
                      decoration: const InputDecoration(
                        labelText: 'Apelido do Serviço *',
                        helperText: 'Ex: MANUTENÇÃO DE COMPUTADORES',
                      ),
                      validator: (val) =>
                          Validators.validateRequired(val, 'Apelido'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _codigoNationalController,
                      decoration: InputDecoration(
                        labelText: 'Código Nacional (NFS-e) *',
                        helperText: 'Ex: 06.01.01. Preenchido auto pelo seu CNAE.',
                        filled: _cnaeSelecionado != null,
                        fillColor: _cnaeSelecionado != null ? Colors.amber.withValues(alpha: 0.1) : null,
                      ),
                      validator: (val) =>
                          Validators.validateRequired(val, 'Código Nacional'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descricaoBaseController,
                      maxLines: 5,
                      maxLength: 2000,
                      decoration: const InputDecoration(
                          labelText: 'Descrição Padrão da Nota *',
                          alignLabelWithHint: true,
                          helperText:
                              'Este texto será importado automaticamente na hora da emissão'),
                      validator: (val) =>
                          Validators.validateRequired(val, 'Descrição Padrão'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _valorBaseController,
                      inputFormatters: [CurrencyInputFormatter()],
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Valor Base Sugerido (Opcional)',
                        hintText: 'R\$ 0,00',
                      ),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Exibir no Atalho Rápido?', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text('Aparecerá na tela inicial para emissão em 1 clique.'),
                      value: _isFavorito,
                      activeTrackColor: MeireTheme.primaryColor.withValues(alpha: 0.5),
                      activeThumbColor: MeireTheme.primaryColor,
                      onChanged: (bool value) {
                        setState(() {
                          _isFavorito = value;
                        });
                      },
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
