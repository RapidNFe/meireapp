# Documentação de Consulta de CNPJ (API Minha Receita)

Consulta de informações empresariais através do CNPJ. Retorna dados cadastrais completos, situação fiscal, sócios, atividades econômicas e outras informações da Receita Federal.

Busca por CNPJ na API Minha Receita. Retorna informações completas de uma empresa a partir do CNPJ.

## Endpoint

```http
GET /cnpj/v1/{cnpj}
```

### Parâmetros de Path (Path Parameters)

| Nome  | Tipo   | Obrigatório | Descrição                                                                                                                                              | Padrão Esperado                                        | Exemplo          |
| :---- | :----- | :---------- | :----------------------------------------------------------------------------------------------------------------------------------------------------- | :----------------------------------------------------- | :--------------- |
| `cnpj`| string | Sim         | O Cadastro Nacional da Pessoa Jurídica é um número único que identifica uma pessoa jurídica junto à Receita Federal. Deve conter 14 dígitos. | `^[0-9]{14}$|^[0-9]{2}\.[0-9]{3}\.[0-9]{3}/[0-9]{4}-[0-9]{2}$` | `19131243000197` |

*O CNPJ pode ser enviado com ou sem formatação (pontos, barras e hífen).*

## Respostas (Responses)

| Código HTTP | Descrição                                         |
| :---------- | :------------------------------------------------ |
| `200`       | **Success** - Retorna os dados do CNPJ.           |
| `400`       | CNPJ inválido ou mal formatado.                   |
| `404`       | CNPJ não encontrado na API Minha Receita.         |

### Formato de Resposta (Content Type)

`application/json`

### Exemplo de Resposta (200 Success)

```json
{
  "uf": "SP",
  "cep": "01311902",
  "qsa": [
    {}
  ],
  "cnpj": "19131243000197",
  "pais": null,
  "email": null,
  "porte": "DEMAIS",
  "bairro": "BELA VISTA",
  "numero": "37",
  "ddd_fax": "",
  "municipio": "SAO PAULO",
  "logradouro": "PAULISTA 37",
  "cnae_fiscal": 9430800,
  "codigo_pais": null,
  "complemento": "ANDAR 4",
  "codigo_porte": 5,
  "razao_social": "OPEN KNOWLEDGE BRASIL",
  "nome_fantasia": "REDE PELO CONHECIMENTO LIVRE",
  "capital_social": 0,
  "ddd_telefone_1": "1123851939",
  "ddd_telefone_2": "",
  "opcao_pelo_mei": null,
  "descricao_porte": "",
  "codigo_municipio": 7107,
  "cnaes_secundarios": [
    {},
    {},
    {},
    {},
    {}
  ],
  "natureza_juridica": "Associação Privada",
  "regime_tributario": [
    {},
    {},
    {},
    {},
    {},
    {},
    {}
  ],
  "situacao_especial": "",
  "opcao_pelo_simples": null,
  "situacao_cadastral": 2,
  "data_opcao_pelo_mei": null,
  "data_exclusao_do_mei": null,
  "cnae_fiscal_descricao": "Atividades de associações de defesa de direitos sociais",
  "codigo_municipio_ibge": 3550308,
  "data_inicio_atividade": "2013-10-03",
  "data_situacao_especial": null,
  "data_opcao_pelo_simples": null,
  "data_situacao_cadastral": "2013-10-03",
  "nome_cidade_no_exterior": "",
  "codigo_natureza_juridica": 3999,
  "data_exclusao_do_simples": null,
  "motivo_situacao_cadastral": 0,
  "ente_federativo_responsavel": "",
  "identificador_matriz_filial": 1,
  "qualificacao_do_responsavel": 16,
  "descricao_situacao_cadastral": "ATIVA",
  "descricao_tipo_de_logradouro": "AVENIDA",
  "descricao_motivo_situacao_cadastral": "SEM MOTIVO",
  "descricao_identificador_matriz_filial": "MATRIZ"
}
```
