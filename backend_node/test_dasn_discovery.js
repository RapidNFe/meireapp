const axios = require('axios');
const serproAuth = require('./serpro_auth');
const catraca = require('./catraca_serpro');
require('dotenv').config();

const systems = ["PGMEI", "SIMEI", "DASNSIMEI", "SIMPLES_NACIONAL"];
const services = ["TRANSDECLARACAO151", "CONSULTIMADECREC152", "CONSSITDASN", "ENTREGARDASN", "DASN", "DASN22", "ENTREGARDASN22", "CONSSITDASN22"];

async function shotgunDiscovery() {
    console.log("🔫 OPERAÇÃO SHOTGUN: Tentando todas as combinações prováveis...");

    const cnpjThiago = "65057385000179"; 
    const cnpjSaid = "28413885000170";

    try {
        const chaves = await serproAuth.getTokens();

        for (const sys of systems) {
            for (const svc of services) {
                console.log(`🧪 [${sys}] -> [${svc}]`);
                
                try {
                    const payload = {
                        "tpAmb": 1,
                        "contratante": { "numero": cnpjSaid, "tipo": 2 },
                        "autorPedidoDados": { "numero": cnpjSaid, "tipo": 2 },
                        "contribuinte": { "numero": cnpjThiago, "tipo": 2 },
                        "pedidoDados": {
                            "idSistema": sys,
                            "idServico": svc,
                            "versaoSistema": "1.0",
                            "dados": JSON.stringify({ "anoCalendario": "2025" })
                        }
                    };

                    const response = await axios({
                        method: 'POST',
                        url: 'https://gateway.apiserpro.serpro.gov.br/integra-contador/v1/Consultar',
                        headers: { 'Authorization': `Bearer ${chaves.bearer}`, 'jwt_token': chaves.jwt, 'Content-Type': 'application/json' },
                        data: payload,
                        httpsAgent: chaves.agente,
                        timeout: 5000
                    });

                    console.log(`🎯 !!! ACHAMOS !!!`);
                    console.log(`SIS: ${sys}, SVC: ${svc}`);
                    console.log(response.data);
                    return;

                } catch (e) {
                    if (e.response && e.response.data && e.response.data.mensagens) {
                        const msg = e.response.data.mensagens[0].texto;
                        const cod = e.response.data.mensagens[0].codigo;
                        if (cod === "[EntradaIncorreta-ICGERENCIADOR-052]") {
                            // Inexistente no catálogo
                        } else {
                            console.log(`💡 ID EXISTE NO SERPRO (${sys}/${svc}): ${msg}`);
                            return; 
                        }
                    }
                }
            }
        }
        console.log("❌ Nenhuma combinação direta funcionou.");

    } catch (error) {
        console.error("❌ Falha:", error.message);
    }
}

shotgunDiscovery();
