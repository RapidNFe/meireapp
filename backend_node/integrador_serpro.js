// ==========================================================
// SERPRO INTEGRA CONTADOR - O MOTOR OFICIAL INQUEBRÁVEL
// ==========================================================
require('dotenv').config();
const axios = require('axios');
const fs = require('fs');
const https = require('https');
const path = require('path');

class SerproIntegrador {
    constructor() {
        this.consumerKey = process.env.SERPRO_CONSUMER_KEY;
        this.consumerSecret = process.env.SERPRO_CONSUMER_SECRET;
        this.certPassword = process.env.SERPRO_CERTIFICADO_SENHA;

        // Caminho do seu certificado PFX (Configurado no .env)
        this.pfxPath = process.env.CAMINHO_CERTIFICADO_PFX
            ? path.resolve(__dirname, process.env.CAMINHO_CERTIFICADO_PFX)
            : path.resolve(__dirname, 'certs/SAID CONTABILIDADE E TREINAMENTOS CONTABEIS LTDA_28413885000170 senha Said2026++.pfx');
        
        // Token temporário em cache (Dura cerca de 60 minutos)
        this.accessToken = null;
    }

    /**
     * Gera o Agente HTTPS blindado com o Certificado Digital da Contabilidade
     */
    _getHttpsAgent() {
        if (!fs.existsSync(this.pfxPath)) {
            throw new Error(`[ERRO] Certificado não encontrado em ${this.pfxPath}! Salve o seu arquivo PFX aqui para o Serpro autenticar.`);
        }

        const pfxFile = fs.readFileSync(this.pfxPath);

        return new https.Agent({
            pfx: pfxFile,
            passphrase: this.certPassword,
            rejectUnauthorized: false // Em homologação pode ser necessário false
        });
    }

    /**
     * Passo 1: Troca as Credenciais e o Certificado pelo Token de Acesso VIP do Governo
     */
    async autenticar() {
        console.log('🔐 [Serpro] Contatando portal de autenticação...');

        // O Serpro exige Basic Auth em Base64 usando Key:Secret
        const rawAuth = `${this.consumerKey}:${this.consumerSecret}`;
        const b64Auth = Buffer.from(rawAuth).toString('base64');

        try {
            // URL Oficial de Autorização do Serpro / Integra Contador (Verifique a doc oficial para URL de Prod vs Homolog)
            const urlAuth = 'https://gateway.apiserpro.serpro.gov.br/token';

            const response = await axios.post(
                urlAuth,
                'grant_type=client_credentials', // Payload exigido
                {
                    httpsAgent: this._getHttpsAgent(), // O Certificado vai junto no aperto de mão TLS!
                    headers: {
                        'Authorization': `Basic ${b64Auth}`,
                        'Content-Type': 'application/x-www-form-urlencoded'
                    }
                }
            );

            this.accessToken = response.data.access_token;
            console.log('✅ [Serpro] Token VIP de Autorização recebido com sucesso!');
            return this.accessToken;

        } catch (erro) {
            console.error('❌ [Serpro] Erro de Autenticação:', erro.response ? erro.response.data : erro.message);
            throw new Error('Falha ao autenticar na API Oficial do Governo. Verifique as credenciais no .env e a validade do seu Certificado A1.');
        }
    }

    /**
     * Passo 2: Usa o Token para Buscar os Dados Diretamente no Banco de Dados da Receita (Exemplo: CNPJ)
     */
    async consultarDadosCliente(cnpjDoCliente) {
        if (!this.accessToken) {
            await this.autenticar();
        }

        console.log(`📡 [Serpro] Escaneando banco central para o CNPJ ${cnpjDoCliente}...`);

        try {
            // O endpoint específico depende do contrato no Integra Contador (Exemplo genérico RFB)
            const urlEndpoint = `https://gateway.apiserpro.serpro.gov.br/integra-contador/v1/empresas/${cnpjDoCliente}`;

            const response = await axios.get(urlEndpoint, {
                httpsAgent: this._getHttpsAgent(),
                headers: {
                    'Authorization': `Bearer ${this.accessToken}`,
                    'Accept': 'application/json'
                }
            });

            console.log(`✅ [Serpro] Ficha extraída instantaneamente (Zero Captchas)!`);
            return response.data;
        } catch (erro) {
            // Se o token expirou (401), podemos tentar renovar e chamar recursivamente 1 vez.
            if (erro.response && erro.response.status === 401) {
                console.log('🔄 [Serpro] Token expirado. Renovando Mágica...');
                this.accessToken = null;
                await this.autenticar();
                return this.consultarDadosCliente(cnpjDoCliente);
            }

            console.error(`❌ [Serpro] Falha na extração de ${cnpjDoCliente}:`, erro.response ? erro.response.data : erro.message);
            throw erro;
        }
    }
}

module.exports = SerproIntegrador;

// === TESTE RÁPIDO ===
// Se você quiser testar se o arquivo .env e o Certificado estão perfeitos,
// Basta descomentar as linhas abaixo, jogar seu PFX na pasta com o nome 'certificado_said.pfx' e rodar 'node integrador_serpro.js'

/*
(async () => {
    try {
        const serpro = new SerproIntegrador();
        await serpro.autenticar();
        console.log('Tudo verde! A conexão com a máquina pública federal está aberta.');
    } catch (e) {
        console.log('Aguardando configuração de chaves...');
    }
})();
*/
