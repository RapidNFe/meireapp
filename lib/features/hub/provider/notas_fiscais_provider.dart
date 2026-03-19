import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../../../core/services/pocketbase_service.dart';
import 'dart:async';
import 'package:pocketbase/pocketbase.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class NotaFiscal {
  final String id;
  final String tomadorNome;
  final double valor;
  final String status;
  final String numeroNota;
  final DateTime created;

  NotaFiscal({
    required this.id,
    required this.tomadorNome,
    required this.valor,
    required this.status,
    required this.numeroNota,
    required this.created,
  });

  factory NotaFiscal.fromRecord(RecordModel record) {
    double parseValor(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      if (val is String) {
        final s = val.replaceAll(RegExp(r'[^0-9.]'), '');
        return double.tryParse(s) ?? 0.0;
      }
      return 0.0;
    }

    return NotaFiscal(
      id: record.id,
      tomadorNome: record.getStringValue('tomador_nome'),
      valor: parseValor(record.getStringValue('valor')),
      status: record.getStringValue('status').isEmpty ? 'processando' : record.getStringValue('status'),
      numeroNota: record.getStringValue('numero_nota'),
      created: (DateTime.tryParse(record.getStringValue('created')) ?? DateTime.now()).toLocal(),
    );
  }
}

final historicoNotasProvider = StreamProvider.autoDispose<List<NotaFiscal>>((ref) async* {
  final pb = ref.watch(pbProvider);
  final user = ref.watch(userProvider);

  if (user == null) {
    yield [];
    return;
  }

  Future<List<NotaFiscal>> fetchNotas() async {
    try {
      final records = await pb.collection('notas_fiscais').getFullList(
        sort: '-created',
        filter: 'user = "${user.id}"',
      );
      return records.map((r) => NotaFiscal.fromRecord(r)).toList();
    } catch (_) {
      return [];
    }
  }

  // 1. Initial Load
  yield await fetchNotas();

  // 2. Real-time Subscription
  final streamController = StreamController<List<NotaFiscal>>();
  
  pb.collection('notas_fiscais').subscribe('*', (e) async {
    final updatedList = await fetchNotas();
    if (!streamController.isClosed) {
      streamController.add(updatedList);
    }
    // Also invalidate the stats so the revenue cards update instantly
    ref.invalidate(revenueStatsProvider);
  });

  ref.onDispose(() {
    pb.collection('notas_fiscais').unsubscribe('*');
    streamController.close();
  });

  yield* streamController.stream;
});

class RevenueStats {
  final double annualTotal;
  final double currentMonthTotal;
  final double monthlyLimit;
  final double annualLimit;
  final double percentage;
  final double remaining;
  final List<NotaFiscal> allNotas;

  RevenueStats({
    required this.annualTotal,
    required this.currentMonthTotal,
    required this.monthlyLimit,
    required this.annualLimit,
    required this.percentage,
    required this.remaining,
    required this.allNotas,
  });

  factory RevenueStats.empty() => RevenueStats(
        annualTotal: 0,
        currentMonthTotal: 0,
        monthlyLimit: 6750.0,
        annualLimit: 81000.0,
        percentage: 0,
        remaining: 81000.0,
        allNotas: [],
      );
}

