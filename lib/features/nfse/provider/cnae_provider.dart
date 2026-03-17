import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meire/core/services/cnae_service.dart';

final cnaeProvider = FutureProvider<List<Map<String, String>>>((ref) async {
  final service = CnaeService();
  return await service.loadCnaes();
});
