import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meiri/core/services/pocketbase_service.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:uuid/uuid.dart';

class FavoriteService {
  final String id;
  final String municipio;
  final String apelido;
  final String codigoTributacao;
  final String itemNbs;
  final String descricaoBase;
  final double? valorBase;
  final String? idClientePadrao;
  final bool? isNichoBeleza; // Para marcar se é o template de Salão Parceiro

  FavoriteService({
    String? id,
    required this.municipio,
    required this.apelido,
    required this.codigoTributacao,
    required this.itemNbs,
    required this.descricaoBase,
    this.valorBase,
    this.idClientePadrao,
    this.isNichoBeleza = false,
  }) : id = id ?? const Uuid().v4();

  FavoriteService copyWith({
    String? municipio,
    String? apelido,
    String? codigoTributacao,
    String? itemNbs,
    String? descricaoBase,
    double? valorBase,
    String? idClientePadrao,
    bool? isNichoBeleza,
  }) {
    return FavoriteService(
      id: id,
      municipio: municipio ?? this.municipio,
      apelido: apelido ?? this.apelido,
      codigoTributacao: codigoTributacao ?? this.codigoTributacao,
      itemNbs: itemNbs ?? this.itemNbs,
      descricaoBase: descricaoBase ?? this.descricaoBase,
      valorBase: valorBase ?? this.valorBase,
      idClientePadrao: idClientePadrao ?? this.idClientePadrao,
      isNichoBeleza: isNichoBeleza ?? this.isNichoBeleza,
    );
  }

  factory FavoriteService.fromRecord(RecordModel record) {
    return FavoriteService(
      id: record.id,
      municipio: record.getStringValue('municipio'),
      apelido: record.getStringValue('apelido'),
      codigoTributacao: record.getStringValue('codigo_tributacao'),
      itemNbs: record.getStringValue('item_nbs'),
      descricaoBase: record.getStringValue('descricao_padrao'),
      valorBase: record.getDoubleValue('valor_base'),
      idClientePadrao: record.getStringValue('id_cliente_padrao'),
      isNichoBeleza: record.getBoolValue('is_nicho_beleza'),
    );
  }
}

class FavoriteServicesNotifier extends StateNotifier<List<FavoriteService>> {
  final PocketBase _pb;
  final String? _userId;

  FavoriteServicesNotifier(this._pb, this._userId) : super([]) {
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    if (_userId == null) {
      _loadInitialMocks();
      return;
    }

    try {
      final records = await _pb.collection('servicos_favoritos').getFullList(
        filter: 'user = "$_userId"',
      );
      
      if (records.isEmpty) {
        _loadInitialMocks();
      } else {
        state = records.map((r) => FavoriteService.fromRecord(r)).toList();
      }
    } catch (e) {
      _loadInitialMocks();
    }
  }

  void _loadInitialMocks() {
    state = [
      FavoriteService(
        municipio: 'Goiânia/GO',
        apelido: 'COMISSÃO SALÃO (QUINZENA)',
        codigoTributacao: '06.01.01 - Barbearia, cabeleireiros, manicuros, pedicuros e congêneres.',
        itemNbs: '126021000 - Serviços de cabeleireiros e barbeiros',
        descricaoBase: 'Nota fiscal referente a serviços de estética e beleza (Salão Parceiro) prestados no período de {QUINZENA_PASSADA}.',
        isNichoBeleza: true,
      ),
      FavoriteService(
        municipio: 'São Paulo/SP',
        apelido: 'MANUTENÇÃO DE COMPUTADORES',
        codigoTributacao: '14.01 - Lubrificação, limpeza e manutenção de máquinas.',
        itemNbs: '126021000 - Serviços de manutenção de T.I',
        descricaoBase: 'MANUTENÇÃO PREVENTIVA E CORRETIVA DE EQUIPAMENTOS DE INFORMÁTICA;',
      ),
    ];
  }

  Future<void> addService(FavoriteService service) async {
    if (_userId == null) return;

    try {
      final body = {
        "user": _userId,
        "municipio": service.municipio,
        "apelido": service.apelido,
        "codigo_tributacao": service.codigoTributacao,
        "item_nbs": service.itemNbs,
        "descricao_padrao": service.descricaoBase,
        "valor_base": service.valorBase,
        "idClientePadrao": service.idClientePadrao,
        "is_nicho_beleza": service.isNichoBeleza,
      };

      final record = await _pb.collection('servicos_favoritos').create(body: body);
      final newService = FavoriteService.fromRecord(record);
      state = [...state, newService];
    } catch (e) {
      // Em caso de erro, adicionamos apenas ao estado local para feedback imediato
      state = [...state, service];
    }
  }

  Future<void> removeService(String id) async {
    state = state.where((service) => service.id != id).toList();
    
    try {
      await _pb.collection('servicos_favoritos').delete(id);
    } catch (_) {
      // Ignora erro na deleção
    }
  }
  
  FavoriteService? getServiceByApelido(String apelido) {
    try {
      return state.firstWhere((service) => service.apelido == apelido);
    } catch (_) {
      return null;
    }
  }
}

final favoriteServicesProvider = StateNotifierProvider<FavoriteServicesNotifier, List<FavoriteService>>((ref) {
  final pb = ref.watch(pbProvider);
  final user = ref.watch(userProvider);
  return FavoriteServicesNotifier(pb, user?.id);
});
