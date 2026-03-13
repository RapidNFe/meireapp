const axios = require('axios');
const serproAuth = require('./serpro_auth');
const catraca = require('./catraca_serpro');
require('dotenv').config();

async function listSerproCatalog() {
    console.log("📖 LENDO O CATÁLOGO REAL: Consultando serviços disponíveis...");

    const cnpjSaid = "28413885000170";

    try {
        const chaves = await serproAuth.getTokens();

        const trials = [
            { svc: "LISTARSISTEMAS", dados: "{}" },
            { svc: "LISTARSERVICOS", dados: "{}" },
            { svc: "CONSULTARSISTEMAS", dados: "{}" },
            { svc: "SERVICOSDISPONIVEIS", dados: "{}" }
        ];

        for (const trial of trials) {
            console.log(`🧪 Tentando serviço de apoio: ${trial.svc}`);
            try {
                const response = await axios({
                    method: 'POST',
                    url: 'https://gateway.apiserpro.serpro.gov.br/integra-contador/v1/Apoiar',
                    headers: { 'Authorization': `Bearer ${chaves.bearer}`, 'jwt_token': chaves.jwt, 'Content-Type': 'application/json' },
                    data: {
                        "contratante": { "numero": cnpjSaid, "tipo": 2 },
                        "autorPedidoDados": { "numero": cnpjSaid, "tipo": 2 },
                        "contribuinte": { "numero": cnpjSaid, "tipo": 2 },
                        "pedidoDados": {
                            "idSistema": "INTEGRA_CONTADOR", // Geralmente o sistema de apoio é ele mesmo
                            "idServico": trial.svc,
                            "versaoSistema": "1.0",
                            "dados": trial.dados
                        }
                    },
                    httpsAgent: chaves.agente,
                    timeout: 5000
                });

                console.log(`🎯 SUCESSO NO APOIO!`);
                console.log(JSON.stringify(response.data, null, 2));
                return;
            } catch (e) {
                console.log(`❌ Falha ${trial.svc}: ${e.response ? e.response.data.mensagens[0].texto : e.message}`);
            }
        }

    } catch (error) {
        console.error("❌ Falha crítica:", error.message);
    }
}

listSerproCatalog();
