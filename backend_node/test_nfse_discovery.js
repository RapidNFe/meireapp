const axios = require('axios');
const serproAuth = require('./serpro_auth');
const catraca = require('./catraca_serpro');
require('dotenv').config();

const combos = [
    { system: "NFSE", service: "EMITIR_NOTA_V1" },
    { system: "NFSE", service: "EMISSAO_NOTA" },
    { system: "NFSE", service: "EMITIR" },
    { system: "NFSE_NACIONAL", service: "EMITIR" },
    { system: "SIMPLES_NACIONAL", service: "EMISSAO_NFSE" },
    { system: "SISTEMA_NFSE", service: "EMISSAO_NOTA" },
    { system: "ADN", service: "EMISSAO_NFSE" },
    { system: "MEI", service: "EMISSAO_NFSE" }
];

async function nfseDiscovery() {
    console.log("🕵️‍♂️ MONITORAMENTO NFS-e: Caçando o CID da Nota Fiscal...");

    const cnpjThiago = "65057385000179"; 
    const cnpjSaid = "28413885000170";

    try {
        const chaves = await serproAuth.getTokens();

        for (const trial of combos) {
            console.log(`\n🧪 Testando [${trial.system}] -> [${trial.service}]`);
            
            try {
                // Payload fake só para ver se o ID existe
                const payload = {
                    "tpAmb": 1,
                    "contratante": { "numero": cnpjSaid, "tipo": 2 },
                    "autorPedidoDados": { "numero": cnpjSaid, "tipo": 2 },
                    "contribuinte": { "numero": cnpjThiago, "tipo": 2 },
                    "pedidoDados": {
                        "idSistema": trial.system,
                        "idServico": trial.service,
                        "versaoSistema": "1.0",
                        "dados": JSON.stringify({ "teste": true })
                    }
                };

                const response = await axios({
                    method: 'POST',
                    url: 'https://gateway.apiserpro.serpro.gov.br/integra-contador/v1/Emitir',
                    headers: { 'Authorization': `Bearer ${chaves.bearer}`, 'jwt_token': chaves.jwt, 'Content-Type': 'application/json' },
                    data: payload,
                    httpsAgent: chaves.agente,
                    timeout: 5000
                });

                console.log(`🎯 MATCH!`);
                console.log(response.data);
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

nfseDiscovery();
