const axios = require('axios');
const serproAuth = require('./serpro_auth');
const catraca = require('./catraca_serpro');
const AssinadorSoberano = require('./assinador_soberano');
require('dotenv').config();

async function testNfseNacionalDirect() {
    console.log("🚀 OPERAÇÃO NFSE NACIONAL: Testando ID do Catálogo Soberano...");

    const cnpjThiago = "65057385000179"; 
    const cnpjSaid = "28413885000170";
    const senhaCert = process.env.CERT_PASSWORD;

    try {
        const chaves = await serproAuth.getTokens();

        // 1. Montar a DPS Original
        const dpsOriginal = {
            "infDPS": {
                "tpAmb": 1, 
                "dhEmi": new Date().toISOString().split('.')[0] + "-03:00",
                "verAplic": "MeireApp_1.0",
                "prest": { "CNPJ": cnpjThiago },
                "toma": { 
                    "CNPJ": cnpjSaid,
                    "xNome": "SAID CONTABILIDADE E TREINAMENTOS CONTABEIS LTDA"
                },
                "serv": { 
                    "cServ": { 
                        "cTribNac": "01.01.01", 
                        "xDescServ": "Consultoria em Estratégia de Software - Teste Meire App" 
                    },
                    "vServ": { "vUnit": 1.00 }
                }
            }
        };

        // 2. Assinar a Nota
        const dpsAssinada = await AssinadorSoberano.assinar(dpsOriginal, senhaCert);

        // 3. Montar o Envelope do Integra Contador (Roteamento via Gateway)
        const payloadFinal = {
            "contratante": { "numero": cnpjSaid, "tipo": 2 },
            "autorPedidoDados": { "numero": cnpjSaid, "tipo": 2 },
            "contribuinte": { "numero": cnpjThiago, "tipo": 2 },
            "pedidoDados": {
                "idSistema": "NFSE_NACIONAL", 
                "idServico": "EMITIR_DPS_V1",
                "versaoSistema": "1.0.0",
                "dados": JSON.stringify(dpsAssinada)
            }
        };

        console.log("📡 Disparando para Integra Contador (/Emitir)...");
        const response = await axios({
            method: 'POST',
            url: 'https://gateway.apiserpro.serpro.gov.br/integra-contador/v1/Emitir',
            headers: {
                'Authorization': `Bearer ${chaves.bearer}`,
                'jwt_token': chaves.jwt,
                'Content-Type': 'application/json'
            },
            data: payloadFinal,
            httpsAgent: chaves.agente,
            timeout: 10000
        });

        console.log("🎯 RESPOSTA RECEBIDA!");
        console.log(JSON.stringify(response.data, null, 2));

    } catch (error) {
        console.error("🕵️ O GOVERNO FALOU:");
        if (error.response) {
            console.error("Status:", error.response.status);
            console.error("Mensagem:", JSON.stringify(error.response.data, null, 2));
        } else {
            console.error(error.message);
        }
    }
}

testNfseNacionalDirect();
