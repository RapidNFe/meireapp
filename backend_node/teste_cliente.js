const axios = require('axios');
const https = require('https');
const fs = require('fs');
require('dotenv').config();

// 1. O Token que o Serpro te deu e o CNPJ do Thiago
const TOKEN_BEARER = 'eyJ4NXQiOiJaVEE1WW1SbU5Ea3dNMlUxWkRZMk9EaGxOekZsWm1WbU5XSmtPREUzWW1NeE5UWmpaREUzWlEiLCJraWQiOiJOalk1TkdRMlkyTmxNV0k0T1dSak9ESmlaREV3WkdaaE5ETXpNek5qWVRRek1XWTNNamMxTjJZeE56YzJaRGMyTVdFNE56RmpZalprTVdabFl6WmhZd19SUzI1NiIsImFsZyI6IlJTMjU2In0.eyJzdWIiOiJhdXRlbnRpa3VzIiwiYXV0IjoiQVBQTElDQVRJT04iLCJhdWQiOiJwNzlhaGdjSmRZX1lhdWlmNzA1TVNDa2U3c01hIiwibmJmIjoxNzczMjQ3ODEyLCJhenAiOiJwNzlhaGdjSmRZX1lhdWlmNzA1TVNDa2U3c01hIiwic2NvcGUiOiJkZWZhdWx0IiwiaXNzIjoiaHR0cHM6XC9cL3B1Ymxpc2hlci5hcGlzZXJwcm8uc2VycHJvLmdvdi5icjo0NDNcL29hdXRoMlwvdG9rZW4iLCJyZWFsbSI6eyJzaWduaW5nX3RlbmFudCI6ImNhcmJvbi5zdXBlciJ9LCJleHAiOjE3NzMyNTE0MTIsImlhdCI6MTc3MzI0NzgxMiwianRpIjoiYTU4NTliYTctZTFhNC00NWVlLThmODYtMzc1MDk3ZjQ3MzllIn0.i3ARYrWcYxk7_SGgrRC9H9VXub12teodvX1VqQyVqECrx8fvf95Q_30GPuI-8Q6s31rKW2mwBugReQOUlALHMCcIYzMzFsqfTdfsMKnp0SPjKawC8OLpvcZVD_kJSQfoxzQIFpw77mMUPya0lH4hw1GtXAZMvIkivKgvvuqmZ_DxhqSAzoshuO03t2pIUXk3kCVsQvbh0GDkEmiMDsiJRJU77IYRVBA8afAArfXcNfGWqZWJxdsIcj2eRcKZj2G-QjQSgHKP15Lhq2Io71GIsk0BmjpjNPjALXHhC8mywLbwUshZiyKZ4R7CFZg5oi-IYe2rdJnWCyw1uf4LL0HreA'; 
const CNPJ_CLIENTE = '65057385000179'; // CNPJ do Thiago (Sem pontuação)

// 2. O mTLS continua sendo obrigatório mesmo com o Token
const agenteSeguro = new https.Agent({
    pfx: fs.readFileSync(process.env.CAMINHO_CERTIFICADO_PFX || './certs/SAID CONTABILIDADE E TREINAMENTOS CONTABEIS LTDA_28413885000170 senha Said2026++.pfx'),
    passphrase: process.env.SERPRO_CERTIFICADO_SENHA,
    rejectUnauthorized: false
});

async function espionarCliente() {
    console.log(`🕵️‍♂️ Consultando o cofre da Receita para o CNPJ: ${CNPJ_CLIENTE}...`);

    try {
        // Exemplo: Consultando a situação do Simples Nacional via Integra Contador
        const resposta = await axios({
            method: 'GET',
            // Rota oficial do Integra Contador para consultar o Simples
            url: `https://gateway.apiserpro.serpro.gov.br/integra-contador/v1/empresas/${CNPJ_CLIENTE}`,
            headers: {
                'Authorization': `Bearer ${TOKEN_BEARER}`,
                'Accept': 'application/json'
            },
            httpsAgent: agenteSeguro
        });

        console.log('\n✅ DADOS CAPTURADOS COM SUCESSO!\n');
        console.log(JSON.stringify(resposta.data, null, 2));

    } catch (erro) {
        console.error('\n❌ O Governo bloqueou a porta:');
        if (erro.response) {
            console.error(erro.response.status, erro.response.data);
        } else {
            console.error(erro.message);
        }
    }
}

espionarCliente();
