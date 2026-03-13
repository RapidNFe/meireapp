const axios = require('axios');

async function testEmissao() {
    console.log("🚀 Iniciando Teste de Emissão (Ordem 3)...");

    const payload = {
        userId: "8t5dmdhpqgaafgi", // Thiago
        tomadorCnpj: "00000000000191", // CNPJ de Teste (Ex: Banco do Brasil)
        tomadorNome: "Empresa de Teste LTDA",
        valor: 10.00,
        servico: "Teste de Integração Soberana - Análise de Sistemas"
    };

    try {
        const response = await axios.post('http://127.0.0.1:3000/api/notas/emitir', payload);
        console.log("✅ Servidor respondeu!");
        console.log("📄 Resultado:", JSON.stringify(response.data, null, 2));
    } catch (error) {
        console.error("❌ Falha na emissão de teste:");
        if (error.response) {
            console.error("Status:", error.response.status);
            console.error("Data:", JSON.stringify(error.response.data, null, 2));
        } else {
            console.error(error.message);
        }
    }
}

testEmissao();
