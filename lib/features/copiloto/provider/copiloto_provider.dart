import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/pocketbase_service.dart';
import '../../auth/services/auth_service.dart';

class DasnStats {
  final double servicos;
  final double comercio; // Atualmente 0, focado em NFSe
  final double total;
  final int ano;

  DasnStats({
    required this.servicos,
    required this.comercio,
    required this.total,
    required this.ano,
  });

  factory DasnStats.empty(int ano) => DasnStats(
        servicos: 0,
        comercio: 0,
        total: 0,
        ano: ano,
      );
}

final dasnCopilotoProvider = FutureProvider.family<DasnStats, int>((ref, ano) async {
  final pb = ref.watch(pbProvider);
  final authService = ref.watch(authServiceProvider);
  final user = authService.currentUser;

  if (user == null) return DasnStats.empty(ano);

  try {
    // Busca todas as notas do ano solicitado
    final records = await pb.collection('notas_fiscais').getFullList(
          filter: 'user = "${user.id}" && created >= "$ano-01-01 00:00:00" && created <= "$ano-12-31 23:59:59"',
        );

    double servicos = 0.0;
    
    for (var r in records) {
      final status = r.getStringValue('status').toLowerCase();
      if (status != 'emitida' && status != 'processando') continue;
      
      final val = r.getDoubleValue('valor');
      servicos += val;
    }

    return DasnStats(
      servicos: servicos,
      comercio: 0.0,
      total: servicos,
      ano: ano,
    );
  } catch (e) {
    return DasnStats.empty(ano);
  }
});
