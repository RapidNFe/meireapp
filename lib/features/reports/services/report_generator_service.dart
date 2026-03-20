import 'package:flutter/foundation.dart';
import 'package:meire/features/hub/provider/notas_fiscais_provider.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:intl/intl.dart';

class ReportGeneratorService {
  final PocketBase _pb;

  ReportGeneratorService(this._pb);

  Future<RecordModel?> generateAndUploadReport({
    required String userId,
    required DateTime start,
    required DateTime end,
    required List<NotaFiscal> allNotas,
    required String userName,
    required String userCnpj,
  }) async {
    // Filtra as notas pelo período de COMPETÊNCIA real
    final filteredNotas = allNotas.where((n) {
      return n.competencia.isAfter(start.subtract(const Duration(minutes: 1))) &&
             n.competencia.isBefore(end.add(const Duration(days: 1)));
    }).toList();

    // TRAVA DE SEGURANÇA: Se não houver notas, não gera arquivo vazio
    if (filteredNotas.isEmpty) {
      throw Exception("Não existem notas fiscais emitidas neste período. Tente outro intervalo.");
    }

    double total = filteredNotas.fold(0, (sum, n) => sum + n.valor);

    final String periodoStr = 
        "${DateFormat('dd/MM/yyyy').format(start)} - ${DateFormat('dd/MM/yyyy').format(end)}";

    try {
      debugPrint('🚀 [Relatório] Iniciando Salvamento de Dados (Sem PDF)...');
      
      // 📦 Prepara o Body (Tudo precisa ser String no formato Multipart!)
      final Map<String, String> bodyBlindado = {
        'user_id': userId,
        'periodo': periodoStr,
        'valor_total': total.toString(), // Transformando o double em String para o Multipart
      };

      // 🎯 PASSO ÚNICO: Cria o registro com os dados
      // Removido o envio do arquivo PDF conforme solicitado pelo usuário.
      final record = await _pb.collection('relatorios_faturamento').create(
        body: bodyBlindado,
      );

      debugPrint('✅ [Relatório] Dados Salvos com Sucesso! ID: ${record.id}');
      return record;

    } catch (e) {
      debugPrint('❌ [Relatório] Falha Crítica ao Salvar Dados: $e');
      rethrow; 
    }
  }
}