final revenueStatsProvider = FutureProvider<RevenueStats>((ref) async {
  // Mantém os dados em cache para velocidade máxima ao navegar entre abas
  ref.keepAlive();

  final pb = ref.watch(pbProvider);
  final user = ref.watch(userProvider);

  if (user == null) {
    return RevenueStats.empty();
  }

  try {
    // Busca todas as notas do usuário para garantir que não perdemos nenhum dado por falha no filtro do banco
    final records = await pb.collection('notas_fiscais').getFullList(
          sort: '-created',
          filter: 'user = "${user.id}"',
        );

    final List<NotaFiscal> notas = records.map((e) => NotaFiscal.fromRecord(e)).toList();

    double annualTotal = 0.0;
    double currentMonthTotal = 0.0;
    final now = DateTime.now();
    const annualLimit = 81000.0;

    for (var n in notas) {
      final status = n.status.toUpperCase();
      
      // SUCESSO: Incluímos todas as variações de "CONCLUÍDO" ou "EMITIDO"
      final isSucesso = 
          status == 'EMITIDA' || 
          status == 'AUTORIZADA' || 
          status == 'CONCLUIDA' || 
          status == 'AUTORIZADO' ||
          status == 'EMISSAO_CONCLUIDA';
          
      // Também contamos se estiver "PROCESSANDO", mas o ideal é só sucessos reais
      if (!isSucesso && status != 'PROCESSANDO') continue;

      final date = n.created;
      final val = n.valor;

      // Filtramos o ano atual e o mês atual
      if (date.year == now.year) {
        annualTotal += val;
        if (date.month == now.month) {
          currentMonthTotal += val;
        }
      }
    }

    return RevenueStats(
      annualTotal: annualTotal,
      currentMonthTotal: currentMonthTotal,
      monthlyLimit: 6750.0,
      annualLimit: annualLimit,
      percentage: (annualTotal / annualLimit).clamp(0.0, 1.0),
      remaining: (annualLimit - annualTotal).clamp(0.0, annualLimit),
      allNotas: notas,
    );
  } catch (e) {
    return RevenueStats.empty();
  }
});

class ImpostoEstimativa {
  final double faturamento;
  final double imposto;
  final String referencia;

  ImpostoEstimativa({
    required this.faturamento,
    required this.imposto,
    required this.referencia,
  });

  factory ImpostoEstimativa.empty() => ImpostoEstimativa(
        faturamento: 0,
        imposto: 0,
        referencia: "Indisponível",
      );

  factory ImpostoEstimativa.fromJson(Map<String, dynamic> json) => ImpostoEstimativa(
        faturamento: (json['faturamento'] ?? 0).toDouble(),
        imposto: (json['imposto'] ?? 0).toDouble(),
        referencia: json['referencia'] ?? '',
      );
}

final impostoEstimativaProvider = FutureProvider<ImpostoEstimativa>((ref) async {
  ref.keepAlive(); // Cacheia o resultado da estimativa
  final user = ref.watch(userProvider);

  if (user == null) {
    return ImpostoEstimativa.empty();
  }

  try {
    final url = '$meireApiUrl/api/impostos/estimativa/${user.id}';
    debugPrint('📡 Buscando impostos em: $url');
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );
    
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      // debugPrint('✅ Resumo Financeiro recebido: ${response.body}');
      debugPrint('✅ Resumo Financeiro recebido com sucesso.');
      return ImpostoEstimativa.fromJson(json);
    }
    
    debugPrint('⚠️ Erro no Servidor Node: ${response.statusCode}');
    return ImpostoEstimativa.empty();
  } catch (e) {
    debugPrint('💥 Falha ao conectar no gateway de impostos.');
    return ImpostoEstimativa.empty();
  }
});

class HistoricoMes {
  final String label;
  final double valor;

  HistoricoMes({required this.label, required this.valor});

  factory HistoricoMes.fromJson(Map<String, dynamic> json) => HistoricoMes(
        label: json['label'] ?? '',
        valor: (json['valor'] ?? 0).toDouble(),
      );
}

final historicoFaturamentoProvider = FutureProvider<List<HistoricoMes>>((ref) async {
  ref.keepAlive(); // Mantém o gráfico carregado instantaneamente
  final user = ref.watch(userProvider);

  if (user == null) return [];

  try {
    final url = '$meireApiUrl/api/faturamento/historico/${user.id}';
    debugPrint('📡 Buscando histórico em: $url');
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );
    
    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      debugPrint('✅ Histórico recebido: ${jsonList.length} meses');
      return jsonList.map((e) => HistoricoMes.fromJson(e)).toList();
    }
    
    debugPrint('⚠️ Erro no Histórico: ${response.statusCode}');
    return [];
  } catch (e) {
    debugPrint('💥 Falha ao buscar histórico no Node: $e');
    return [];
  }
});
