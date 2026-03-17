import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meiri/core/ui/theme.dart';
import 'package:meiri/features/auth/services/auth_service.dart';
import 'package:meiri/core/services/brasil_api_service.dart';
import 'package:meiri/core/utils/validators.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class RegisterStepperPage extends ConsumerStatefulWidget {
  const RegisterStepperPage({super.key});

  @override
  ConsumerState<RegisterStepperPage> createState() => _RegisterStepperPageState();
}

class _RegisterStepperPageState extends ConsumerState<RegisterStepperPage> {
  final _formKeyStep1 = GlobalKey<FormState>();
  final _formKeyStep2 = GlobalKey<FormState>();
  
  bool _isLoading = false;
  bool _aceitouTermos = false;
  int _currentStep = 0; // 0 = CNPJ, 1 = Pessoal

  // Masks
  final _cnpjMask = MaskTextInputFormatter(
      mask: '##.###.###/####-##', filter: {"#": RegExp(r'[0-9]')});
  final _cpfMask = MaskTextInputFormatter(
      mask: '###.###.###-##', filter: {"#": RegExp(r'[0-9]')});

  // State Step 1
  String _cnpj = '';
  String _razaoSocial = '';
  
  // State Step 2
  String _nomeCompleto = '';
  String _email = '';
  String _password = '';

  Future<void> _fetchCnpjData(String cnpj) async {
    setState(() => _isLoading = true);
    try {
      final data = await BrasilApiService.buscarCnpj(cnpj);

      setState(() {
        _razaoSocial = data['razao_social'] ?? 'Não informada';
        _isLoading = false;
        _currentStep = 1; // Advance to next step
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        _mostrarOpcaoManual();
      }
    }
  }

  void _mostrarOpcaoManual() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('⚠️ Não conseguimos validar o CNPJ automaticamente.'),
        duration: const Duration(seconds: 8),
        action: SnackBarAction(
          label: 'Preencher Manual',
          textColor: Colors.amber,
          onPressed: () {
            setState(() {
              _razaoSocial = 'Preenchimento Manual';
              _currentStep = 1;
            });
          },
        ),
      ),
    );
  }

  Future<void> _performRegistration() async {
    if (!(_formKeyStep2.currentState?.validate() ?? false)) return;
    _formKeyStep2.currentState?.save();

    setState(() => _isLoading = true);

    try {
      final cleanCpf = _cpfMask.getUnmaskedText();
      final cleanCnpj = _cnpjMask.getUnmaskedText();

      await ref.read(authServiceProvider).signUp(
            email: _email,
            password: _password,
            nomeCompleto: _nomeCompleto,
            razaoSocial: _razaoSocial,
            cpf: cleanCpf,
            cnpj: cleanCnpj,
          );

      if (mounted) {
        // Go directly to Success Page
        Navigator.pushReplacementNamed(context, '/success');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception:', '').trim()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          _currentStep == 0 ? 'Conectar Empresa' : 'Seus Dados',
          style: const TextStyle(color: MeiriTheme.primaryColor, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: MeiriTheme.primaryColor),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Progress Indicator elegant
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: MeiriTheme.primaryColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: _currentStep == 1 ? MeiriTheme.primaryColor : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              
              if (_currentStep == 0) _buildStep1() else _buildStep2(),
              
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return Form(
      key: _formKeyStep1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SvgPicture.asset(
            'assets/images/logo.svg',
            height: 64,
          ),

          const SizedBox(height: 24),
          const Text(
            'Qual o CNPJ da sua MEI?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: MeiriTheme.primaryColor,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Vamos buscar as informações públicas da sua empresa para agilizar o cadastro.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 48),
          TextFormField(
            inputFormatters: [_cnpjMask],
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: '00.000.000/0000-00',
              filled: true,
              fillColor: MeiriTheme.iceGray,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 24),
            ),
            validator: Validators.validateCnpj,
            onChanged: (val) => _cnpj = val,
            onFieldSubmitted: (_) {
              if (_formKeyStep1.currentState?.validate() ?? false) {
                _fetchCnpjData(_cnpj);
              }
            },
          ),
          const SizedBox(height: 48),
          ElevatedButton(
            onPressed: _isLoading
                ? null
                : () {
                    if (_formKeyStep1.currentState?.validate() ?? false) {
                      _fetchCnpjData(_cnpj);
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: MeiriTheme.primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Text(
                    'Avançar',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return Form(
      key: _formKeyStep2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: MeiriTheme.accentColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: MeiriTheme.accentColor.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                const Icon(Icons.verified, color: MeiriTheme.accentColor, size: 32),
                const SizedBox(height: 12),
                if (_razaoSocial != 'Preenchimento Manual')
                  Text(
                    _razaoSocial,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: MeiriTheme.primaryColor,
                    ),
                  )
                else
                  TextFormField(
                    initialValue: '',
                    decoration: const InputDecoration(
                      labelText: 'Razão Social da sua MEI',
                      hintText: 'Digite o nome exatamente como na Receita',
                    ),
                    onChanged: (val) => _razaoSocial = val,
                    validator: (val) => (val == null || val.isEmpty) ? 'Campo obrigatório' : null,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 48),
          const Text(
            'Credenciais de Acesso',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: MeiriTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          _buildTextField(
            label: 'Seu Nome Completo',
            icon: Icons.person_outline,
            textCapitalization: TextCapitalization.words,
            validator: (val) {
              if (val == null || val.trim().split(' ').length < 2) return 'Digite seu nome completo';
              return null;
            },
            onSaved: (val) => _nomeCompleto = val?.trim() ?? '',
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'E-mail Comercial',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: Validators.validateEmail,
            onSaved: (val) => _email = val?.trim() ?? '',
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'CPF do Titular',
            icon: Icons.badge_outlined,
            keyboardType: TextInputType.number,
            inputFormatters: [_cpfMask],
            validator: Validators.validateCpf,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Crie sua Senha',
            icon: Icons.lock_outline,
            obscureText: true,
            validator: (val) {
              if (val == null || val.length < 8) return 'Mínimo de 8 caracteres';
              return null;
            },
            onSaved: (val) => _password = val ?? '',
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 24,
                width: 24,
                child: Checkbox(
                  value: _aceitouTermos,
                  activeColor: MeiriTheme.accentColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  onChanged: (bool? value) {
                    setState(() {
                      _aceitouTermos = value ?? false;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, '/privacy_policy');
                  },
                  child: RichText(
                    text: const TextSpan(
                      style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.4),
                      children: [
                        TextSpan(text: 'Declaro que li e concordo com os '),
                        TextSpan(
                          text: 'Termos de Uso e Política de Privacidade.',
                          style: TextStyle(
                            color: MeiriTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 48),
          ElevatedButton(
            onPressed: (_isLoading || !_aceitouTermos) ? null : _performRegistration,
            style: ElevatedButton.styleFrom(
              backgroundColor: MeiriTheme.primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Text(
                    'Finalizar e Entrar',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              setState(() => _currentStep = 0);
            },
            child: const Text('Voltar e editar CNPJ', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    void Function(String?)? onSaved,
  }) {
    return TextFormField(
      obscureText: obscureText,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      inputFormatters: inputFormatters,
      validator: validator,
      onSaved: onSaved,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey),
        filled: true,
        fillColor: MeiriTheme.iceGray,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
