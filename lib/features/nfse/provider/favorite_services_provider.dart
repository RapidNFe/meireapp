import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

class FavoriteService {
  final String id;
  final String municipio;
  final String apelido;
  final String codigoTributacao;
  final String itemNbs;
  final String descricaoBase;

  FavoriteService({
    String? id,
    required this.municipio,
    required this.apelido,
    required this.codigoTributacao,
    required this.itemNbs,
    required this.descricaoBase,
  }) : id = id ?? const Uuid().v4();

  FavoriteService copyWith({
    String? municipio,
    String? apelido,
    String? codigoTributacao,
    String? itemNbs,
    String? descricaoBase,
  }) {
    return FavoriteService(
      id: id,
      municipio: municipio ?? this.municipio,
      apelido: apelido ?? this.apelido,
      codigoTributacao: codigoTributacao ?? this.codigoTributacao,
      itemNbs: itemNbs ?? this.itemNbs,
      descricaoBase: descricaoBase ?? this.descricaoBase,
    );
  }
}

class FavoriteServicesNotifier extends StateNotifier<List<FavoriteService>> {
  FavoriteServicesNotifier() : super([]) {
    _loadInitialMocks();
  }

  void _loadInitialMocks() {
    state = [
      FavoriteService(
        municipio: 'Goiânia/GO',
        apelido: 'PRESTAÇÃO DE SERVIÇO',
        codigoTributacao: '06.01.01 - Barbearia, cabeleireiros, manicuros, pedicuros e congêneres.',
        itemNbs: '126021000 - Serviços de cabeleireiros e barbeiros',
        descricaoBase: 'NOTA FISCAL REFERENTE A PRESTAÇÃO DE SERVIÇO;',
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

  void addService(FavoriteService service) {
    state = [...state, service];
  }

  void removeService(String id) {
    state = state.where((service) => service.id != id).toList();
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
  return FavoriteServicesNotifier();
});
