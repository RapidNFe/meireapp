require('dotenv').config();
const fs = require('fs');
const https = require('https');
const axios = require('axios');

// 1. Os Atores do Jogo
const CNPJ_SAID = '28413885000170';
const CNPJ_THIAGO = '65057385000179';

// 2. O Túnel Blindado (mTLS)
const agenteSeguro = new https.Agent({
    pfx: fs.readFileSync(process.env.CAMINHO_CERTIFICADO_PFX || './certs/SAID CONTABILIDADE E TREINAMENTOS CONTABEIS LTDA_28413885000170 senha Said2026++.pfx'),
    passphrase: process.env.SERPRO_CERTIFICADO_SENHA,
    rejectUnauthorized: false
});

async function extrairDadosReceita() {
    try {
        console.log('🛡️ Passo 1: Solicitando Chave Dupla (SAPI)...');

        const credenciaisBase64 = Buffer.from(
            `${process.env.SERPRO_CONSUMER_KEY}:${process.env.SERPRO_CONSUMER_SECRET}`
        ).toString('base64');

        // Chamada de Autenticação (Exatamente como o manual mandou)
        const authResponse = await axios({
            method: 'POST',
            url: 'https://autenticacao.sapi.serpro.gov.br/authenticate',
            headers: {
                'Authorization': `Basic ${credenciaisBase64}`,
                'Role-Type': 'TERCEIROS',
                'Content-Type': 'application/x-www-form-urlencoded'
            },
            data: 'grant_type=client_credentials',
            httpsAgent: agenteSeguro
        });

        const tokenBearer = authResponse.data.access_token;
        const tokenJwt = authResponse.data.jwt_token;
        console.log('✅ Chaves recebidas! Bearer & JWT em mãos.');

        console.log(`\n🕵️‍♂️ Passo 2: Consultando CNPJ ${CNPJ_THIAGO} no Integra Contador...`);

        // O Envelope Padrão da Receita
        const payloadGoverno = {
            "contratante": { "numero": CNPJ_SAID, "tipo": 2 },
            "autorPedidoDados": { "numero": CNPJ_SAID, "tipo": 2 },
            "contribuinte": { "numero": CNPJ_THIAGO, "tipo": 2 },
            "pedidoDados": {
                "idSistema": "PGDASD",
                "idServico": "CONSEXTRATO16",
                "versaoSistema": "1.0",
                "dados": "{ \"numeroDas\": \"99999999999999999\" }" // Usando o exemplo da documentação
            }
        };

        // Chamada Final no Guichê Único
        const consultaResponse = await axios({
            method: 'POST',
            url: 'https://gateway.apiserpro.serpro.gov.br/integra-contador/v1/Consultar',
            headers: {
                'Authorization': `Bearer ${tokenBearer}`,
                'jwt_token': tokenJwt,
                'Content-Type': 'application/json',
                'Accept': 'application/json'
            },
            data: payloadGoverno,
            httpsAgent: agenteSeguro
        });

        console.log('\n🎯 BINGO! O Governo respondeu:');
        console.log(JSON.stringify(consultaResponse.data, null, 2));

    } catch (erro) {
        console.error('\n❌ Ocorreu um bloqueio:');
        if (erro.response) {
            console.error(`Status: ${erro.response.status}`);
            console.error(JSON.stringify(erro.response.data, null, 2));
        } else {
            console.error(erro.message);
        }
    }
}

extrairDadosReceita();
