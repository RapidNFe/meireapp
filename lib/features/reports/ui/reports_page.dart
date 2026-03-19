import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meire/core/ui/theme.dart';
import 'package:meire/core/services/pocketbase_service.dart';
import 'package:intl/intl.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:meire/features/reports/services/report_generator_service.dart';
import 'package:meire/features/hub/provider/notas_fiscais_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class ReportItem {
  final String id;
  final String periodo;
  final double valorTotal;
  final String pdfUrl;
  final DateTime created;

  ReportItem({
    required this.id,
    required this.periodo,
    required this.valorTotal,
    required this.pdfUrl,
    required this.created,
  });

  factory ReportItem.fromRecord(RecordModel record, String baseUrl) {
    return ReportItem(
      id: record.id,
      periodo: record.getStringValue('periodo'),
      valorTotal: record.getDoubleValue('valor_total'),
      pdfUrl: "$baseUrl/api/files/${record.collectionId}/${record.id}/${record.getStringValue('arquivo_pdf')}",
      created: DateTime.tryParse(record.getStringValue('created')) ?? DateTime.now(),
    );
  }
}

final generatedReportsProvider = FutureProvider.autoDispose<List<ReportItem>>((ref) async {
  final pb = ref.watch(pbProvider);
  final user = ref.watch(userProvider);
  if (user == null) return [];

  final records = await pb.collection('relatorios_faturamento').getFullList(
    filter: 'user_id = "${user.id}"',
    sort: '-created',
  );

  return records.map((r) => ReportItem.fromRecord(r, pb.baseURL)).toList();
});

class ReportsPage extends ConsumerStatefulWidget {
  const ReportsPage({super.key});

  @override
  ConsumerState<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends ConsumerState<ReportsPage> {
  DateTimeRange? _selectedDateRange;
  bool _isGenerating = false;

  void _showDatePicker() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      locale: const Locale("pt", "BR"),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: MeireTheme.primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: MeireTheme.primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDateRange = picked);
    }
  }

  void _generateReport() async {
    if (_selectedDateRange == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecione um período primeiro.')),
      );
      return;
    }

    final user = ref.read(userProvider);
    final pb = ref.read(pbProvider);
    final revenueStats = ref.read(revenueStatsProvider).value;

    if (user == null || revenueStats == null) return;

    setState(() => _isGenerating = true);
    
    try {
      final generator = ReportGeneratorService(pb);
      
      // Utilizamos a lista de notas já tipada do provider
      final List<NotaFiscal> notasList = revenueStats.allNotas;

      final result = await generator.generateAndUploadReport(
        userId: user.id,
        userName: user.getStringValue('name'),
        userCnpj: user.getStringValue('cnpj'),
        start: _selectedDateRange!.start,
        end: _selectedDateRange!.end,
        allNotas: notasList,
      );

      if (result != null && mounted) {
        ref.invalidate(generatedReportsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Relatório Gerado com Sucesso!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao gerar: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportsAsync = ref.watch(generatedReportsProvider);

    return Scaffold(
      backgroundColor: MeireTheme.iceGray,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 160.0,
            floating: false,
            pinned: true,
            backgroundColor: MeireTheme.primaryColor,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('Central de Relatórios', 
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              background: Stack(
                fit: StackFit.expand,
                children: [
                   Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                        colors: [MeireTheme.primaryColor, Color(0xFF0D2A26)],
                      ),
                    ),
                  ),
                  Positioned(
                    right: -20,
                    top: -20,
                    child: Opacity(
                      opacity: 0.25, // Aumentado de 0.1 para melhor visibilidade
                      child: SvgPicture.asset(
                        'assets/images/logo.svg',
                        width: 200,
                        colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFilterSection(),
                  const SizedBox(height: 32),
                  const Text(
                    "Histórico de Relatórios",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: MeireTheme.primaryColor),
                  ),
                  const SizedBox(height: 16),
                  
                  reportsAsync.when(
                    data: (reports) => reports.isEmpty 
                        ? _buildEmptyState()
                        : ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: reports.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) => _buildReportCard(reports[index]),
                          ),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, __) => Text('Erro ao carregar: $e'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(ReportItem report) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MeireTheme.iceGray),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: MeireTheme.primaryColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.description_rounded, color: MeireTheme.primaryColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(report.periodo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(
                  "Total: R\$ ${NumberFormat("#,##0.00", "pt_BR").format(report.valorTotal)}",
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => launchUrl(Uri.parse(report.pdfUrl)),
            icon: const Icon(Icons.download_for_offline_outlined, color: MeireTheme.primaryColor),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.tune_rounded, color: MeireTheme.accentColor),
              SizedBox(width: 12),
              Text("Configurar Relatório", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 24),
          InkWell(
            onTap: _showDatePicker,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: MeireTheme.iceGray),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.date_range_outlined, color: Colors.grey),
                  const SizedBox(width: 12),
                  Text(
                    _selectedDateRange == null
                        ? "Selecionar Período"
                        : "${DateFormat('dd/MM/yyyy').format(_selectedDateRange!.start)} - ${DateFormat('dd/MM/yyyy').format(_selectedDateRange!.end)}",
                    style: TextStyle(
                      color: _selectedDateRange == null ? Colors.grey : MeireTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isGenerating ? null : _generateReport,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 54),
              backgroundColor: MeireTheme.primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: _isGenerating
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Text("Gerar PDF Inteligente", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: MeireTheme.iceGray),
      ),
      child: const Column(
        children: [
          Icon(Icons.analytics_outlined, size: 64, color: MeireTheme.iceGray),
          SizedBox(height: 24),
          Text("Sem relatórios no período", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          SizedBox(height: 8),
          Text(
            "Utilize os filtros acima para gerar um novo relatório personalizado.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
