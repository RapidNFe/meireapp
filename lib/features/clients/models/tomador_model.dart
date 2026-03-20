import 'package:pocketbase/pocketbase.dart';

class TomadorModel {
  final String id;
  final String cnpj;
  final String razaoSocial;
  final String? nomeFantasia;
  final String? apelido;
  final String? cnae;
  final String? cnaeDescricao;
  final bool isSalaoParceiro;
  final String cep;
  final String logradouro;
  final String numero;
  final String bairro;
  final String municipioIbge;
  final String cidadeNome;
  final String uf;
  final String email;

  TomadorModel({
    required this.id,
    required this.cnpj,
    required this.razaoSocial,
    this.nomeFantasia,
    this.apelido,
    this.cnae,
    this.cnaeDescricao,
    this.isSalaoParceiro = false,
    this.cep = '',
    this.logradouro = '',
    this.numero = '',
    this.bairro = '',
    this.municipioIbge = '',
    this.cidadeNome = '',
    this.uf = '',
    this.email = '',
  });

  factory TomadorModel.fromRecord(RecordModel record) {
    return TomadorModel(
      id: record.id,
      cnpj: record.getStringValue('cnpj'),
      razaoSocial: record.getStringValue('razao_social'),
      nomeFantasia: record.getStringValue('nome_fantasia'),
      apelido: record.getStringValue('apelido'),
      cnae: record.getStringValue('cnae'),
      cnaeDescricao: record.getStringValue('cnae_descricao'),
      isSalaoParceiro: record.collectionName == 'salao_parceiro',
      cep: record.getStringValue('cep'),
      logradouro: record.getStringValue('logradouro'),
      numero: record.getStringValue('numero'),
      bairro: record.getStringValue('bairro'),
      municipioIbge: record.getStringValue('municipio_ibge'),
      cidadeNome: record.getStringValue('cidade_nome'),
      uf: record.getStringValue('uf'),
      email: record.getStringValue('email'),
    );
  }

  factory TomadorModel.fromBrasilApi(Map<String, dynamic> json) {
    return TomadorModel(
      id: '', // Entidade ainda não persistida
      cnpj: json['cnpj'] ?? '',
      razaoSocial: json['razao_social'] ?? '',
      nomeFantasia: json['nome_fantasia'],
      cnae: json['cnae_fiscal']?.toString(),
      cnaeDescricao: json['cnae_fiscal_descricao'],
      isSalaoParceiro: false, // Será validado pelo service
      cep: json['cep'] ?? '',
      logradouro: json['logradouro'] ?? '',
      numero: json['numero'] ?? 'S/N',
      bairro: json['bairro'] ?? '',
      municipioIbge: json['municipio_ibge'] ?? '',
      cidadeNome: json['cidade_nome'] ?? '',
      uf: json['uf'] ?? '',
      email: json['email'] ?? '',
    );
  }

  // Helper para exibir o nome preferencial (Apelido > Fantasia > Razão)
  String get displayName {
    if (apelido?.isNotEmpty ?? false) return apelido!;
    if (nomeFantasia?.isNotEmpty ?? false) return nomeFantasia!;
    return razaoSocial;
  }

  TomadorModel copyWith({bool? isSalaoParceiro}) {
    return TomadorModel(
      id: id,
      cnpj: cnpj,
      razaoSocial: razaoSocial,
      nomeFantasia: nomeFantasia,
      apelido: apelido,
      cnae: cnae,
      cnaeDescricao: cnaeDescricao,
      isSalaoParceiro: isSalaoParceiro ?? this.isSalaoParceiro,
    );
  }
}
