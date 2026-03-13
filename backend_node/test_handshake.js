const SerproIntegrador = require('./integrador_serpro');
const config = require('./config');
require('dotenv').config();

async function testHandshake() {
    console.log("🔍 Iniciando Teste de Aperto de Mãos (Handshake)...");
    
    // Forçar ambiente de produção para o teste se o usuário pediu validação 360 do link novo
    console.log(`🌍 Ambiente: ${config.isProducao ? 'PRODUÇÃO' : 'TESTES'}`);
    
    const integrador = new SerproIntegrador();
    
    try {
        const token = await integrador.autenticar();
        if (token) {
            console.log("✅ Aperto de mãos realizado com sucesso!");
            console.log("🎟️ Bearer Token obtido (Primeiros 20 caracteres):", token.substring(0, 20) + "...");
        } else {
            console.error("❌ Falha: Token não retornado.");
        }
    } catch (error) {
        console.error("❌ Erro no aperto de mãos:");
        console.error(error.message);
    }
}

testHandshake();
