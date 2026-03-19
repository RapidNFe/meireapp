import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meire/core/services/brasil_api_service.dart';
import 'package:meire/features/auth/services/auth_service.dart';
import 'package:meire/core/utils/validators.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

// Paleta Esmeralda
const Color esmeraldaFundo = Color(0xFF022C22);
const Color verdeSecundario = Color(0xFF064E3B);
const Color verdeCard = Color(0xFF065F46);
const Color amareloDestaque = Color(0xFFFFB800);

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

  String _cnpj = '';
  String _razaoSocial = '';
  bool _isBeleza = false;
  String _cnae = '';
  
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
        _cnae = data['cnae_fiscal']?.toString().replaceAll(RegExp(r'\D'), '') ?? '';
        
        // Elite Filter: 9602-5/01 ou 9602-5/02
        _isBeleza = _cnae == '9602501' || _cnae == '9602502';
        
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
        backgroundColor: verdeSecundario,
        action: SnackBarAction(
          label: 'Preencher Manual',
          textColor: amareloDestaque,
          onPressed: () {
            setState(() {
              _razaoSocial = '';
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
      final cleanCnpj = _cnpjMask.getUnmaskedText();

      await ref.read(authServiceProvider).signUp(
            email: _email,
            password: _password,
            nomeCompleto: _nomeCompleto,
            razaoSocial: _razaoSocial,
            cnpj: cleanCnpj,
          );

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/success');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception:', '').trim()),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: esmeraldaFundo,
      appBar: AppBar(
        title: Text(
          _currentStep == 0 ? 'Conectar Empresa' : 'Seus Dados',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: amareloDestaque),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Progress Bar
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: amareloDestaque,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: _currentStep == 1 ? amareloDestaque : Colors.white24,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 48),
              
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _currentStep == 0 ? _buildStep1() : _buildStep2(),
              ),
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
        key: const ValueKey(0),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.business_center_rounded, size: 80, color: amareloDestaque),
          const SizedBox(height: 32),
          const Text(
            'Qual o CNPJ da sua MEI?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Vamos buscar as informações públicas da sua empresa para agilizar o cadastro.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 56),
          TextFormField(
            inputFormatters: [_cnpjMask],
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2),
            textAlign: TextAlign.center,
            decoration: _inputDecoration('CNPJ', Icons.search).copyWith(
              hintText: '00.000.000/0000-00',
              hintStyle: const TextStyle(color: Colors.white24, fontSize: 20),
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
              backgroundColor: amareloDestaque,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 24),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                  )
                : const Text(
                    'Validar Empresa',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
        key: const ValueKey(1),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: verdeCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: amareloDestaque.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                const Icon(Icons.verified_rounded, color: amareloDestaque, size: 40),
                const SizedBox(height: 16),
                if (_razaoSocial.isNotEmpty)
                  Text(
                    _razaoSocial,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  )
                else
                  TextFormField(
                    initialValue: '',
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration('Razão Social da sua MEI', Icons.business).copyWith(
                      hintText: 'Digite o nome oficial',
                    ),
                    onChanged: (val) => _razaoSocial = val,
                    validator: (val) => (val == null || val.isEmpty) ? 'Campo obrigatório' : null,
                  ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _isBeleza ? amareloDestaque.withValues(alpha: 0.1) : Colors.white10,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _isBeleza ? amareloDestaque : Colors.white24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_isBeleza ? Icons.auto_awesome_rounded : Icons.work_outline_rounded, 
                           size: 14, color: _isBeleza ? amareloDestaque : Colors.white70),
                      const SizedBox(width: 6),
                      Text(
                        _isBeleza ? "PERFIL: ESTÉTICA & BELEZA" : "PERFIL: SERVIÇOS GERAIS",
                        style: TextStyle(
                          color: _isBeleza ? amareloDestaque : Colors.white70,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          const Text(
            'Seus dados pessoais',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          _buildTextField(
            label: 'Nome Completo',
            icon: Icons.person_outline_rounded,
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
            label: 'Crie sua Senha',
            icon: Icons.lock_outline_rounded,
            obscureText: true,
            validator: (val) {
              if (val == null || val.length < 8) return 'Mínimo de 8 caracteres';
              return null;
            },
            onSaved: (val) => _password = val ?? '',
          ),
          const SizedBox(height: 24),
          // Terms of Use
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Checkbox(
                  value: _aceitouTermos,
                  activeColor: amareloDestaque,
                  checkColor: Colors.black,
                  side: const BorderSide(color: Colors.white30),
                  onChanged: (bool? value) {
                    setState(() {
                      _aceitouTermos = value ?? false;
                    });
                  },
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, '/privacy_policy');
                    },
                    child: RichText(
                      text: const TextSpan(
                        style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                        children: [
                          TextSpan(text: 'Li e concordo com os '),
                          TextSpan(
                            text: 'Termos e Privacidade.',
                            style: TextStyle(
                              color: amareloDestaque,
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
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: (_isLoading || !_aceitouTermos) ? null : _performRegistration,
            style: ElevatedButton.styleFrom(
              backgroundColor: amareloDestaque,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 24),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              disabledBackgroundColor: Colors.white12,
              elevation: 4,
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                  )
                : const Text(
                    'Concluir Cadastro',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
          ),
          const SizedBox(height: 20),
          TextButton(
            onPressed: () {
              setState(() => _currentStep = 0);
            },
            child: const Text('Voltar e editar CNPJ', style: TextStyle(color: Colors.white54)),
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
      style: const TextStyle(color: Colors.white),
      decoration: _inputDecoration(label, icon),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white60),
      prefixIcon: Icon(icon, color: amareloDestaque),
      filled: true,
      fillColor: verdeCard.withValues(alpha: 0.3),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: amareloDestaque, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 2),
      ),
    );
  }
}
