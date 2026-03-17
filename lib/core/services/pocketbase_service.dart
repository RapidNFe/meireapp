import 'package:flutter/foundation.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'dart:convert';

// Secure storage for tokens
const _storage = FlutterSecureStorage();
const _authKey = 'pb_auth';

class SecureAuthStore extends AuthStore {
  Future<void> init() async {
    try {
      final jsonStr = await _storage.read(key: _authKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        if (jsonStr.startsWith('{')) {
          final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
          final token = decoded['token'] as String?;
          final modelData = decoded['model'];
          if (token != null) {
            final parsedModel = modelData != null 
                ? RecordModel(Map<String, dynamic>.from(modelData as Map)) 
                : null;
            super.save(token, parsedModel);
          }
        } else {
          // Retorno de compatibilidade (token simples antigo)
          super.save(jsonStr, null);
        }
      }
    } catch (e) {
      debugPrint('Não foi possível ler o armazenamento seguro: $e');
    }
  }

  @override
  void save(String newToken, dynamic newRecord) {
    super.save(newToken, newRecord);
    
    dynamic modelData;
    if (newRecord is RecordModel) {
      modelData = newRecord.toJson();
    } else if (newRecord != null) {
      try {
        modelData = (newRecord as dynamic).toJson();
      } catch (_) {
        modelData = newRecord;
      }
    }

    final dataStr = jsonEncode({
      'token': newToken,
      'model': modelData,
    });
    
    _storage.write(key: _authKey, value: dataStr);
  }

  @override
  void clear() {
    super.clear();
    _storage.delete(key: _authKey);
  }
}

// Configuração de Ambientes
const String _prodUrl = 'https://api.meireapp.com.br';
const String _devApiUrl = 'http://127.0.0.1:3000'; // Gateway Inteligente (Node)

// Em desenvolvimento, apontamos TUDO para o Gateway (3000) para testar o Proxy/CORS localmente
// Em produção, apontamos para o domínio oficial que faz o roteamento
const String meiriPbUrl = kDebugMode ? _devApiUrl : _prodUrl;
const String meiriApiUrl = kDebugMode ? _devApiUrl : _prodUrl;

// Retrocompatibilidade
const String meiriBaseUrl = meiriPbUrl;

// Create the global PocketBase client instance with secure storage
final pocketBaseAuthStore = SecureAuthStore();
final pb = PocketBase(meiriBaseUrl, authStore: pocketBaseAuthStore);

// Create a provider for easier injection
final pbProvider = Provider<PocketBase>((ref) => pb);

// Stream provider that yields the AuthStoreEvent whenever authentication changes
final pbAuthChangeProvider = StreamProvider<AuthStoreEvent>((ref) {
  return pb.authStore.onChange;
});

// Provider reativo do Usuário Logado - ESSENCIAL PARA REATIVIDADE DO APP
final userProvider = Provider<RecordModel?>((ref) {
  // Observa mudanças no estado de autenticação para invalidar este provider
  ref.watch(pbAuthChangeProvider);
  return pb.authStore.record;
});
