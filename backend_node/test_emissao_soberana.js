const axios = require('axios');

async function testEmissaoSoberana() {
    console.log("🚀 Iniciando Teste de Emissão (Direto do Cofre de Certificados)...");

    // Precisamos acionar a nova rota /api/nacional/emitir
    const payload = {
        userId: "8t5dmdhpqgaafgi", // Substitua pelo ID real do seu usuário de teste que JÁ FEZ O NOVO UPLOAD
        payload: {
            tomador: {
                cnpj: "00000000000191", // Ex: Banco do Brasil
                nome: "Empresa de Teste LTDA"
            },
            servico: {
                valor: 10.00
            }
        }
    };

    try {
        const response = await axios.post('http://127.0.0.1:3000/api/nacional/emitir', payload);
        console.log("✅ Serviço acessado!");
        console.log("📄 Resultado da Emissão Nacional:", JSON.stringify(response.data, null, 2));
    } catch (error) {
        console.error("❌ O teste barrou (A Trava Soberana está operando):");
        if (error.response) {
            console.error("Status:", error.response.status);
            console.error("Motivo:", error.response.data.erro || error.response.data);
            
            if (error.response.status === 403) {
                console.log("\n💡 DICA DE OURO: Esse 403 é a prova da nossa segurança!");
                console.log("A sua base de dados foi inteiramente isolada. Para que o teste de emissão rode agora, você (ou o Thiago) precisa:");
                console.log("1. Abrir o meiri App no Flutter");
                console.log("2. Ir na aba 'Perfil'");
                console.log("3. Fazer SELECIONAR CERTIFICADO .PFX novamente e por a senha");
                console.log("4. Apertar SALVAR.");
                console.log("Isso mandará a chave de vocês pro NOVO COFRE AES, aí a emissão vai rolar! 🛡️");
            }
        } else {
            console.error(error.message);
        }
    }
}

testEmissaoSoberana();
