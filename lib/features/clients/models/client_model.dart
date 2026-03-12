import 'package:pocketbase/pocketbase.dart';

class ClientModel {
  final String id;
  final String cnpj;
  final String razaoSocial;
  final String apelido;
  final String email;

  ClientModel({
    required this.id,
    required this.cnpj,
    required this.razaoSocial,
    required this.apelido,
    required this.email,
  });

  factory ClientModel.fromRecord(RecordModel record) {
    return ClientModel(
      id: record.id,
      cnpj: record.getStringValue('cnpj'),
      razaoSocial: record.getStringValue('razao_social'),
      apelido: record.getStringValue('apelido'),
      email: record.getStringValue('email'),
    );
  }
}
