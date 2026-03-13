const axios = require('axios');
const serproAuth = require('./serpro_auth');
const catraca = require('./catraca_serpro');
require('dotenv').config();

const trials = [
    { system: "SITFIS", service: "OBTER_RELATORIO", endpoint: "Consultar" },
    { system: "SITFIS", service: "GERAR_RELATORIO", endpoint: "Emitir" },
    { system: "SITFIS", service: "CONSULTAR_SITUACAO", endpoint: "Consultar" },
    { system: "PGDASD", service: "CONSEXTRATO16", endpoint: "Consultar" },
    { system: "PGDASD", service: "CONSEXTRATO", endpoint: "Consultar" },
    { system: "PGDASD", service: "CONSULTAR_DECLARACAO", endpoint: "Consultar" },
    { system: "SIMPLES_NACIONAL", service: "TRANSDECLARACAO11", endpoint: "Consultar" },
    { system: "SIMPLES_NACIONAL", service: "CONSEXTRATO16", endpoint: "Consultar" }
];

async function sitfisDiscovery() {
    console.log("🕵️‍♂️ MONITORAMENTO GLOBAL: Buscando Situação Fiscal e DASN...");

    const cnpjThiago = "65057385000179"; 
    const cnpjSaid = "28413885000170";

    try {
        const chaves = await serproAuth.getTokens();

        for (const trial of trials) {
            console.log(`\n🧪 Testando [${trial.system}] -> [${trial.service}]`);
            
            try {
                const payload = {
                    "tpAmb": 1,
                    "contratante": { "numero": cnpjSaid, "tipo": 2 },
                    "autorPedidoDados": { "numero": cnpjSaid, "tipo": 2 },
                    "contribuinte": { "numero": cnpjThiago, "tipo": 2 },
                    "pedidoDados": {
                        "idSistema": trial.system,
                        "idServico": trial.service,
                        "versaoSistema": "1.0",
                        "dados": JSON.stringify({
                             "anoCalendario": "2025",
                             "cnpjBasico": cnpjThiago.substring(0, 8)
                        })
                    }
                };

                const response = await axios({
                    method: 'POST',
                    url: `https://gateway.apiserpro.serpro.gov.br/integra-contador/v1/${trial.endpoint}`,
                    headers: { 'Authorization': `Bearer ${chaves.bearer}`, 'jwt_token': chaves.jwt, 'Content-Type': 'application/json' },
                    data: payload,
                    httpsAgent: chaves.agente,
                    timeout: 7000
                });

                console.log(`🎯 MATCH!`);
                console.log(JSON.stringify(response.data, null, 2));
                return;

            } catch (e) {
                if (e.response && e.response.data && e.response.data.mensagens) {
                    const msg = e.response.data.mensagens[0].texto;
                    const cod = e.response.data.mensagens[0].codigo;
                    console.log(`❌ Negado: ${msg} (${cod})`);
                    if (cod !== "[EntradaIncorreta-ICGERENCIADOR-052]") {
                        console.log("💡 ID ATIVO!");
                        return;
                    }
                } else {
                    console.log(`❌ Erro: ${e.message}`);
                }
            }
        }

    } catch (error) {
        console.error("❌ Falha:", error.message);
    }
}

sitfisDiscovery();
