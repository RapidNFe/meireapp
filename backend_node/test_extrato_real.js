const axios = require('axios');
const serproAuth = require('./serpro_auth');
const catraca = require('./catraca_serpro');
require('dotenv').config();

async function testRelatorioPagamentos() {
    console.log("🕵️‍♂️ MONITORAMENTO: Buscando Relatório de Pagamentos (RELPMEI)...");

    const cnpjThiago = "65057385000179"; 
    const cnpjSaid = "28413885000170";

    const chaves = await serproAuth.getTokens();

    const ids = [
        { sys: "PGMEI", svc: "RELPMEI154" },
        { sys: "PGMEI", svc: "RELPMEI" },
        { sys: "RELPMEI", svc: "CONSULTAR" }
    ];

    for (const trial of ids) {
        console.log(`\n🧪 Testando [${trial.sys}] -> [${trial.svc}]`);
        try {
            const response = await axios({
                method: 'POST',
                url: 'https://gateway.apiserpro.serpro.gov.br/integra-contador/v1/Consultar',
                headers: { 'Authorization': `Bearer ${chaves.bearer}`, 'jwt_token': chaves.jwt, 'Content-Type': 'application/json' },
                data: {
                    "contratante": { "numero": cnpjSaid, "tipo": 2 },
                    "autorPedidoDados": { "numero": cnpjSaid, "tipo": 2 },
                    "contribuinte": { "numero": cnpjThiago, "tipo": 2 },
                    "pedidoDados": {
                        "idSistema": trial.sys,
                        "idServico": trial.svc,
                        "versaoSistema": "1.0",
                        "dados": JSON.stringify({ "anoCalendario": "2025" })
                    }
                },
                httpsAgent: chaves.agente,
                timeout: 5000
            });
            console.log("🎯 SUCESSO!");
            console.log(response.data);
            return;
        } catch (e) {
             if (e.response && e.response.data && e.response.data.mensagens) {
                const cod = e.response.data.mensagens[0].codigo;
                if (cod !== "[EntradaIncorreta-ICGERENCIADOR-052]") {
                    console.log(`💡 ID ATIVO (${trial.svc}): ${e.response.data.mensagens[0].texto}`);
                    return;
                }
            }
        }
    }
}

testRelatorioPagamentos();
