const axios = require('axios');
const https = require('https');
const fs = require('fs');
const config = require('./config');

/**
 * SERPRO AUTH - MOTOR DE AUTENTICAÇÃO SOBERANO
 * 
 * Agora este módulo não guarda estado global com certificado fixo.
 * Ele gera agentes e tokens baseados no certificado fornecido em cada chamada.
 */
class SerproAuthManager {
    constructor() {
        // Cache de tokens por certPath para não fritar a API do Serpro desnecessariamente
        // Mas o ideal é que cada requisição de usuário use o seu
        this.tokenCache = new Map();
    }

    /**
     * Obtém um Agente HTTPS e Tokens para um certificado específico
     * @param {string} certPath 
     * @param {string} certPassword 
     * @param {boolean} isProducao
     */
    async getTokens(certPath, certPassword, isProducao = false) {
        const cacheKey = certPath;
        const agora = Date.now();
        const cached = this.tokenCache.get(cacheKey);

        if (cached && cached.expiresAt > agora + 300000) { // 5 min de margem
            return {
                bearer: cached.bearer,
                jwt: cached.jwt,
                agente: this._createAgent(certPath, certPassword, isProducao)
            };
        }

        console.log(`🔄 [Soberano] Renovando tokens SERPRO (${isProducao ? 'REAL' : 'TESTE'}) para o certificado: ${certPath}`);

        const credenciaisBase64 = Buffer.from(
            `${process.env.SERPRO_CLIENT_ID}:${process.env.SERPRO_CLIENT_SECRET}`
        ).toString('base64');

        const urlAuth = isProducao 
            ? 'https://autenticacao.sapi.serpro.gov.br/authenticate'
            : 'https://autenticacao.sapi.serpro.gov.br/authenticate'; // O Serpro usa endpoint unico, mas o mTLS define o contexto. 

        const agente = this._createAgent(certPath, certPassword, isProducao);

        try {
            const response = await axios({
                method: 'POST',
                url: urlAuth,
                headers: {
                    'Authorization': `Basic ${credenciaisBase64}`,
                    'Role-Type': 'TERCEIROS', // Pode ser 'CONTRIBUINTE' se for o próprio, mas 'TERCEIROS' costuma funcionar pra ambos
                    'Content-Type': 'application/x-www-form-urlencoded'
                },
                data: 'grant_type=client_credentials',
                httpsAgent: agente
            });

            const tokens = {
                bearer: response.data.access_token,
                jwt: response.data.jwt_token,
                expiresAt: agora + (response.data.expires_in * 1000)
            };

            this.tokenCache.set(cacheKey, tokens);

            return {
                bearer: tokens.bearer,
                jwt: tokens.jwt,
                agente: agente
            };

        } catch (erro) {
            console.error('❌ [Serpro Auth] Erro na renovação soberana:', erro.response?.data || erro.message);
            throw new Error(`Falha na autenticação com o Governo usando seu certificado: ${erro.message}`);
        }
    }

    _createAgent(certPath, certPassword, isProducao = false) {
        if (!fs.existsSync(certPath)) {
            throw new Error(`Arquivo de certificado não encontrado: ${certPath}`);
        }
        return new https.Agent({
            pfx: fs.readFileSync(certPath),
            passphrase: certPassword,
            rejectUnauthorized: isProducao // Trava meticulosa
        });
    }
}

module.exports = new SerproAuthManager();
