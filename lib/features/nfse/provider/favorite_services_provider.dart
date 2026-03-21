import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meire/core/services/pocketbase_service.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:uuid/uuid.dart';

class FavoriteService {
  final String id;
  final String idMunicipio;
  final String apelido;
  final String codigoNacional;
  final String descricaoBase;
  final double? valorBase;
  final String? idClientePadrao;
  final bool issRetido;
  final String userId;
  final String? itemNbs; // Novo!
  final bool favorito;

  FavoriteService({
    String? id,
    required this.idMunicipio,
    required this.apelido,
    required this.codigoNacional,
    required this.descricaoBase,
    this.valorBase,
    this.idClientePadrao,
    this.issRetido = false,
    required this.userId,
    this.itemNbs, // Novo!
    this.favorito = false,
  }) : id = id ?? const Uuid().v4();

  FavoriteService copyWith({
    String? idMunicipio,
    String? apelido,
    String? codigoNacional,
    String? descricaoBase,
    double? valorBase,
    String? idClientePadrao,
    bool? issRetido,
    String? userId,
    String? itemNbs, // Novo!
    bool? favorito,
  }) {
    return FavoriteService(
      id: id,
      idMunicipio: idMunicipio ?? this.idMunicipio,
      apelido: apelido ?? this.apelido,
      codigoNacional: codigoNacional ?? this.codigoNacional,
      descricaoBase: descricaoBase ?? this.descricaoBase,
      valorBase: valorBase ?? this.valorBase,
      idClientePadrao: idClientePadrao ?? this.idClientePadrao,
      issRetido: issRetido ?? this.issRetido,
      userId: userId ?? this.userId,
      itemNbs: itemNbs ?? this.itemNbs,
      favorito: favorito ?? this.favorito,
    );
  }

  factory FavoriteService.fromRecord(RecordModel record) {
    return FavoriteService(
      id: record.id,
      idMunicipio: record.getStringValue('id_municipio'),
      apelido: record.getStringValue('apelido'),
      codigoNacional: record.getStringValue('codigo_nacional'),
      descricaoBase: record.getStringValue('descricao_padrao'),
      valorBase: record.getDoubleValue('valor_base'),
      idClientePadrao: record.getStringValue('id_cliente_padrao'),
      issRetido: record.getBoolValue('iss_retido'),
      userId: record.getStringValue('user_id'),
      itemNbs: record.getStringValue('item_nbs'),
      favorito: record.getBoolValue('favorito'),
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
        filter: 'user_id = "$_userId"',
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
        idMunicipio: 'Goiânia/GO',
        apelido: 'SERVIÇOS GERAIS MEI',
        codigoNacional: '06.01.01',
        descricaoBase: 'Nota fiscal referente a serviços prestados no período de {QUINZENA_PASSADA}.',
        userId: _userId ?? 'mock',
        favorito: true,
      ),
    ];
  }

  Future<void> addService(FavoriteService service) async {
    if (_userId == null) return;

    try {
      final body = {
        "user_id": _userId,
        "id_municipio": service.idMunicipio,
        "apelido": service.apelido,
        "codigo_nacional": service.codigoNacional,
        "descricao_padrao": service.descricaoBase,
        "valor_base": service.valorBase,
        "id_cliente_padrao": service.idClientePadrao,
        "iss_retido": false, // MEI is exempt
        "item_nbs": service.itemNbs,
        "favorito": service.favorito,
        "regime_especial_tributacao": 6, // 6 = MEI
        "exigibilidade_iss": 1, // 1 = Exigível do Simples/MEI
      };

      final record = await _pb.collection('servicos_favoritos').create(body: body);
      final newService = FavoriteService.fromRecord(record);
      state = [...state, newService];
    } catch (e) {
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
