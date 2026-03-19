import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meire/core/services/pocketbase_service.dart';
import 'package:pocketbase/pocketbase.dart';

class SalaoParceiroModel {
  final String id;
  final String cnpj;
  final String razaoSocial;
  final String nomeFantasia;
  final double comissaoPadrao;
  final double valorCotaParte;

  SalaoParceiroModel({
    required this.id,
    required this.cnpj,
    required this.razaoSocial,
    required this.nomeFantasia,
    required this.comissaoPadrao,
    required this.valorCotaParte,
  });

  factory SalaoParceiroModel.fromRecord(RecordModel record) {
    return SalaoParceiroModel(
      id: record.id,
      cnpj: record.getStringValue('cnpj'),
      razaoSocial: record.getStringValue('razao_social'),
      nomeFantasia: record.getStringValue('nome_fantasia'),
      comissaoPadrao: record.getDoubleValue('comissao_padrao'),
      valorCotaParte: record.getDoubleValue('valor_cota_parte'),
    );
  }
}

final salaoConfigProvider = FutureProvider<SalaoParceiroModel?>((ref) async {
  final pb = ref.watch(pbProvider);
  final userId = pb.authStore.record?.id;
  if (userId == null) return null;

  try {
    final record = await pb.collection('salao_parceiro').getFirstListItem('user_id = "$userId"');
    return SalaoParceiroModel.fromRecord(record);
  } catch (e) {
    if (e.toString().contains('404')) return null;
    rethrow;
  }
});

class SalaoConfigNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref ref;
  SalaoConfigNotifier(this.ref) : super(const AsyncValue.data(null));

  Future<void> saveSalao({
    required String cnpj,
    required String razaoSocial,
    required String nomeFantasia,
    required double comissao,
    required double cotaParte,
  }) async {
    state = const AsyncValue.loading();
    try {
      final pb = ref.read(pbProvider);
      final userId = pb.authStore.record?.id;
      if (userId == null) throw Exception('Usuário não logado');

      final body = {
        'cnpj': cnpj.replaceAll(RegExp(r'\D'), ''),
        'razao_social': razaoSocial,
        'nome_fantasia': nomeFantasia,
        'comissao_padrao': comissao,
        'valor_cota_parte': cotaParte,
        'user_id': userId,
      };

      try {
        final existing = await pb.collection('salao_parceiro').getFirstListItem('user_id = "$userId"');
        await pb.collection('salao_parceiro').update(existing.id, body: body);
      } catch (e) {
        if (e.toString().contains('404')) {
          await pb.collection('salao_parceiro').create(body: body);
        } else {
          rethrow;
        }
      }

      ref.invalidate(salaoConfigProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final salaoConfigNotifierProvider = StateNotifierProvider<SalaoConfigNotifier, AsyncValue<void>>((ref) {
  return SalaoConfigNotifier(ref);
});
