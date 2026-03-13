const axios = require('axios');
const serproAuth = require('./serpro_auth');
const catraca = require('./catraca_serpro');
require('dotenv').config();

async function testMeiVariações() {
    console.log("🕵️‍♂️ MONITORAMENTO: Testando campos para CCMEI e PGMEI com Versões...");

    const cnpjThiago = "65057385000179"; 
    const cnpjSaid = "28413885000170";

    const combos = [
        { system: "CCMEI", service: "DADOSCCMEI122", version: "1.0.0" },
        { system: "CCMEI", service: "DADOSCCMEI", version: "1.2.2" },
        { system: "PGMEI", service: "GERARDAS", version: "2.2" },
        { system: "PGMEI", service: "EMITIRDAS", version: "1.0" }
    ];

    try {
        const chaves = await serproAuth.getTokens();

        for (const trial of combos) {
            console.log(`\n🧪 Testando: ${trial.system}/${trial.service} v${trial.version}`);
            try {
                const response = await axios({
                    method: 'POST',
                    url: `https://gateway.apiserpro.serpro.gov.br/integra-contador/v1/${trial.service.includes('DADOS') ? 'Consultar' : 'Emitir'}`,
                    headers: { 'Authorization': `Bearer ${chaves.bearer}`, 'jwt_token': chaves.jwt, 'Content-Type': 'application/json' },
                    data: {
                        "contratante": { "numero": cnpjSaid, "tipo": 2 },
                        "autorPedidoDados": { "numero": cnpjSaid, "tipo": 2 },
                        "contribuinte": { "numero": cnpjThiago, "tipo": 2 },
                        "pedidoDados": {
                            "idSistema": trial.system,
                            "idServico": trial.service,
                            "versaoSistema": trial.version,
                            "dados": JSON.stringify({ "numeroCnpj": cnpjThiago, "periodoApuracao": "202602" })
                        }
                    },
                    httpsAgent: chaves.agente,
                    timeout: 5000
                });
                console.log("🎯 SUCESSO!");
            } catch (e) {
                 if (e.response && e.response.data && e.response.data.mensagens) {
                    console.log(`❌ Rejeitado: ${e.response.data.mensagens[0].texto}`);
                }
            }
        }

    } catch (error) {
        console.error("❌ ERRO:", error.message);
    }
}

testMeiVariações();
