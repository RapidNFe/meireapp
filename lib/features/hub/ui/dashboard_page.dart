import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meire/core/ui/theme.dart';
import 'package:meire/core/ui/notifications_modal.dart';
import 'package:meire/features/history/ui/invoice_history_page.dart';
import 'package:meire/features/profile/ui/profile_page.dart';
import 'package:meire/features/auth/ui/gov_integration_page.dart';
import 'package:meire/features/hub/provider/notas_fiscais_provider.dart';
import 'package:meire/features/auth/services/auth_service.dart';
import 'package:meire/core/provider/settings_provider.dart';
import 'package:meire/features/clients/ui/customer_central_page.dart';
import 'package:meire/core/services/pocketbase_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;

class HubPage extends ConsumerStatefulWidget {
  const HubPage({super.key});

  @override
  ConsumerState<HubPage> createState() => _HubPageState();
}

class _HubPageState extends ConsumerState<HubPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authServiceProvider).currentUser;
      if (user?.getStringValue('status_registro') == 'conta_criada') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const GovIntegrationPage()),
        );
      }
    });
  }

  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final userRecord = ref.watch(userProvider);
    
    var fullName = userRecord?.getStringValue('name') ?? '';
    if (fullName.isEmpty) fullName = userRecord?.getStringValue('nome_fantasia') ?? '';
    if (fullName.isEmpty) fullName = userRecord?.getStringValue('razao_social') ?? '';

    final userName =
        fullName.isNotEmpty ? fullName.split(' ').first : 'Usuário';

    // Provider Access for Revenue real via PocketBase
    final revenueAsync = ref.watch(revenueStatsProvider);
    final stats = revenueAsync.valueOrNull ?? RevenueStats.empty();

    // Formatters
    final currencyFormatter =
        NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    // Formatting values
    final annualLimitPercentageString =
        '${(stats.percentage * 100).toStringAsFixed(0)}%';

    final annualRevenueString = currencyFormatter.format(stats.annualTotal);
    final meiLimitString = currencyFormatter.format(stats.annualLimit);
    final remainingString = currencyFormatter.format(stats.remaining);

    final List<Widget> pages = [
      _buildInicioTab(
          context,
          stats.percentage,
          annualLimitPercentageString,
          annualRevenueString,
          meiLimitString,
          remainingString,
          userRecord?.getStringValue('status_registro') ?? 'conta_criada',
          userRecord),
      const InvoiceHistoryPage(),
      const CustomerCentralPage(),
      const ProfilePage(),
    ];

    return Scaffold(
      appBar: _buildAppBar(userName, settings),
      body: pages[_currentIndex],
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  PreferredSizeWidget _buildAppBar(String userName, SettingsState settings) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: MeireTheme.primaryColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.account_balance_wallet_outlined,
                color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Olá, $userName",
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : MeireTheme.primaryColor)),
              const Text("MEI ATIVO",
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: Colors.grey)),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () {
            ref.read(settingsProvider.notifier).toggleCompact();
          },
          tooltip: 'Modo Compacto',
          icon: Icon(
              settings.isCompact
                  ? Icons.unfold_more_outlined
                  : Icons.unfold_less_outlined,
              color: isDark ? Colors.white : MeireTheme.primaryColor),
          style: IconButton.styleFrom(
              backgroundColor:
                  isDark ? const Color(0xFF1E293B) : MeireTheme.iceGray,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12))),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: () {
            ref.read(settingsProvider.notifier).toggleTheme();
          },
          tooltip: 'Alternar Tema',
          icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              color: isDark ? Colors.white : MeireTheme.primaryColor),
          style: IconButton.styleFrom(
              backgroundColor:
                  isDark ? const Color(0xFF1E293B) : MeireTheme.iceGray,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12))),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: () {
            NotificationsModal.show(context);
          },
          icon: Icon(Icons.notifications_none,
              color: isDark ? Colors.white : MeireTheme.primaryColor),
          style: IconButton.styleFrom(
              backgroundColor:
                  isDark ? const Color(0xFF1E293B) : MeireTheme.iceGray,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12))),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: () {
            ref.read(authServiceProvider).logout();
          },
          tooltip: 'Sair da Conta',
          icon: Icon(Icons.logout,
              color: isDark ? Colors.white : MeireTheme.primaryColor),
          style: IconButton.styleFrom(
              backgroundColor:
                  isDark ? const Color(0xFF1E293B) : MeireTheme.iceGray,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12))),
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildInicioTab(
      BuildContext context,
      double annualLimitPercentage,
      String annualLimitPercentageString,
      String annualRevenueString,
      String meiLimitString,
      String remainingString,
      String statusRegistro,
      dynamic userRecord) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final bool isPending = statusRegistro == 'aguardando_procuracao' || statusRegistro == 'conta_criada';

              Widget statusCard = Container();
              final bool possessesCert = userRecord?.getBoolValue('possui_certificado') ?? false;

              if (isPending) {
                statusCard = Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: MeireTheme.accentColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: MeireTheme.accentColor.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.hourglass_empty_rounded, color: MeireTheme.accentColor, size: 32),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Análise em Andamento",
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: MeireTheme.primaryColor),
                              ),
                              SizedBox(height: 4),
                              Text(
                                "Sua e-Procuração está sendo validada pelos nossos contadores. Isso costuma levar pouco tempo. Assim que confirmada, seu emissor de notas será destravado.",
                                style: TextStyle(fontSize: 13, color: Colors.grey, height: 1.4),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              } else if (statusRegistro == 'ativado' && possessesCert) {
                // STATUS 100% VERDINHO E OPERACIONAL
                statusCard = Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.verified_user_rounded, color: Colors.green, size: 32),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "SISTEMA 100% OPERACIONAL",
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF065F46)),
                              ),
                              SizedBox(height: 4),
                              Text(
                                "Seu motor de emissão está calibrado e o cofre blindado ativo. Você já pode emitir suas NFS-e com segurança total.",
                                style: TextStyle(fontSize: 13, color: Colors.grey, height: 1.4),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Breakpoint adjusted for earlier mobile-format switch
              if (constraints.maxWidth > 950) {
                return Column(
                  children: [
                    statusCard,
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 6,
                          child: Column(
                            children: [
                              _buildTermometroCard(context),
                              const SizedBox(height: 16),
                              _buildPerformanceSemestral(context),
                              const SizedBox(height: 16),
                              _buildMeiLimitCard(
                                  annualLimitPercentage,
                                  annualLimitPercentageString,
                                  annualRevenueString,
                                  meiLimitString,
                                  remainingString),
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          flex: 4,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildDasUrgencyCard(),
                              const SizedBox(height: 24),
                              const Text(
                                "AÇÕES RÁPIDAS",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: MeireTheme.accentColor,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildQuickActionsGrid(context, statusRegistro),
                              _buildRecentActivities(context),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              } else {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    statusCard,
                    _buildTermometroCard(context),
                    const SizedBox(height: 16),
                    _buildPerformanceSemestral(context),
                    const SizedBox(height: 16),
                    _buildMeiLimitCard(
                        annualLimitPercentage,
                        annualLimitPercentageString,
                        annualRevenueString,
                        meiLimitString,
                        remainingString),
                    const SizedBox(height: 16),
                    _buildDasUrgencyCard(),
                    const SizedBox(height: 24),
                    const Text(
                      "AÇÕES RÁPIDAS",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: MeireTheme.accentColor,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildQuickActionsGrid(context, statusRegistro),
                    _buildRecentActivities(context),
                  ],
                );
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTermometroCard(BuildContext context) {
    final impostoAsync = ref.watch(impostoEstimativaProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark ? [const Color(0xFF1E293B), const Color(0xFF0F172A)] : [const Color(0xFF1E3A8A), const Color(0xFF172554)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: impostoAsync.when(
        data: (imposto) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Resumo Financeiro", style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
                    child: Text(imposto.referencia.isNotEmpty ? imposto.referencia : "Atual", style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Faturamento Mensal", style: TextStyle(color: Colors.white70, fontSize: 12)),
                        const SizedBox(height: 4),
                        TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0, end: imposto.faturamento),
                          duration: const Duration(milliseconds: 1500),
                          curve: Curves.easeOut,
                          builder: (context, value, child) {
                            return Text(
                              NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(value),
                              style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  if (imposto.faturamento > 0)
                    AnimatedDonutChart(faturamento: imposto.faturamento, imposto: imposto.imposto),
                ],
              ),
              // Seção de imposto removida conforme solicitado
            ],
          );
        },
        loading: () => const SizedBox(height: 180, child: Center(child: CircularProgressIndicator(color: Colors.white))),
        error: (err, stack) => const SizedBox(height: 180, child: Center(child: Text('Erro ao carregar dados', style: TextStyle(color: Colors.white)))),
      ),
    );
  }

  Widget _buildMeiLimitCard(
      double annualLimitPercentage,
      String annualLimitPercentageString,
      String annualRevenueString,
      String meiLimitString,
      String remainingString) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white10 : MeireTheme.iceGray),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Limite MEI (Anual)",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text(annualLimitPercentageString,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      )),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: annualLimitPercentage,
            backgroundColor: isDark ? Colors.white10 : MeireTheme.iceGray,
            color: annualLimitPercentage > 0.8
                ? Colors.amber
                : MeireTheme.accentColor,
            borderRadius: BorderRadius.circular(10),
            minHeight: 10,
          ),
          const SizedBox(height: 12),
          if (annualLimitPercentage > 0.8)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color:
                      Colors.amber.shade50.withValues(alpha: isDark ? 0.1 : 1),
                  borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      size: 16, color: Colors.amber.shade900),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(
                          "Atenção: Você atingiu $annualRevenueString. Restam apenas $remainingString antes do desenquadramento.",
                          style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? Colors.amber.shade200
                                  : Colors.amber.shade900,
                              fontWeight: FontWeight.w600))),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Total Emitido: $annualRevenueString de $meiLimitString",
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500)),
                  Text("Faltam: $remainingString",
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.green.shade600,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            )
        ],
      ),
    );
  }

  Widget _buildDasUrgencyCard() {
    final now = DateTime.now();
    var dueDate = DateTime(now.year, now.month, 20);
    if (now.isAfter(dueDate)) {
      dueDate = DateTime(now.year, now.month + 1, 20);
    }
    final daysRemaining = dueDate.difference(now).inDays;
    final formattedDueDate =
        DateFormat("dd 'de' MMMM", 'pt_BR').format(dueDate);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [MeireTheme.primaryColor, Color(0xFF1E3A8A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: MeireTheme.primaryColor.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10))
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: 0,
            top: 10,
            child: Icon(Icons.event_available,
                size: 100, color: Colors.white.withValues(alpha: 0.05)),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("GUIA DE IMPOSTO",
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2)),
                const SizedBox(height: 4),
                Text("Próximo DAS",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(daysRemaining.toString().padLeft(2, '0'),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.w900)),
                    const SizedBox(width: 6),
                    const Text("Dias",
                        style: TextStyle(color: Colors.white70, fontSize: 16)),
                  ],
                ),
                Text("Vencimento: $formattedDueDate",
                    style:
                        const TextStyle(color: Colors.white60, fontSize: 11)),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () async {
                    final user = ref.read(authServiceProvider).currentUser;
                    final cnpj = user?.getStringValue('cnpj') ?? '';
                    
                    if (cnpj.isNotEmpty) {
                      await Clipboard.setData(ClipboardData(text: cnpj));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("✨ CNPJ $cnpj copiado para o pagamento!"),
                            backgroundColor: MeireTheme.primaryColor,
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 4),
                          ),
                        );
                      }
                    }

                    final uri = Uri.parse('https://www8.receita.fazenda.gov.br/SimplesNacional/Aplicacoes/ATSPO/pgmei.app/Identificacao');
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                  icon: const Icon(Icons.qr_code_scanner,
                      color: MeireTheme.primaryColor, size: 18),
                  label: const Text("Pagar Agora (PIX)",
                      style: TextStyle(
                          color: MeireTheme.primaryColor,
                          fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 44),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showActivationBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 60,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(2),
              ),
              alignment: Alignment.center,
              child: const SizedBox.shrink(),
            ),
            const Icon(Icons.rocket_launch_outlined, color: MeireTheme.accentColor, size: 48),
            const SizedBox(height: 24),
            const Text(
              "Emissor em Ativação",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: MeireTheme.primaryColor),
            ),
            const SizedBox(height: 16),
            const Text(
              "Nossa equipe está validando sua e-Procuração junto à Receita Federal. Esse processo é rápido.\n\nEnquanto isso, você já pode cadastrar seus clientes e serviços no aplicativo.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.5),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: MeireTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text("Entendi", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsGrid(BuildContext context, String statusRegistro) {
    final bool isAwaiting = statusRegistro == 'aguardando_procuracao';
    final bool isCreated = statusRegistro == 'conta_criada';
    final bool isLocked = isAwaiting || isCreated;

    return Column(
      children: [
        if (isLocked)
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: MeireTheme.accentColor.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: MeireTheme.accentColor.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified_user_outlined, color: MeireTheme.accentColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAwaiting ? "Quase lá! Ativando Acesso" : "Configure o Emissor Nacional",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isAwaiting 
                          ? "Estamos habilitando seu perfil na Receita Federal. Navegue pelo app enquanto isso!"
                          : "Você precisa validar seus dados para começar a emitir notas fiscais pelo app.",
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        _buildActionItem(
          context, 
          Icons.receipt_long,
          "Emitir Minha Primeira Nota", 
          "Nota Fiscal de Serviço", 
          () {
            if (isCreated) {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const GovIntegrationPage()));
            } else if (isAwaiting) {
              _showActivationBottomSheet(context);
            } else {
              Navigator.pushNamed(context, '/nfse_form');
            }
          }, 
          isLocked: isLocked,
          showLockIcon: isAwaiting,
        ),
        const SizedBox(height: 12),
        _buildActionItem(
            context,
            Icons.bookmark_add_outlined,
            "Cadastrar Serviço Favorito",
            "Moldes de Notas Simplificadas",
            () => Navigator.pushNamed(context, '/favorite_service_form')),
        const SizedBox(height: 12),
        _buildActionItem(context, Icons.description_outlined,
            "Declaração Anual", "DASN-SIMEI 2024", 
            () => Navigator.pushNamed(context, '/dasn_copiloto')),
      ],
    );
  }

  Widget _buildRecentActivities(BuildContext context) {
    final historicoAsync = ref.watch(historicoNotasProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        const Text(
          "ATIVIDADES RECENTES",
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: MeireTheme.accentColor,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        historicoAsync.when(
          data: (notas) {
            if (notas.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : MeireTheme.iceGray),
                ),
                child: Column(
                  children: [
                    Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey.withValues(alpha: 0.1)),
                    const SizedBox(height: 16),
                    const Text(
                      "Sua primeira nota aparecerá aqui.",
                      style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              );
            }

            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : MeireTheme.iceGray),
              ),
              child: ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: notas.length > 5 ? 5 : notas.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final nota = notas[index];
                  
                  Color statusColor;
                  IconData statusIcon;
                  switch (nota.status.toLowerCase()) {
                    case 'emitida':
                      statusColor = Colors.green;
                      statusIcon = Icons.check;
                      break;
                    case 'cancelada':
                      statusColor = Colors.red;
                      statusIcon = Icons.close;
                      break;
                    case 'erro':
                      statusColor = Colors.red;
                      statusIcon = Icons.error_outline;
                      break;
                    default: // processando
                      statusColor = Colors.amber;
                      statusIcon = Icons.sync;
                  }

                  final dataFormatada = DateFormat("dd MMM, HH:mm", "pt_BR").format(nota.created);
                  final subtitle = nota.numeroNota.isNotEmpty 
                      ? "$dataFormatada • Nota #${nota.numeroNota}"
                      : dataFormatada;

                  final valorFormatado = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(nota.valor);

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: statusColor.withValues(alpha: 0.9),
                      radius: 20,
                      child: Icon(statusIcon, color: statusColor, size: 20),
                    ),
                    title: Text(
                      nota.tomadorNome.isNotEmpty ? nota.tomadorNome : "Cliente Não Informado",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      subtitle,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    trailing: Text(
                      valorFormatado,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                  );
                },
              ),
            );
          },
          loading: () => const Center(child: Padding(padding: EdgeInsets.all(24.0), child: CircularProgressIndicator())),
          error: (err, stack) => Center(child: Text('Erro ao carregar histórico', style: TextStyle(color: Colors.red.shade300))),
        ),
      ],
    );
  }

  Widget _buildActionItem(BuildContext context, IconData icon, String title,
      String subtitle, VoidCallback onTap,
      {bool isLocked = false, bool showLockIcon = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: isDark ? Colors.white10 : MeireTheme.iceGray),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : MeireTheme.iceGray,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon,
                  color: isDark
                      ? (isLocked ? Colors.grey : MeireTheme.accentColor)
                      : (isLocked ? Colors.grey : MeireTheme.primaryColor)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(subtitle,
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            Icon(showLockIcon ? Icons.lock_outline : (isLocked ? Icons.arrow_forward : Icons.chevron_right),
                color: (showLockIcon || isLocked) ? MeireTheme.accentColor : Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceSemestral(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white10 : MeireTheme.iceGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Performance Semestral",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Icon(Icons.timeline, color: Colors.grey.shade400, size: 20),
            ],
          ),
          const SizedBox(height: 24),
          const SizedBox(
            height: 120, // Altura do gráfico
            child: SparklineWidget(),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
          border: Border(
              top: BorderSide(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white10
                      : MeireTheme.iceGray))),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.grid_view_rounded), label: "Início"),
          BottomNavigationBarItem(
              icon: Icon(Icons.history_edu), label: "Notas"),
          BottomNavigationBarItem(
              icon: Icon(Icons.people_alt), label: "Clientes"),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline), label: "Perfil"),
        ],
      ),
    );
  }
}

