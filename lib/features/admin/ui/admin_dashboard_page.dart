import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meire/core/services/pocketbase_service.dart';
import 'package:meire/core/ui/theme.dart';
import 'package:pocketbase/pocketbase.dart';

import '../../auth/services/auth_service.dart';

final adminUsersProvider = FutureProvider.autoDispose<List<RecordModel>>((ref) async {
  final pb = ref.watch(pbProvider);
  
  try {
    final records = await pb.collection('users').getFullList(
      filter: 'status_registro = "aguardando_procuracao"',
      sort: '-created',
    );
    return records;
  } catch (e) {
    return [];
  }
});

class AdminDashboardPage extends ConsumerWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final usersAsync = ref.watch(adminUsersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Administração (SAID)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(adminUsersProvider),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authServiceProvider).logout();
              Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/hub'),
              icon: const Icon(Icons.business_center),
              label: const Text('Acessar Meu Painel MEI (Emissor)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 54),
                backgroundColor: MeireTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              "CLIENTES AGUARDANDO PROCURAÇÃO NO E-CAC",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: MeireTheme.accentColor,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            usersAsync.when(
              data: (users) {
                if (users.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? Colors.white10 : MeireTheme.iceGray),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.check_circle_outline, size: 48, color: Colors.green.withValues(alpha: 1.0)),
                        const SizedBox(height: 16),
                        const Text(
                          "Todos os clientes estão verificados.",
                          style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: users.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isDark ? Colors.white10 : MeireTheme.iceGray),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.person_outline, size: 32, color: isDark ? Colors.white54 : Colors.black54),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(user.getStringValue('name').toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                const SizedBox(height: 4),
                                Text("CNPJ: ${user.getStringValue('cnpj')}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                Text("E-mail: ${user.getStringValue('email')}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                              ],
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () async {
                              final scaffoldMsg = ScaffoldMessenger.of(context);
                              try {
                                await ref.read(pbProvider).collection('users').update(user.id, body: {
                                  'status_registro': 'verificado',
                                });
                                // ignore: unused_result
                                ref.refresh(adminUsersProvider);
                                scaffoldMsg.showSnackBar(
                                  const SnackBar(content: Text('Cliente liberado com sucesso!'), backgroundColor: Colors.green),
                                );
                              } catch (e) {
                                scaffoldMsg.showSnackBar(
                                  SnackBar(content: Text('Erro ao liberar cliente: $e'), backgroundColor: Colors.red),
                                );
                              }
                            },
                            icon: const Icon(Icons.check, size: 16),
                            label: const Text("Liberar"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              elevation: 0,
                            ),
                          )
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, stack) => Center(child: Text("Erro ao carregar clientes: $e")),
            )
          ],
        ),
      ),
    );
  }
}
