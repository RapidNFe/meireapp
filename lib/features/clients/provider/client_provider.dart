import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meiri/core/services/pocketbase_service.dart';
import 'package:meiri/features/clients/models/client_model.dart';
import 'package:pocketbase/pocketbase.dart';

final clientListProvider = FutureProvider.autoDispose<List<ClientModel>>((ref) async {
  final pb = ref.watch(pbProvider);
  if (!pb.authStore.isValid) return [];

  final userId = pb.authStore.record?.id;
  if (userId == null) return [];

  try {
    final records = await pb.collection('clientes_tomadores').getFullList(
      filter: 'user = "$userId"',
      sort: 'apelido',
    );
    return records.map((r) => ClientModel.fromRecord(r)).toList();
  } catch (e) {
    if (e is ClientException && e.statusCode == 404) {
       // Collection not found, meaning it's not created yet or empty
       return [];
    }
    rethrow;
  }
});

final clienteSearchProvider = StateProvider<String>((ref) => '');

final filteredClientesProvider = Provider<List<ClientModel>>((ref) {
  final allClientes = ref.watch(clientListProvider).asData?.value ?? [];
  final searchTerm = ref.watch(clienteSearchProvider).toLowerCase();

  if (searchTerm.isEmpty) return allClientes;

  return allClientes.where((cliente) {
    return cliente.apelido.toLowerCase().contains(searchTerm) ||
           cliente.razaoSocial.toLowerCase().contains(searchTerm) ||
           cliente.cnpj.contains(searchTerm);
  }).toList();
});
