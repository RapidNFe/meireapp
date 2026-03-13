import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/ui/theme.dart';
import '../../auth/services/auth_service.dart';
import '../provider/copiloto_provider.dart';

class DasnCopilotoPage extends ConsumerStatefulWidget {
  const DasnCopilotoPage({super.key});

  @override
  ConsumerState<DasnCopilotoPage> createState() => _DasnCopilotoPageState();
}

class _DasnCopilotoPageState extends ConsumerState<DasnCopilotoPage> {
  int _selectedYear = DateTime.now().year - 1;
  int _currentStep = 0;
  bool _profileStepConfirmed = false;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authServiceProvider).currentUser;
    final cnpj = user?.getStringValue('cnpj') ?? '';
    final statsAsync = ref.watch(dasnCopilotoProvider(_selectedYear));

    return Scaffold(
      backgroundColor: MeireTheme.backgroundColor,
      appBar: AppBar(
        title: const Text("Controle Remoto e-CAC", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Stepper(
        type: StepperType.vertical,
        currentStep: _currentStep,
        onStepTapped: (step) => setState(() => _currentStep = step),
        elevation: 0,
        controlsBuilder: (context, details) => const SizedBox.shrink(),
        steps: [
          Step(
            title: const Text("PASSO 1: A Infiltração (Login)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            state: _currentStep > 0 ? StepState.complete : StepState.indexed,
            isActive: _currentStep >= 0,
            content: _buildLoginStep(),
          ),
          Step(
            title: const Text("PASSO 2: A Virada de Chave (Perfil)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            state: _currentStep > 1 ? StepState.complete : (_profileStepConfirmed ? StepState.editing : StepState.indexed),
            isActive: _currentStep >= 1,
            content: _buildProfileStep(cnpj),
          ),
          Step(
            title: const Text("PASSO 3: Arsenal de Precisão", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            state: _currentStep > 2 ? StepState.complete : StepState.indexed,
            isActive: _currentStep >= 2,
            content: _buildActionArsenal(statsAsync),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginStep() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MeireTheme.iceGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "O acesso ao e-CAC será feito com seu CPF e senha Gov.br, dentro do nosso Trilho Tático.",
            style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () async {
              final uri = Uri.parse('https://cav.receita.fazenda.gov.br/ecac/');
              await launchUrl(uri, mode: LaunchMode.inAppWebView);
            },
            icon: const Icon(Icons.login_rounded),
            label: const Text("Abrir Portal e-CAC"),
            style: ElevatedButton.styleFrom(
              backgroundColor: MeireTheme.primaryColor,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.info_outline, size: 14, color: MeireTheme.accentColor),
              const SizedBox(width: 8),
              const Expanded(
                child: Text("Isso abrirá o navegador oficial da Receita sem sair do Meire.", 
                    style: TextStyle(fontSize: 11, color: Colors.grey)),
              ),
              TextButton(
                onPressed: () => setState(() => _currentStep = 1),
                child: const Text("Logado", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileStep(String cnpj) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MeireTheme.iceGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "No topo da tela do governo, mude para o perfil de acesso do seu CNPJ.",
            style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 20),
          _buildInstructionVisual(),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: MeireTheme.backgroundColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Seu CNPJ para colar:", style: TextStyle(fontSize: 10, color: Colors.grey)),
                      Text(cnpj, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.2)),
                    ],
                  ),
                ),
                ElevatedButton(
                   onPressed: () {
                    Clipboard.setData(ClipboardData(text: cnpj));
                    HapticFeedback.vibrate();
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: MeireTheme.accentColor, minimumSize: const Size(40, 40)),
                  child: const Icon(Icons.copy, size: 18),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => setState(() {
              _profileStepConfirmed = true;
              _currentStep = 2;
            }),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Perfil Alterado com Sucesso"),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionVisual() {
    return Container(
      height: 80,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.blue.shade900, Colors.blue.shade700]),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          Positioned(
            right: 10,
            top: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.amber.shade600,
                borderRadius: BorderRadius.circular(4),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
              ),
              child: const Row(
                children: [
                  Icon(Icons.person_search, size: 14, color: Colors.white),
                  SizedBox(width: 4),
                  Text("Alterar Perfil", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          const Center(
            child: Icon(Icons.ads_click_rounded, color: Colors.white54, size: 40),
          ),
        ],
      ),
    );
  }

  Widget _buildActionArsenal(AsyncValue<DasnStats> statsAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Você agora tem o controle total. Use os links de precisão abaixo:",
          style: TextStyle(color: Colors.grey, fontSize: 13),
        ),
        const SizedBox(height: 20),
        _buildMetricSummaryWidget(statsAsync),
        const SizedBox(height: 24),
        _buildMissionTarget(
          title: "Declaração Anual (DASN-SIMEI)",
          desc: "Consultar ou transmitir sua declaração",
          url: "https://cav.receita.fazenda.gov.br/ecac/Aplicacao.aspx?id=5118&origem=menu",
          icon: Icons.rocket_launch,
          color: MeireTheme.primaryColor,
        ),
        const SizedBox(height: 12),
        _buildMissionTarget(
          title: "Parcelamento MEI",
          desc: "Negociar dívidas e parcelamentos",
          url: "https://cav.receita.fazenda.gov.br/ecac/Aplicacao.aspx?id=134&origem=menu",
          icon: Icons.account_balance_wallet,
          color: Colors.blueGrey.shade800,
        ),
      ],
    );
  }

  Widget _buildMetricSummaryWidget(AsyncValue<DasnStats> statsAsync) {
    return statsAsync.when(
      data: (stats) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.amber.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.amber.shade200),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Valores para DASN $_selectedYear", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                _buildSmallYearToggle(),
              ],
            ),
            const Divider(height: 24),
            _buildValRow("Receita Bruta Total:", stats.total),
            _buildValRow("Receita Serviços:", stats.servicos),
          ],
        ),
      ),
      loading: () => const LinearProgressIndicator(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildSmallYearToggle() {
    return DropdownButton<int>(
      value: _selectedYear,
      underline: const SizedBox.shrink(),
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: MeireTheme.primaryColor),
      items: [DateTime.now().year - 1, DateTime.now().year - 2]
          .map((y) => DropdownMenuItem(value: y, child: Text(y.toString())))
          .toList(),
      onChanged: (val) { if (val != null) setState(() => _selectedYear = val); },
    );
  }

  Widget _buildValRow(String label, double val) {
    final rawVal = val.toStringAsFixed(2).replaceAll('.', ',');
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.black87)),
          Row(
            children: [
              Text(NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(val), style: const TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: rawVal));
                  HapticFeedback.mediumImpact();
                },
                child: const Icon(Icons.copy, size: 16, color: MeireTheme.accentColor),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMissionTarget({required String title, required String desc, required String url, required IconData icon, required Color color}) {
    return InkWell(
      onTap: () async {
        final uri = Uri.parse(url);
        await launchUrl(uri, mode: LaunchMode.inAppWebView);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(desc, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
          ],
        ),
      ),
    );
  }
}
