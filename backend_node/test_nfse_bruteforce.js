const axios = require('axios');
const serproAuth = require('./serpro_auth');
const catraca = require('./catraca_serpro');
const AssinadorSoberano = require('./assinador_soberano');
require('dotenv').config();

async function bruteForceNfse() {
    console.log("💥 BRUTE FORCE NFSE: Testando TODAS as possibilidades de 052...");

    const cnpjThiago = "65057385000179"; 
    const cnpjSaid = "28413885000170";
    const senhaCert = process.env.CERT_PASSWORD;

    try {
        const chaves = await serproAuth.getTokens();
        
        const systems = ["SIMPLES_NACIONAL", "NFSE", "NFSE_NACIONAL", "PGMEI", "ADN", "SISTEMA_NFSE"];
        const services = ["EMISSAO_NFSE", "EMITIR_DPS", "EMISSAO_DPS", "GERAR_NFSE", "EMISSAO_NOTA", "ENVIAR_DPS", "DPS"];
        const suffixes = ["", "V1", "_V1", "11", "22"];

        for (const sys of systems) {
            for (const svc of services) {
                for (const suf of suffixes) {
                    const finalSvc = `${svc}${suf}`;
                    console.log(`🧪 [${sys}] -> [${finalSvc}]`);
                    
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
                                    "idSistema": sys,
                                    "idServico": finalSvc,
                                    "versaoSistema": "1.0",
                                    "dados": JSON.stringify({ "teste": true })
                                }
                            },
                            httpsAgent: chaves.agente,
                            timeout: 2000
                        });
                        console.log(`🎯 MATCH SUPREMO! SIS: ${sys}, SVC: ${finalSvc}`);
                        return;
                    } catch (e) {
                         if (e.response && e.response.data && e.response.data.mensagens) {
                            const cod = e.response.data.mensagens[0].codigo;
                            if (cod !== "[EntradaIncorreta-ICGERENCIADOR-052]") {
                                console.log(`💡 ID ATIVO (${sys}/${finalSvc}): ${e.response.data.mensagens[0].texto}`);
                                return;
                            }
                        }
                    }
                }
            }
        }

    } catch (error) {
        console.error("❌ Falha:", error.message);
    }
}

bruteForceNfse();
