import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meire/core/services/pocketbase_service.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:uuid/uuid.dart';

class FavoriteService {
  final String id;
  final String idMunicipio;
  final String apelido;
  final String codigoNational;
  final String descricaoBase;
  final double? valorBase;
  final String? idClientePadrao;
  final bool issRetido;
  final String userId;

  FavoriteService({
    String? id,
    required this.idMunicipio,
    required this.apelido,
    required this.codigoNational,
    required this.descricaoBase,
    this.valorBase,
    this.idClientePadrao,
    this.issRetido = false,
    required this.userId,
  }) : id = id ?? const Uuid().v4();

  FavoriteService copyWith({
    String? idMunicipio,
    String? apelido,
    String? codigoNational,
    String? descricaoBase,
    double? valorBase,
    String? idClientePadrao,
    bool? issRetido,
    String? userId,
  }) {
    return FavoriteService(
      id: id,
      idMunicipio: idMunicipio ?? this.idMunicipio,
      apelido: apelido ?? this.apelido,
      codigoNational: codigoNational ?? this.codigoNational,
      descricaoBase: descricaoBase ?? this.descricaoBase,
      valorBase: valorBase ?? this.valorBase,
      idClientePadrao: idClientePadrao ?? this.idClientePadrao,
      issRetido: issRetido ?? this.issRetido,
      userId: userId ?? this.userId,
    );
  }

  factory FavoriteService.fromRecord(RecordModel record) {
    return FavoriteService(
      id: record.id,
      idMunicipio: record.getStringValue('id_municipio'),
      apelido: record.getStringValue('apelido'),
      codigoNational: record.getStringValue('codigo_national'),
      descricaoBase: record.getStringValue('descricao_padrao'),
      valorBase: record.getDoubleValue('valor_base'),
      idClientePadrao: record.getStringValue('id_cliente_padrao'),
      issRetido: record.getBoolValue('iss_retido'),
      userId: record.getStringValue('user_id'),
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
        idMunicipio: 'Goiânia/GO',
        apelido: 'SERVIÇOS GERAIS MEI',
        codigoNational: '06.01.01',
        descricaoBase: 'Nota fiscal referente a serviços prestados no período de {QUINZENA_PASSADA}.',
        userId: _userId ?? 'mock',
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
        "codigo_national": service.codigoNational,
        "descricao_padrao": service.descricaoBase,
        "valor_base": service.valorBase,
        "id_cliente_padrao": service.idClientePadrao,
        "iss_retido": service.issRetido,
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