class AnimatedDonutChart extends StatelessWidget {
  final double faturamento;
  final double imposto;
  const AnimatedDonutChart({super.key, required this.faturamento, required this.imposto});

  @override
  Widget build(BuildContext context) {
    if (faturamento == 0) return const SizedBox.shrink();
    final impostoPerc = imposto / faturamento;
    
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: impostoPerc),
      duration: const Duration(milliseconds: 1500),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return CustomPaint(
          size: const Size(64, 64),
          painter: DonutChartPainter(
            impostoPercentage: value,
          ),
        );
      },
    );
  }
}

class DonutChartPainter extends CustomPainter {
  final double impostoPercentage;
  DonutChartPainter({required this.impostoPercentage});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 8.0;

    final paintImposto = Paint()
      ..color = Colors.amber
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
      
    final paintLucro = Paint()
      ..color = Colors.white.withValues(alpha: 1.0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCircle(center: center, radius: radius - strokeWidth / 2);
    const startAngle = -math.pi / 2;

    final sweepImposto = (2 * math.pi) * impostoPercentage;
    final sweepLucro = (2 * math.pi) * (1 - impostoPercentage);
    
    // Micro gap para separar as partes da pizza para um look premium
    const gap = 0.15;
    
    if (impostoPercentage > 0 && impostoPercentage < 1 && sweepLucro > gap && sweepImposto > gap) {
       canvas.drawArc(rect, startAngle + gap / 2, sweepLucro - gap, false, paintLucro);
       canvas.drawArc(rect, startAngle + sweepLucro + gap / 2, sweepImposto - gap, false, paintImposto);
    } else {
       canvas.drawArc(rect, startAngle, sweepLucro, false, paintLucro);
       canvas.drawArc(rect, startAngle + sweepLucro, sweepImposto, false, paintImposto);
    }
  }

