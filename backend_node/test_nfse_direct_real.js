const axios = require('axios');
const serproAuth = require('./serpro_auth');
const AssinadorSoberano = require('./assinador_soberano');
require('dotenv').config();

async function testEmitirNfsDirect() {
    console.log("🚀 OPERAÇÃO TIRO DE MESTRE: Emissão Direta NFS-e Nacional...");

    const cnpjThiago = "65057385000179"; 
    const senhaCert = process.env.CERT_PASSWORD;

    try {
        // 1. Obter Token de Autenticação (Serpro / SAPI)
        const chaves = await serproAuth.getTokens();

        // 2. Montar a DPS (Declaração de Prestação de Serviço)
        const dps = {
            "infDPS": {
                "tpAmb": 1, // PRODUÇÃO
                "dhEmi": new Date().toISOString(),
                "verAplic": "MeireApp_1.0",
                "prest": { "CNPJ": cnpjThiago },
                "toma": { 
                    "CNPJ": "28413885000170", // Usando SAID como tomador para o teste
                    "xNome": "SAID CONTABILIDADE E TREINAMENTOS CONTABEIS LTDA"
                },
                "serv": { 
                    "cServ": { 
                        "cTribNac": "01.01.01", // Código de tributação nacional
                        "xDescServ": "Consultoria em Estratégia de Software - Teste Meire App" 
                    },
                    "vServ": { "vUnit": 1.00 } // Valor simbólico para teste
                }
            }
        };

        // 3. Assinar a Nota
        const notaAssinada = await AssinadorSoberano.assinar(dps, senhaCert);

        // 4. O Disparo para o ADN (Ambiente de Dados Nacional)
        // Tentando a URL oficial do ADN/Serpro
        const urlNacional = 'https://trib.nfse.gov.br/api/v1/nfs-e';

        console.log(`📡 Disparando para ${urlNacional}...`);
        const response = await axios.post(urlNacional, notaAssinada, {
            headers: { 
                'Authorization': `Bearer ${chaves.bearer}`,
                'Content-Type': 'application/json'
            },
            httpsAgent: chaves.agente, // Usando o agente mTLS com o certificado da SAID
            timeout: 10000
        });

        console.log("💎 SUCESSO ABSOLUTO! O GOVERNO ACEITOU A NOTA!");
        console.log(JSON.stringify(response.data, null, 2));

    } catch (error) {
        console.error("🕵️ O GOVERNO FALOU:");
        if (error.response) {
            console.error("Status:", error.response.status);
            console.error("Body:", JSON.stringify(error.response.data, null, 2));
        } else {
            console.error(error.message);
        }
    }
}

testEmitirNfsDirect();
