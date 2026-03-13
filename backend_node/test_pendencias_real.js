const axios = require('axios');
const serproAuth = require('./serpro_auth');
const catraca = require('./catraca_serpro');
require('dotenv').config();

async function extremeBruteForce() {
    console.log("🧨 OPERAÇÃO EXTREME BRUTE FORCE: Varrendo o PGDASD...");

    const cnpjThiago = "65057385000179"; 
    const cnpjSaid = "28413885000170";

    const commonPrefixes = ["CONS", "OBTER", "LISTAR", "VER"];
    const commonTerms = ["PENDENCIAS", "DASN", "EXTRATO", "RELATORIO"];
    const commonSuffixes = ["", "11", "12", "16", "22", "016"];

    try {
        const chaves = await serproAuth.getTokens();

        for (const pre of commonPrefixes) {
            for (const term of commonTerms) {
                for (const suf of commonSuffixes) {
                    const svc = `${pre}${term}${suf}`;
                    const system = (term === "PENDENCIAS" || term === "EXTRATO") ? "PGDASD" : "PGMEI";
                    
                    console.log(`🧪 [${system}] -> [${svc}]`);
                    
                    try {
                        const payload = {
                            "tpAmb": 1,
                            "contratante": { "numero": cnpjSaid, "tipo": 2 },
                            "autorPedidoDados": { "numero": cnpjSaid, "tipo": 2 },
                            "contribuinte": { "numero": cnpjThiago, "tipo": 2 },
                            "pedidoDados": {
                                "idSistema": system,
                                "idServico": svc,
                                "versaoSistema": "1.0",
                                "dados": JSON.stringify({ "cnpjBasico": cnpjThiago.substring(0, 8), "anoCalendario": "2025" })
                            }
                        };

                        const response = await axios({
                            method: 'POST',
                            url: 'https://gateway.apiserpro.serpro.gov.br/integra-contador/v1/Consultar',
                            headers: { 'Authorization': `Bearer ${chaves.bearer}`, 'jwt_token': chaves.jwt, 'Content-Type': 'application/json' },
                            data: payload,
                            httpsAgent: chaves.agente,
                            timeout: 1000 // Timeout curto para varrer rápido
                        });

                        console.log(`🎯 MATCH SUPREMO! ID: ${svc}`);
                        return;

                    } catch (e) {
                        if (e.response && e.response.data && e.response.data.mensagens) {
                            const cod = e.response.data.mensagens[0].codigo;
                            if (cod !== "[EntradaIncorreta-ICGERENCIADOR-052]") {
                                console.log(`💡 ID ATIVO (${svc}): ${e.response.data.mensagens[0].texto}`);
                                return;
                            }
                        }
                    }
                }
            }
        }
        console.log("💀 Nada encontrado no radar.");

    } catch (error) {
        console.error("❌ Falha:", error.message);
    }
}

extremeBruteForce();
