import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meiri/core/services/nbs_service.dart';

// Represents individual node from IBGE API
class NbsModel {
  final String id;
  final String nome;
  final String? pai;

  NbsModel({
    required this.id,
    required this.nome,
    this.pai,
  });

  factory NbsModel.fromJson(Map<String, dynamic> json) {
    return NbsModel(
      id: json['id']?.toString() ?? '',
      nome: json['nome']?.toString() ?? '',
      pai: json['pai']?.toString(),
    );
  }
}

// Provider that fetches and caches the list once
final nbsProvider = FutureProvider<List<NbsModel>>((ref) async {
  final service = NbsService();
  final data = await service.fetchNbsCodes();
  
  if (data.isEmpty) return [];

  return data.map((json) => NbsModel.fromJson(json)).toList();
});
