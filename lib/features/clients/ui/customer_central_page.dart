import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meire/core/ui/theme.dart';
import 'package:meire/features/clients/provider/client_provider.dart';

class CustomerCentralPage extends ConsumerWidget {
  const CustomerCentralPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: MeireTheme.primaryColor,
        foregroundColor: Colors.white,
        onPressed: () => Navigator.pushNamed(context, '/add_client'),
        icon: const Icon(Icons.add),
        label: const Text('Novo Cliente'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchHeader(context, ref),
            Expanded(
              child: _buildClientList(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchHeader(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: MeireTheme.iceGray)),
      ),
      child: TextField(
        onChanged: (val) => ref.read(clienteSearchProvider.notifier).state = val,
        decoration: InputDecoration(
          hintText: 'Buscar por nome, CPF/CNPJ...',
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: MeireTheme.iceGray,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }

  Widget _buildClientList(BuildContext context, WidgetRef ref) {
    final filteredClients = ref.watch(filteredClientesProvider);
    final asyncClients = ref.watch(clientListProvider);

    if (asyncClients.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (asyncClients.hasError) {
       return Center(child: Text('Erro ao carregar clientes: ${asyncClients.error}'));
    }

    if (filteredClients.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              "Nenhum cliente encontrado.",
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
      itemCount: filteredClients.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final client = filteredClients[index];
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: MeireTheme.iceGray),
          ),
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: MeireTheme.accentColor.withValues(alpha: 0.1),
                  child: Text(
                    client.apelido.isNotEmpty ? client.apelido.substring(0, 1).toUpperCase() : 'C',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: MeireTheme.accentColor),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        client.apelido,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        client.razaoSocial,
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'CNPJ: ${client.cnpj}',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        // O "Atalho do Dinheiro" - navegar para NfseFormPage com dados preenchidos
                        Navigator.pushNamed(context, '/nfse_form', arguments: client);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: MeireTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        elevation: 0,
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.request_quote_outlined, size: 16),
                          SizedBox(width: 6),
                          Text('Emitir', style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
