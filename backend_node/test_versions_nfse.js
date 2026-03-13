const axios = require('axios');
const serproAuth = require('./serpro_auth');
const catraca = require('./catraca_serpro');
const AssinadorSoberano = require('./assinador_soberano');
require('dotenv').config();

async function extremeNfseSearch() {
    console.log("🧨 BUSCA EXTREMA NFSE: Testando VERSÕES e IDs...");

    const cnpjThiago = "65057385000179"; 
    const cnpjSaid = "28413885000170";
    const senhaCert = process.env.CERT_PASSWORD;

    const chaves = await serproAuth.getTokens();

    const candidates = [
        { sys: "NFSE_NACIONAL", svc: "EMITIR_DPS_V1", ver: "1.0.0" },
        { sys: "NFSE_NACIONAL", svc: "EMITIR_DPS", ver: "1.0" },
        { sys: "SIMPLES_NACIONAL", svc: "EMISSAO_NFSE", ver: "1.0.0" },
        { sys: "NFSE", svc: "EMISSAO_NOTA", ver: "1.0.0" },
        { sys: "SISTEMA_NFSE", svc: "EMISSAO_NOTA", ver: "1.1" }
    ];

    for (const trial of candidates) {
        console.log(`🧪 Testando [${trial.sys}] -> [${trial.svc}] v${trial.ver}`);
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
                        "versaoSistema": trial.ver,
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

extremeNfseSearch();
