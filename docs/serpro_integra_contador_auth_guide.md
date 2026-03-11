# Guia de Autenticação e Consumo - API SERPRO Integra Contador

Este guia descreve o processo oficial para autenticação e consumo das APIs da plataforma Serpro utilizando o protocolo OAuth2 e mTLS.

## 1. Obtenção de Credenciais
Para consumir as APIs, utilize os códigos **Consumer Key** e **Consumer Secret** disponibilizados na Área do Cliente Serpro ([cliente.serpro.gov.br](https://cliente.serpro.gov.br)).

> [!IMPORTANT]
> O Consumer Key e o Consumer Secret identificam seu contrato. Mantenha essas informações seguras.

## 2. Solicitação de Tokens (Bearer e JWT)
O Integra Contador exige dois tokens para autenticação: o `access_token` (Bearer) e o `jwt_token`. Eles são obtidos através de uma requisição mTLS à plataforma SAPI.

### Requisitos Técnicos
- **Certificado Digital:** e-CNPJ padrão ICP-Brasil (tipo A1 .pfx ou .p12) válido.
- **Endpoint de Autenticação:** `https://autenticacao.sapi.serpro.gov.br/authenticate`

### Cabeçalhos (Headers) da Requisição
- `Authorization`: `Basic base64(consumerKey:consumerSecret)`
- `Role-Type`: `TERCEIROS`
- `Content-Type`: `application/x-www-form-urlencoded`

### Exemplo de Chamada via cURL
```bash
curl -i -X POST \
  -H "Authorization: Basic [BASE64_CREDENTIALS]" \
  -H "Role-Type: TERCEIROS" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d 'grant_type=client_credentials' \
  --cert-type PFX \
  --cert certificado.pfx:senha_foda_aqui \
  'https://autenticacao.sapi.serpro.gov.br/authenticate'
```

## 3. Retorno da Autenticação
O retorno será um objeto JSON contendo os tempos de expiração e os tokens:

```json
{
  "expires_in": 3600,
  "scope": "default",
  "token_type": "Bearer",
  "access_token": "af012866-daae-3aef-8b40-bd14e8cfac99",
  "jwt_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

> [!NOTE]
> Quando o token expirar, o gateway retornará um **HTTP 401**. Nesse caso, repita o processo de autenticação.

## 4. Consumo da API (Consultar)
De posse dos tokens, as consultas devem ser feitas via **POST** no "Guichê Único" de consulta.

- **URL:** `https://gateway.apiserpro.serpro.gov.br/integra-contador/v1/Consultar`
- **Cabeçalhos:**
  - `Accept`: `application/json`
  - `Authorization`: `Bearer [access_token]`
  - `jwt_token`: `[jwt_token]`
  - `Content-Type`: `application/json`

### Estrutura do Payload (Body)
O corpo da requisição deve seguir o envelope padrão esperado pela Receita Federal:

```json
{
  "contratante": {
    "numero": "CNPJ_DA_CONTABILIDADE",
    "tipo": 2
  },
  "autorPedidoDados": {
    "numero": "CNPJ_DA_CONTABILIDADE",
    "tipo": 2
  },
  "contribuinte": {
    "numero": "CNPJ_DO_CLIENTE",
    "tipo": 2
  },
  "pedidoDados": {
    "idSistema": "PGDASD",
    "idServico": "CONSEXTRATO16",
    "versaoSistema": "1.0",
    "dados": "{ \"numeroDas\": \"99999999\" }"
  }
}
```

### Exemplo de Resposta
```json
{
  "status": 200,
  "dados": "...",
  "mensagens": [
    {
      "codigo": "SUCESSO",
      "texto": "Operação realizada com êxito."
    }
  ]
}
```
