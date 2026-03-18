import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meire/core/services/pocketbase_service.dart';

/// Provider que busca as configurações personalizadas do usuário (MEI).
/// Alimenta os valores padrão de comissão e salão para novos lançamentos.
final settingsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final pb = ref.read(pbProvider);
  final userId = pb.authStore.record?.id;

  if (userId == null) return {'comissao': 0.60, 'salaoId': ''};

  try {
    // Busca os dados atualizados do usuário logado
    final user = await pb.collection('users').getOne(userId);
    
    return {
      'comissao': (user.data['comissao_padrao'] ?? 0.60).toDouble(),
      'salaoId': user.data['salao_padrao'] ?? '',
    };
  } catch (e) {
    // Fallback seguro se o PocketBase falhar ou o campo não existir
    return {'comissao': 0.60, 'salaoId': ''};
  }
});
