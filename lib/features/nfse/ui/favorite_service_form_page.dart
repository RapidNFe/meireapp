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
   bool _issRetido = false;
 
   @override
   void initState() {
     super.initState();
     _codigoNationalController.addListener(_checkEsteticaLogic);

     // Inteligência: Se o usuário é do setor de Beleza/Estética (Setado no cadastro via BrasilAPI), 
     // já inicia com a opção de ISS Retido ATIVADA.
     Future.microtask(() {
        final user = ref.read(userProvider);
        if (user?.getBoolValue('is_beleza') == true) {
          if (mounted) setState(() => _issRetido = true);
        }
     });
   }
 
   void _checkEsteticaLogic() {
     final code = _codigoNationalController.text.replaceAll('.', '').trim();
     // Lógica de Salão Parceiro / Estética (LC 116: 06.01 e 06.02)
     if (code.startsWith('0601') || code.startsWith('0602')) {
       if (!_issRetido) {
         setState(() {
           _issRetido = true;
         });
       }
     }
   }

  @override
  void dispose() {
    _idMunicipioController.dispose();
    _apelidoController.dispose();
    _codigoNationalController.dispose();
    _descricaoBaseController.dispose();
    _valorBaseController.dispose();
    _codigoNationalController.removeListener(_checkEsteticaLogic);
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
        issRetido: _issRetido,
        userId: user.id,
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
                      decoration:
                          const InputDecoration(labelText: 'Município (Nome ou Código IBGE) *'),
                      validator: (val) =>
                          Validators.validateRequired(val, 'Município'),
                    ),
                    const SizedBox(height: 16),
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
                      decoration: const InputDecoration(
                        labelText: 'Código Nacional (NFS-e) *',
                        helperText: 'Ex: 06.01.01',
                      ),
                      validator: (val) =>
                          Validators.validateRequired(val, 'Código Nacional'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descricaoBaseController,
                      maxLines: 4,
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
                    const SizedBox(height: 24),
                    SwitchListTile(
                      title: const Text('ISS Retido pelo Tomador?', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text('Marque apenas se o imposto for pago pelo cliente'),
                      value: _issRetido,
                      activeThumbColor: MeireTheme.accentColor,
                      onChanged: (val) => setState(() => _issRetido = val),
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
