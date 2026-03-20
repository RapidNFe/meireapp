import 'package:pocketbase/pocketbase.dart';

class ClientModel {
  final String id;
  final String cnpj;
  final String razaoSocial;
  final String apelido;
  final String email;
  final String cep;
  final String logradouro;
  final String numero;
  final String bairro;
  final String municipioIbge;
  final String cidadeNome;
  final String uf;

  ClientModel({
    required this.id,
    required this.cnpj,
    required this.razaoSocial,
    required this.apelido,
    required this.email,
    this.cep = '',
    this.logradouro = '',
    this.numero = '',
    this.bairro = '',
    this.municipioIbge = '',
    this.cidadeNome = '',
    this.uf = '',
  });

  factory ClientModel.fromRecord(RecordModel record) {
    return ClientModel(
      id: record.id,
      cnpj: record.getStringValue('cnpj'),
      razaoSocial: record.getStringValue('razao_social'),
      apelido: record.getStringValue('apelido'),
      email: record.getStringValue('email'),
      cep: record.getStringValue('cep'),
      logradouro: record.getStringValue('logradouro'),
      numero: record.getStringValue('numero'),
      bairro: record.getStringValue('bairro'),
      municipioIbge: record.getStringValue('municipio_ibge'),
      cidadeNome: record.getStringValue('cidade_nome'),
      uf: record.getStringValue('uf'),
    );
  }
}
