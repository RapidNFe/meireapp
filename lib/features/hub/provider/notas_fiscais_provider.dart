import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/pocketbase_service.dart';
import '../../auth/services/auth_service.dart';
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
      created: DateTime.tryParse(record.getStringValue('created')) ?? DateTime.now(),
    );
  }
}

final historicoNotasProvider = StreamProvider.autoDispose<List<NotaFiscal>>((ref) async* {
  final pb = ref.watch(pbProvider);
  final authService = ref.watch(authServiceProvider);
  final user = authService.currentUser;

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
  final List<Map<String, dynamic>> allNotas;

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
  final pb = ref.watch(pbProvider);
  final authService = ref.watch(authServiceProvider);

  if (authService.currentUser == null) {
    return RevenueStats.empty();
  }

  try {
    final records = await pb.collection('notas_fiscais').getFullList(
          sort: '-created',
          filter: 'user = "${authService.currentUser!.id}"',
        );

    final notas = records.map((e) => e.toJson()).toList();

    double annualTotal = 0.0;
    double currentMonthTotal = 0.0;
    final now = DateTime.now();
    const annualLimit = 81000.0;

    double parseValor(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      if (val is String) {
        final s = val.replaceAll(RegExp(r'[^0-9.]'), '');
        return double.tryParse(s) ?? 0.0;
      }
      return 0.0;
    }

    DateTime parseDate(dynamic dateStr) {
      if (dateStr == null) return DateTime.now();
      return DateTime.tryParse(dateStr.toString()) ?? DateTime.now();
    }

    for (var n in notas) {
      final date =
          parseDate(n['created'] ?? n['data_competencia'] ?? n['emissao']);
      final valStr = n['valor_servico'] ?? n['valor'] ?? '0';
      final val = parseValor(valStr.toString().replaceAll(',', '.'));

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
  final authService = ref.watch(authServiceProvider);
  final user = authService.currentUser;

  if (user == null) {
    return ImpostoEstimativa.empty();
  }

  try {
    final response = await http.get(Uri.parse('http://127.0.0.1:3000/api/impostos/estimativa/${user.id}'));
    
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return ImpostoEstimativa.fromJson(json);
    }
    
    return ImpostoEstimativa.empty();
  } catch (e) {
    print('Erro buscando estimativa de imposto: $e');
    return ImpostoEstimativa.empty();
  }
});
