import 'package:flutter/foundation.dart';
import 'package:meire/core/services/pocketbase_service.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DasReminderService {
  final PocketBase pb;

  DasReminderService(this.pb);

  Future<void> checkAndNotify(String userId) async {
    final now = DateTime.now();
    final day = now.day;
    final String monthYear = "${now.year}-${now.month.toString().padLeft(2, '0')}";

    // Regras: dia 13 (7 dias antes do dia 20) e dia 19 (1 dia antes)
    if (day != 13 && day != 19) return;

    final String title = (day == 19) 
        ? "Seu DAS vence amanhã!" 
        : "Seu DAS vence em 7 dias.";
    
    try {
      // Usamos o título + mês/ano como chave de busca num filtro rápido
      final String filter = 'user_id = "$userId" && titulo = "$title" && created >= "$monthYear-01"';
      
      final existing = await pb.collection('notificacoes').getList(
        page: 1,
        perPage: 1,
        filter: filter,
      );

      if (existing.totalItems == 0) {
        await pb.collection('notificacoes').create(body: {
          'user_id': userId,
          'titulo': title,
          'mensagem': (day == 19) 
              ? "Lembre-se de pagar o seu imposto MEI até amanhã para evitar multas e juros." 
              : "O vencimento do seu DAS está chegando. Organize o seu faturamento para o pagamento em dia.",
          'tipo': 'fiscal',
          'lida': false,
          'acao_rota': '',
        });
        debugPrint("🔔 Notificação de DAS enviada com sucesso para o dia $day");
      }
    } catch (e) {
      debugPrint("❌ Erro ao processar lembrete de DAS automático: $e");
    }
  }
}

final dasReminderServiceProvider = Provider<DasReminderService>((ref) {
  final pb = ref.watch(pbProvider);
  return DasReminderService(pb);
});
