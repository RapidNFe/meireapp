import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:meire/core/ui/theme.dart';
import 'package:meire/features/auth/services/auth_service.dart';
import 'package:meire/features/auth/ui/gov_integration_page.dart';
import 'package:meire/core/services/pocketbase_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  bool _isLoadingSwitch = false;
  bool _isEditing = false;
  bool _isSaving = false;

  final _imController = TextEditingController();
  final _cepController = TextEditingController();
  final _senhaPfxController = TextEditingController();
  PlatformFile? _pickedFile;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    final user = ref.read(authServiceProvider).currentUser;
    if (user != null) {
      _imController.text = user.getStringValue('inscricao_municipal');
      _cepController.text = user.getStringValue('cep');
      _senhaPfxController.text = user.getBoolValue('possui_certificado') ? '********' : '';
    }
  }

  @override
  void dispose() {
    _imController.dispose();
    _cepController.dispose();
    _senhaPfxController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final authService = ref.read(authServiceProvider);
    final user = authService.currentUser;
    if (user == null) return;

    setState(() => _isSaving = true);

    try {
      final Map<String, dynamic> body = {
        'inscricao_municipal': _imController.text,
        'cep': _cepController.text.replaceAll(RegExp(r'[^0-9]'), ''),
      };

      // 1. Atualiza dados Cadastrais no PocketBase (Dados Seguros/Públicos)
      await ref.read(pbProvider).collection('users').update(user.id, body: body);

      // 2. Se o usuário tentou subir um pfx novo, usamos a Rota Blindada (Node)
      final senhaDigitada = _senhaPfxController.text;
      if (_pickedFile != null && _pickedFile!.bytes != null) {
        if (senhaDigitada.isEmpty || senhaDigitada == '********') {
            throw Exception('Você precisa fornecer a senha verdadeira para salvar o novo certificado.');
        }

        final uri = Uri.parse('$meireApiUrl/api/certificados/upload');
        final request = http.MultipartRequest('POST', uri)
          ..fields['userId'] = user.id
          ..fields['senha_pfx'] = senhaDigitada
          ..files.add(http.MultipartFile.fromBytes(
            'arquivo_pfx',
            _pickedFile!.bytes!,
            filename: _pickedFile!.name,
          ));

        final response = await request.send();
        
        if (response.statusCode != 201) {
          final resStr = await response.stream.bytesToString();
          throw Exception('Erro do cofre: $resStr');
        }
      } else if (senhaDigitada.isNotEmpty && senhaDigitada != '********') {
          // Se o usuário digitou senha nova MAS NÃO subiu arquivo
          throw Exception('Para segurança do cofre, envie o arquivo .pfx junto com a nova senha.');
      }

      // Refresh data
      await ref.read(pbProvider).collection('users').authRefresh();
      
      if (mounted) {
        setState(() {
          _isEditing = false;
          _isSaving = false;
        });
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Perfil atualizado com sucesso!')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Erro ao salvar: $e')),
        );
      }
    }
  }

  bool _checkCadastroCompleto(RecordModel user) {
    final im = user.getStringValue('inscricao_municipal');
    final cep = user.getStringValue('cep');
    final cnpj = user.getStringValue('cnpj');
    return im.isNotEmpty && cep.isNotEmpty && cnpj.length == 14;
  }

  bool _validarRequisitosProducao(RecordModel user) {
    List<String> pendencias = [];

    final cnpj = user.getStringValue('cnpj');
    final razaoSocial = user.getStringValue('razao_social');
    final im = user.getStringValue('inscricao_municipal');
    final cep = user.getStringValue('cep');

    if (cnpj.isEmpty || cnpj.length != 14) pendencias.add("CNPJ inválido ou incompleto");
    if (razaoSocial.isEmpty) pendencias.add("Razão Social ausente");
    if (im.isEmpty) pendencias.add("Inscrição Municipal (IM) ausente");
    if (cep.isEmpty) pendencias.add("CEP ausente");

    if (pendencias.isNotEmpty) {
      _mostrarAlertaPendencias(pendencias);
      return false;
    }
    return true;
  }

  void _mostrarAlertaPendencias(List<String> pendencias) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('Cadastro Incompleto'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Para ativar o Modo Real, corrija as seguintes pendências no seu perfil:'),
            const SizedBox(height: 16),
            ...pendencias.map((p) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text('• $p', style: const TextStyle(fontWeight: FontWeight.bold, color: MeireTheme.primaryColor)),
            )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Entendi', style: TextStyle(color: MeireTheme.accentColor, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = ref.watch(authServiceProvider);
    final user = authService.currentUser;

    if (user == null) {
      return const Center(child: Text('Nenhum dado do usuário encontrado.'));
    }

    final cnpj = user.getStringValue('cnpj');
    var displayName = user.getStringValue('name');
    if (displayName.isEmpty) displayName = user.getStringValue('nome_fantasia');
    if (displayName.isEmpty) displayName = user.getStringValue('razao_social');
    
    final email = user.getStringValue('email');
    final statusRegistro = user.getStringValue('status_registro');
    final modoProducao = user.getBoolValue('producao');

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 32),
              
              // 🎛️ 1. CONTROLE DE AMBIENTE
              Builder(
                builder: (context) {
                  final bool isCompleto = _checkCadastroCompleto(user);
                  return Opacity(
                    opacity: isCompleto ? 1.0 : 0.6,
                    child: _buildCard(
                      context: context,
                      title: 'Configurações de Emissão',
                      icon: isCompleto ? Icons.settings_remote : Icons.lock_outline,
                      isVault: true,
                      children: [
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Row(
                            children: [
                              const Text(
                                'Modo de Operação',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              if (!isCompleto)
                                const Padding(
                                  padding: EdgeInsets.only(left: 8.0),
                                  child: Icon(Icons.info_outline, size: 16, color: Colors.redAccent),
                                ),
                            ],
                          ),
                          subtitle: Text(
                            modoProducao ? '🚀 PRODUÇÃO (Notas Reais)' : '🛠️ HOMOLOGAÇÃO (Testes)',
                            style: TextStyle(
                              color: modoProducao ? Colors.green : Colors.orange,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          value: modoProducao,
                          activeThumbColor: Colors.green,
                          inactiveThumbColor: Colors.orange,
                          onChanged: _isLoadingSwitch ? null : (bool value) async {
                            if (value == true) {
                              if (!_validarRequisitosProducao(user)) return;
                            }

                            setState(() => _isLoadingSwitch = true);
                            try {
                              await ref.read(pbProvider).collection('users').update(user.id, body: {
                                'producao': value,
                              });
                              await ref.read(pbProvider).collection('users').authRefresh();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(value ? '🚀 Meire em Produção!' : '🛠️ Modo de Testes Ativado.'),
                                    backgroundColor: value ? Colors.green : Colors.orange,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Erro ao atualizar ambiente.')),
                                );
                              }
                            } finally {
                              if (mounted) setState(() => _isLoadingSwitch = false);
                            }
                          },
                        ),
                        const Divider(height: 32),
                        Text(
                          isCompleto 
                            ? 'Dica: Em Modo de Testes, as notas não possuem valor legal.'
                            : '⚠️ Finalize seu cadastro para habilitar o Modo de Produção.',
                          style: TextStyle(
                            color: isCompleto ? Colors.grey : Colors.redAccent, 
                            fontSize: 12, 
                            fontWeight: isCompleto ? null : FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 24),

              // 🛡️ 2. CERTIFICADO DIGITAL (Prioridade Máxima)
              _buildCard(
                context: context,
                title: 'Certificado Digital (A1 PFX)',
                icon: Icons.security,
                isVault: true,
                children: [
                   const Text(
                    'O arquivo .pfx e sua senha são essenciais para que você assine suas notas de forma oficial e soberana.',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  if (_isEditing) ...[
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      onPressed: () async {
                        final result = await FilePicker.platform.pickFiles(
                          type: FileType.custom,
                          allowedExtensions: ['pfx'],
                          withData: true,
                        );
                        if (result != null) {
                          setState(() => _pickedFile = result.files.first);
                        }
                      },
                      icon: const Icon(Icons.upload_file),
                      label: Text(_pickedFile != null ? 'Arquivo: ${_pickedFile!.name}' : 'Selecionar Certificado .pfx'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _senhaPfxController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Senha do Certificado',
                        prefixIcon: Icon(Icons.password),
                      ),
                    ),
                  ] else ...[
                    _InfoRow(
                      label: 'Arquivo PFX', 
                      value: !user.getBoolValue('possui_certificado') ? '❌ Não carregado' : '✅ Protegido no Cofre (Isolado)',
                      isPending: !user.getBoolValue('possui_certificado'),
                    ),
                    const Divider(height: 24),
                    _InfoRow(
                      label: 'Senha', 
                      value: !user.getBoolValue('possui_certificado') ? '❌ Pendente' : '✅ Configurada e Criptografada 🔐',
                      isPending: !user.getBoolValue('possui_certificado'),
                    ),
                    if (user.getStringValue('vencimento_pfx').isNotEmpty) ...[
                      const Divider(height: 24),
                      _InfoRow(
                        label: 'Vencimento', 
                        value: (() {
                          try {
                            final dataStr = user.getStringValue('vencimento_pfx');
                            final data = DateTime.parse(dataStr).toLocal();
                            final diferenca = data.difference(DateTime.now()).inDays;
                            final dataFormatada = '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';
                            if (diferenca < 0) return '❌ Expirado em $dataFormatada';
                            if (diferenca <= 30) return '⚠️ Vence em $diferenca dias ($dataFormatada)';
                            return '✅ Válido até $dataFormatada';
                          } catch (_) {
                            return 'Formato inválido';
                          }
                        })(),
                      ),
                    ],
                    const SizedBox(height: 24),
                    if (!_isEditing) 
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => setState(() => _isEditing = true),
                          icon: const Icon(Icons.cloud_upload_outlined),
                          label: const Text('Atualizar Certificado / Senha'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: MeireTheme.accentColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                  ]
                ],
              ),

              const SizedBox(height: 24),

              // 👤 3. INFORMAÇÕES PESSOAIS
              _buildCard(
                context: context,
                title: 'Informações Pessoais',
                icon: Icons.person_outline,
                extra: TextButton.icon(
                  onPressed: _isSaving ? null : () {
                    if (_isEditing) {
                      _saveProfile();
                    } else {
                      _initializeControllers();
                      setState(() => _isEditing = true);
                    }
                  },
                  icon: Icon(_isEditing ? Icons.check : Icons.edit),
                  label: Text(_isEditing ? 'Salvar' : 'Editar'),
                  style: TextButton.styleFrom(
                    foregroundColor: _isEditing ? Colors.green : MeireTheme.accentColor,
                  ),
                ),
                children: [
                  _InfoRow(label: 'Nome', value: displayName),
                  const Divider(height: 24),
                  _InfoRow(label: 'E-mail', value: email),
                  const Divider(height: 24),
                  _InfoRow(label: 'CPF', value: _formatDocument(user.getStringValue('cpf'))),
                  const Divider(height: 24),
                  _InfoRow(label: 'CNPJ', value: _formatDocument(cnpj)),
                  const Divider(height: 24),
                  if (_isEditing)
                    Column(
                      children: [
                        TextFormField(
                          controller: _imController,
                          decoration: const InputDecoration(labelText: 'Inscrição Municipal'),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _cepController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'CEP'),
                        ),
                      ],
                    )
                  else
                    Column(
                      children: [
                        _InfoRow(
                          label: 'Insc. Municipal', 
                          value: user.getStringValue('inscricao_municipal').isEmpty ? '⚠️ Pendente' : user.getStringValue('inscricao_municipal'),
                          isPending: user.getStringValue('inscricao_municipal').isEmpty,
                        ),
                        const Divider(height: 24),
                        _InfoRow(
                          label: 'CEP', 
                          value: user.getStringValue('cep').isEmpty ? '⚠️ Pendente' : _formatCEP(user.getStringValue('cep')),
                          isPending: user.getStringValue('cep').isEmpty,
                        ),
                      ],
                    ),
                ],
              ),

              const SizedBox(height: 24),

              // 🏦 4. INTEGRAÇÃO GOVERNAMENTAL
              _buildCard(
                context: context,
                title: 'Integração Governamental',
                icon: Icons.account_balance,
                children: [
                  if (statusRegistro == 'conta_criada')
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Conecte seu acesso ao Governo para sincronizar dados e facilitar a gestão do seu MEI.',
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const GovIntegrationPage()));
                          },
                          icon: const Icon(Icons.add_moderator),
                          label: const Text('Conectar via e-CAC'),
                        ),
                      ],
                    )
                  else if (statusRegistro == 'aguardando_procuracao')
                    const Row(
                      children: [
                        Icon(Icons.hourglass_top, color: Colors.orange, size: 20),
                        SizedBox(width: 8),
                        Text('Análise da e-Procuração em curso...', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    )
                  else
                    const Row(
                      children: [
                        Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
                        SizedBox(width: 8),
                        Text('Acesso Delegado Ativo ✓', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                      ],
                    ),
                ],
              ),
              
              const SizedBox(height: 32),
              
              // BOTÕES DE SAÍDA
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => ref.read(authServiceProvider).logout(),
                  icon: const Icon(Icons.logout),
                  label: const Text('Sair da Conta'),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () => _mostrarModalDeExclusao(context, ref),
                  icon: const Icon(Icons.delete_forever, color: Colors.redAccent),
                  label: const Text('Excluir Minha Conta', style: TextStyle(color: Colors.redAccent)),
                ),
              ),
              const SizedBox(height: 56),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarModalDeExclusao(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Excluir Conta Definitivamente?'),
          content: const Text(
            'Esta ação é irreversível. Todos os seus clientes, histórico de notas fiscais e cálculos de impostos serão apagados dos nossos servidores imediatamente, em conformidade com a LGPD.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                try {
                  final authService = ref.read(authServiceProvider);
                  final userId = authService.currentUser?.id;
                  
                  if (userId != null) {
                    await authService.deleteAccount(userId);
                    if (context.mounted) Navigator.of(context).pop();
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Erro ao excluir conta. Tente novamente.')),
                    );
                  }
                }
              },
              child: const Text('Sim, Excluir Tudo'),
            ),
          ],
        );
      },
    );
  }

  String _formatDocument(String doc) {
    if (doc.length == 11) {
       return '${doc.substring(0, 3)}.${doc.substring(3, 6)}.${doc.substring(6, 9)}-${doc.substring(9, 11)}';
    } else if (doc.length == 14) {
      return '${doc.substring(0, 2)}.${doc.substring(2, 5)}.${doc.substring(5, 8)}/${doc.substring(8, 12)}-${doc.substring(12, 14)}';
    }
    return doc;
  }

  String _formatCEP(String cep) {
    if (cep.length == 8) {
      return '${cep.substring(0, 5)}-${cep.substring(5, 8)}';
    }
    return cep;
  }

  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Seu Perfil MEI",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: MeireTheme.primaryColor,
          ),
        ),
        SizedBox(height: 8),
        Text(
          "Gerencie suas informações e acesse seus dados com segurança.",
          style: TextStyle(color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required List<Widget> children,
    Widget? extra,
    bool isVault = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isVault
              ? MeireTheme.accentColor.withValues(alpha: 0.5)
              : (isDark ? Colors.white10 : MeireTheme.iceGray),
          width: isVault ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isVault
                ? MeireTheme.accentColor.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon,
                  color: isVault
                      ? MeireTheme.accentColor
                      : MeireTheme.primaryColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (extra != null) ...[
                const Spacer(),
                extra,
              ] else if (isVault) ...[
                const Spacer(),
                const Icon(Icons.lock, size: 16, color: Colors.grey),
              ]
            ],
          ),
          const SizedBox(height: 24),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isPending;

  const _InfoRow({
    required this.label, 
    required this.value, 
    this.isPending = false
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(label,
              style: const TextStyle(
                  color: Colors.grey, fontWeight: FontWeight.w500)),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value, 
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isPending ? Colors.redAccent : null,
            ),
          ),
        ),
      ],
    );
  }
}
