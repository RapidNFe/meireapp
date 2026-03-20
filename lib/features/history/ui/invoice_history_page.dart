import 'package:flutter/material.dart';
import 'package:meire/core/ui/theme.dart';
import 'package:meire/features/history/models/invoice_model.dart';
import 'package:meire/features/history/ui/widgets/invoice_list_tile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meire/features/hub/provider/notas_fiscais_provider.dart';

class InvoiceHistoryPage extends ConsumerStatefulWidget {
  const InvoiceHistoryPage({super.key});

  @override
  ConsumerState<InvoiceHistoryPage> createState() => _InvoiceHistoryPageState();
}

class _InvoiceHistoryPageState extends ConsumerState<InvoiceHistoryPage> {
  String _searchQuery = '';
  int _selectedFilterIndex = 0; // 0: Todos, 1: Mês Atual, 2: Últimos 3 Meses

  List<InvoiceModel> _getFilteredInvoices(List<InvoiceModel> allInvoices) {
    return allInvoices.where((invoice) {
      // 1. Text Search Filter
      final matchesSearch = invoice.clientName
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          invoice.id.toLowerCase().contains(_searchQuery.toLowerCase());

      if (!matchesSearch) return false;

      // 2. Period Filter
      final now = DateTime.now();
      if (_selectedFilterIndex == 1) {
        // Mês Atual
        return invoice.issueDate.month == now.month &&
            invoice.issueDate.year == now.year;
      } else if (_selectedFilterIndex == 2) {
        // Últimos 3 Meses
        final threeMonthsAgo = DateTime(now.year, now.month - 3, now.day);
        return invoice.issueDate.isAfter(threeMonthsAgo);
      }

      return true; // Todos
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final revenueAsync = ref.watch(revenueStatsProvider);
    final stats = revenueAsync.valueOrNull;

    final allInvoices = stats?.allNotas.map((n) {
          return InvoiceModel(
            id: n.id, // pocketbase id
            clientName: n.tomadorNome,
            clientCnpj: n.tomadorCnpj ?? '',
            amount: n.valor,
            issueDate: n.competencia,
            status: n.status,
            chaveAcesso: n.chaveAcesso, // Usando o link real da nota para o PDF
          );
        }).toList() ??
        [];

    final filteredInvoices = _getFilteredInvoices(allInvoices);

    return Scaffold(
      backgroundColor: Colors.transparent, // Inherit from Dashboard
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          _buildFilters(),
          Expanded(
            child: filteredInvoices.isEmpty
                ? _buildEmptyState()
                : _buildInvoiceList(filteredInvoices),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Histórico de Notas",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: MeireTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Gerencie todas as NFS-e emitidas.",
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          TextField(
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: const InputDecoration(
              hintText: "Buscar por cliente ou número da NF",
              prefixIcon: Icon(Icons.search, color: Colors.grey),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
                borderSide: BorderSide(color: MeireTheme.iceGray),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
                borderSide: BorderSide(color: MeireTheme.iceGray),
              ),
              contentPadding: EdgeInsets.symmetric(vertical: 0),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          _buildFilterChip("Todos", 0),
          const SizedBox(width: 8),
          _buildFilterChip("Mês Atual", 1),
          const SizedBox(width: 8),
          _buildFilterChip("Últimos 3 Meses", 2),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, int index) {
    final isSelected = _selectedFilterIndex == index;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) setState(() => _selectedFilterIndex = index);
      },
      selectedColor: MeireTheme.primaryColor,
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : MeireTheme.primaryColor,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(
          color: isSelected ? MeireTheme.primaryColor : MeireTheme.iceGray),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  Widget _buildInvoiceList(List<InvoiceModel> invoices) {
    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: invoices.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final invoice = invoices[index];
        return InvoiceListTile(
          invoice: invoice,
          onTap: () {
            if (invoice.chaveAcesso == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Esta é uma nota antiga e não possui PDF oficial disponível.')),
              );
              return;
            }
            Navigator.pushNamed(
              context,
              '/pdf_viewer',
              arguments: invoice.chaveAcesso,
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined,
              size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            "Nenhuma nota encontrada",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF757575), // Colors.grey.shade600
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Tente ajustar os filtros ou termo de busca.",
            style: TextStyle(color: Color(0xFF9E9E9E)), // Colors.grey.shade500
          ),
        ],
      ),
    );
  }
}
