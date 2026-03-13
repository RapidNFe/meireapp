const axios = require('axios');
const serproAuth = require('./serpro_auth');
const catraca = require('./catraca_serpro');
require('dotenv').config();

async function deepSearchCatalog() {
    console.log("🕵️‍♂️ DEEP SEARCH CATALOG: Buscando qualquer rastro de NFS-e...");

    const cnpjThiago = "65057385000179"; 
    const cnpjSaid = "28413885000170";

    const chaves = await serproAuth.getTokens();

    const candidates = [
        { sys: "SIMPLES_NACIONAL", svc: "EMISSAO_NFSE_V1" },
        { sys: "SIMPLES_NACIONAL", svc: "GERAR_NFSE" },
        { sys: "PGMEI", svc: "EMITIR_NFSE" },
        { sys: "NFSE", svc: "EMITIR_DPS" },
        { sys: "NFSEN", svc: "EMITIR" },
        { sys: "ADN", svc: "EMITIR_DPS" },
        { sys: "NFSE_NACIONAL", svc: "EMITIR_DPS" },
        { sys: "NFSE_NACIONAL", svc: "EMITIR" }
    ];

    for (const trial of candidates) {
        console.log(`🧪 Testando [${trial.sys}] -> [${trial.svc}]`);
        try {
            const response = await axios({
                method: 'POST',
                url: 'https://gateway.apiserpro.serpro.gov.br/integra-contador/v1/Emitir',
                headers: { 'Authorization': `Bearer ${chaves.bearer}`, 'jwt_token': chaves.jwt, 'Content-Type': 'application/json' },
                data: {
                    "contratante": { "numero": cnpjSaid, "tipo": 2 },
                    "autorPedidoDados": { "numero": cnpjSaid, "tipo": 2 },
                    "contribuinte": { "numero": cnpjThiago, "tipo": 2 },
                    "pedidoDados": {
                        "idSistema": trial.sys,
                        "idServico": trial.svc,
                        "versaoSistema": "1.0",
                        "dados": JSON.stringify({ "teste": true })
                    }
                },
                httpsAgent: chaves.agente,
                timeout: 5000
            });
            console.log("🎯 SUCESSO!");
            return;
        } catch (e) {
            if (e.response && e.response.data && e.response.data.mensagens) {
                const cod = e.response.data.mensagens[0].codigo;
                if (cod !== "[EntradaIncorreta-ICGERENCIADOR-052]") {
                    console.log(`💡 ID ATIVO (${trial.sys}/${trial.svc}): ${e.response.data.mensagens[0].texto}`);
                    return;
                }
            }
        }
    }
}

deepSearchCatalog();
