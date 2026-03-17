import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meiri/core/services/brasil_api_service.dart';
import 'package:meiri/core/services/pocketbase_service.dart';
import 'package:meiri/core/ui/theme.dart';
import 'package:meiri/core/utils/validators.dart';
import 'package:meiri/features/clients/provider/client_provider.dart';

class AddClientPage extends ConsumerStatefulWidget {
  const AddClientPage({super.key});

  @override
  ConsumerState<AddClientPage> createState() => _AddClientPageState();
}

class _AddClientPageState extends ConsumerState<AddClientPage> {
  final _formKey = GlobalKey<FormState>();

  final _documentController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _nameController = TextEditingController(); // Razao Social
  final _emailController = TextEditingController();

  final _nicknameFocus = FocusNode();

  bool _isLoadingDocument = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _documentController.addListener(_onDocumentChanged);
  }

  @override
  void dispose() {
    _documentController.removeListener(_onDocumentChanged);
    _documentController.dispose();
    _nicknameController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _nicknameFocus.dispose();
    super.dispose();
  }

  void _onDocumentChanged() async {
    String text = _documentController.text;
    String cleanText = text.replaceAll(RegExp(r'[^0-9]'), '');

    if (cleanText.length == 14 && _nameController.text.isEmpty && !_isLoadingDocument) {
      setState(() {
        _isLoadingDocument = true;
      });

      try {
        final data = await BrasilApiService.buscarCnpj(cleanText);
        setState(() {
          _nameController.text = data['razao_social'];
        });
        _nicknameFocus.requestFocus(); // Auto-focus no Apelido
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoadingDocument = false;
          });
        }
      }
    } else if (cleanText.length < 14 && _nameController.text.isNotEmpty) {
       setState(() {
         // Limpa caso o usuario apague o CNPJ
         _nameController.clear();
       });
    }
  }

  void _saveClient() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isSaving = true);
      
      try {
        final pb = ref.read(pbProvider);
        final userId = pb.authStore.record?.id;
        if (userId == null) throw Exception('Sessão expirada. Faça login novamente.');

        // Clean document before saving
        final cleanCnpj = _documentController.text.replaceAll(RegExp(r'[^0-9]'), '');

        await pb.collection('clientes_tomadores').create(body: {
          'user': userId,
          'cnpj': cleanCnpj,
          'razao_social': _nameController.text,
          'apelido': _nicknameController.text,
          'email': _emailController.text,
        });

        // Refresh riverpod list
        ref.invalidate(clientListProvider);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cliente cadastrado com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao cadastrar: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isSaving = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cadastrar Tomador'),
        backgroundColor: Colors.white,
        foregroundColor: MeiriTheme.primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Digite o CNPJ para preenchimento automático usando a Brasil API.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _documentController,
                inputFormatters: [Validators.cnpjMask],
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'CNPJ *',
                  suffixIcon: _isLoadingDocument
                      ? const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : null,
                ),
                validator: Validators.validateCpfCnpj,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Razão Social',
                  filled: true,
                  fillColor: Colors.grey.withValues(alpha: 0.1),
                ),
                validator: (val) => Validators.validateRequired(val, 'Razão Social'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nicknameFocus.hasFocus ? _nicknameController : _nicknameController,
                focusNode: _nicknameFocus,
                decoration: const InputDecoration(
                  labelText: 'Apelido do Cliente *',
                  hintText: 'Ex: Agência XYZ, Consultório, etc.',
                ),
                validator: (val) => Validators.validateRequired(val, 'Apelido'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'E-mail (opcional)',
                  hintText: 'email@cliente.com.br',
                ),
                validator: (val) {
                  if (val != null && val.isNotEmpty) {
                    return Validators.validateEmail(val);
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isSaving ? null : _saveClient,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 54),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 24, width: 24,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Salvar Cliente', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
