// config.js
const path = require('path');
const fs = require('fs');
const envPath = path.resolve(__dirname, '.env');

try {
    const envConfig = require('dotenv').parse(fs.readFileSync(envPath));
    for (const k in envConfig) {
        process.env[k] = envConfig[k];
    }
} catch (err) {
    // Silencioso aqui para não poluir
}

const isProducao = process.env.NODE_ENV === 'producao';

const config = {
    isProducao: isProducao,
    serpro: {
        baseUrl: isProducao 
            ? 'https://gateway.apiserpro.serpro.gov.br/integra-contador/v1' 
            : 'https://gateway.apiserpro.serpro.gov.br/integra-contador-homologacao/v1',
        tpAmb: isProducao ? 1 : 2, // 1 = Real, 2 = Testes
        authUrl: 'https://autenticacao.sapi.serpro.gov.br/authenticate',
        // Default values for Integra Contador requests, can be overridden per request
        idSistema: "NFSE", // Mandatory for Integra Contador
        idServico: "EMISSAO_NOTA", // Mandatory for Integra Contador
        // Nota: O SERPRO costuma usar o mesmo endpoint de token para ambos, 
        // mas o certificado e as credenciais definem o ambiente.
    },
    pocketbase: {
        url: process.env.PB_URL || 'https://abu-boss-gain-mere.trycloudflare.com',
        adminEmail: process.env.PB_ADMIN_EMAIL,
        adminPassword: process.env.PB_ADMIN_PASSWORD
    },
    servidor: {
        port: process.env.PORT || 3000
    }
};

module.exports = config;