  @override
  bool shouldRepaint(DonutChartPainter oldDelegate) => 
      oldDelegate.impostoPercentage != impostoPercentage;
}

class SparklineWidget extends ConsumerWidget {
  const SparklineWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historicoAsync = ref.watch(historicoFaturamentoProvider);

    return historicoAsync.when(
      data: (historico) {
        if (historico.isEmpty) {
          return const Center(
            child: Text('Sem histórico no momento', style: TextStyle(color: Colors.grey, fontSize: 12)),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            return CustomPaint(
              size: Size(constraints.maxWidth, constraints.maxHeight),
              painter: SparklineChartPainter(
                data: historico,
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      error: (_, __) => const Center(child: Text('Erro ao carregar', style: TextStyle(color: Colors.grey, fontSize: 12))),
    );
  }
}

class SparklineChartPainter extends CustomPainter {
  final List<HistoricoMes> data;

  SparklineChartPainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final double maxVal = data.map((e) => e.valor).reduce(math.max);
    final maxScale = maxVal == 0 ? 1.0 : maxVal; // Prevent division by zero

    final w = size.width;
    final h = size.height;

    // Definição da Linha Principal
    final paintLine = Paint()
      ..color = Colors.amber
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    final fillPath = Path();

    final stepX = w / (data.length > 1 ? data.length - 1 : 1);

    for (int i = 0; i < data.length; i++) {
        final double x = i * stepX;
        final double normalizedY = data[i].valor / maxScale;
        // The Y coordinate: 0 is at the bottom, so h - (normalizedY * h)
        // Margem de 10% embaixo e cima, escala 80%
        final double y = h - (normalizedY * (h * 0.8)) - (h * 0.1); 

        if (i == 0) {
            path.moveTo(x, y);
            fillPath.moveTo(x, h);
            fillPath.lineTo(x, y);
        } else {
            // Curva suave
            final prevX = (i - 1) * stepX;
            final prevNormalizedY = data[i - 1].valor / maxScale;
            final prevY = h - (prevNormalizedY * (h * 0.8)) - (h * 0.1);

            final controlX1 = prevX + (stepX / 2);
            final controlY1 = prevY;
            final controlX2 = prevX + (stepX / 2);
            final controlY2 = y;
            
            path.cubicTo(controlX1, controlY1, controlX2, controlY2, x, y);
            fillPath.cubicTo(controlX1, controlY1, controlX2, controlY2, x, y);
        }
    }

    fillPath.lineTo(w, h); // Desce até a base
    fillPath.close();

    // Gradiente de Fundo
    final gradient = LinearGradient(
        colors: [
            Colors.amber.withValues(alpha: 0.35),
            Colors.amber.withValues(alpha: 0.0),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
    );

    final paintFill = Paint()..shader = gradient.createShader(Rect.fromLTWH(0, 0, w, h));

    canvas.drawPath(fillPath, paintFill);
    canvas.drawPath(path, paintLine);

    // Labels e Pontos
    final textPainter = TextPainter(textDirection: ui.TextDirection.ltr);

    for (int i = 0; i < data.length; i++) {
        final double x = i * stepX;
        final double normalizedY = data[i].valor / maxScale;
        final double y = h - (normalizedY * (h * 0.8)) - (h * 0.1);

        final pointPaintOuter = Paint()..color = Colors.white..style = PaintingStyle.fill;
        final pointPaintInner = Paint()..color = Colors.amber..style = PaintingStyle.fill;
        
        canvas.drawCircle(Offset(x, y), 5.0, pointPaintOuter);
        canvas.drawCircle(Offset(x, y), 3.0, pointPaintInner);

        textPainter.text = TextSpan(
            text: data[i].label,
            style: TextStyle(color: Colors.grey.shade400, fontSize: 10, fontWeight: FontWeight.bold),
        );
        textPainter.layout();
        
        final double tx = x - (textPainter.width / 2);
        // Garante que o texto não ultrapassa a tela
        final double boundedTx = tx < 0 ? 0 : (tx + textPainter.width > w ? w - textPainter.width : tx);

        textPainter.paint(
            canvas,
            Offset(boundedTx, h - (h * 0.05)),
        );
    }
  }

  @override
  bool shouldRepaint(SparklineChartPainter oldDelegate) {
    return oldDelegate.data != data;
  }
}

// Teste Append
