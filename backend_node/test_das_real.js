const axios = require('axios');
const serproAuth = require('./serpro_auth');
const catraca = require('./catraca_serpro');
require('dotenv').config();

async function testGerarDasMeiReal() {
    console.log("🚀 O MÁXIMO DO AGENTE: Gerando DAS Real para Thiago (Fevereiro 2026)...");

    const cnpjThiago = "65057385000179"; 
    const cnpjSaid = "28413885000170";

    try {
        const resultado = await catraca.adicionar(async () => {
            const chaves = await serproAuth.getTokens();

            const payload = {
                "contratante": { "numero": cnpjSaid, "tipo": 2 },
                "autorPedidoDados": { "numero": cnpjSaid, "tipo": 2 },
                "contribuinte": { "numero": cnpjThiago, "tipo": 2 },
                "pedidoDados": {
                    "idSistema": "PGMEI",
                    "idServico": "GERARDASCODBARRA22", 
                    "versaoSistema": "1.0",
                    "dados": JSON.stringify({
                        "periodoApuracao": "202602" // Ele virou MEI em 10/02/2026. Bingo!
                    })
                }
            };

            const response = await axios({
                method: 'POST',
                url: 'https://gateway.apiserpro.serpro.gov.br/integra-contador/v1/Emitir',
                headers: { 'Authorization': `Bearer ${chaves.bearer}`, 'jwt_token': chaves.jwt, 'Content-Type': 'application/json' },
                data: payload,
                httpsAgent: chaves.agente
            });

            return response.data;
        });

        console.log("✅ BOLETO GERADO!");
        console.log(JSON.stringify(resultado, null, 2));

    } catch (error) {
        console.error("❌ Falha:");
        if (error.response) {
            console.error("Mensagem:", JSON.stringify(error.response.data, null, 2));
        } else {
            console.error(error.message);
        }
    }
}

testGerarDasMeiReal();
