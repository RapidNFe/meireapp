const axios = require('axios');
const https = require('https');
const fs = require('fs');
require('dotenv').config();

class SerproAuthManager {
    constructor() {
        // O Cofre da Memória RAM
        this.bearerToken = null;
        this.jwtToken = null;
        this.expiresAt = null;

        // O Túnel mTLS fica montado e pronto para uso
        this.agenteSeguro = new https.Agent({
            pfx: fs.readFileSync(process.env.CAMINHO_CERTIFICADO_PFX || './certs/SAID CONTABILIDADE E TREINAMENTOS CONTABEIS LTDA_28413885000170 senha Said2026++.pfx'),
            passphrase: process.env.SERPRO_CERTIFICADO_SENHA,
            rejectUnauthorized: false
        });
    }

    async getTokens() {
        const agora = Date.now();
        const margemSeguranca = 5 * 60 * 1000; // Renova 5 minutos antes de expirar

        // 1. VERIFICAÇÃO DO CACHE: Tem chave e ela ainda está válida?
        if (this.bearerToken && this.jwtToken && this.expiresAt && (agora < this.expiresAt - margemSeguranca)) {
            console.log('⚡ [CACHE SAPI] Entregando chaves direto da memória RAM (0 lentidão).');
            return { 
                bearer: this.bearerToken, 
                jwt: this.jwtToken,
                agente: this.agenteSeguro
            };
        }

        // 2. RENOVAÇÃO OFICIAL: Se não tem ou está vencendo, pede uma nova ao Governo
        console.log('🔄 [RENOVAÇÃO SAPI] Indo até a Receita buscar novas chaves duplas...');
        
        const credenciaisBase64 = Buffer.from(
            `${process.env.SERPRO_CONSUMER_KEY}:${process.env.SERPRO_CONSUMER_SECRET}`
        ).toString('base64');

        try {
            const authResponse = await axios({
                method: 'POST',
                url: 'https://autenticacao.sapi.serpro.gov.br/authenticate',
                headers: {
                    'Authorization': `Basic ${credenciaisBase64}`,
                    'Role-Type': 'TERCEIROS',
                    'Content-Type': 'application/x-www-form-urlencoded'
                },
                data: 'grant_type=client_credentials',
                httpsAgent: this.agenteSeguro
            });

            // 3. ATUALIZA O COFRE
            this.bearerToken = authResponse.data.access_token;
            this.jwtToken = authResponse.data.jwt_token;
            // expires_in vem em segundos (ex: 3600). Multiplicamos por 1000 para milissegundos.
            this.expiresAt = agora + (authResponse.data.expires_in * 1000);

            console.log(`✅ [COFRE ATUALIZADO] Novas chaves guardadas. Válidas até: ${new Date(this.expiresAt).toLocaleTimeString()}`);

            return { 
                bearer: this.bearerToken, 
                jwt: this.jwtToken,
                agente: this.agenteSeguro
            };

        } catch (erro) {
            console.error('❌ [FALHA CRÍTICA SAPI] Não foi possível renovar as chaves:', erro.message);
            throw erro;
        }
    }
}

// O pulo do gato: exportamos a INSTÂNCIA, não a classe. 
// Isso garante que o Node.js inteiro compartilhe a mesma memória RAM.
module.exports = new SerproAuthManager();
