// config.js
require('dotenv').config();

const isProducao = process.env.NODE_ENV === 'producao';

const config = {
    isProducao: isProducao,
    serpro: {
        baseUrl: isProducao 
            ? 'https://gateway.apiserpro.serpro.gov.br/integra-contador/v1' 
            : 'https://gateway.apiserpro.serpro.gov.br/integra-contador-homologacao/v1',
        tpAmb: isProducao ? 1 : 2, // 1 = Real, 2 = Testes
        certPath: isProducao ? (process.env.CERT_PATH_PROD || './certs/said_producao.pfx') : (process.env.CERT_PATH_HOMOLOG || './certs/said_homologacao.pfx'),
        authUrl: isProducao
            ? 'https://gateway.apiserpro.serpro.gov.br/token'
            : 'https://gateway.apiserpro.serpro.gov.br/token' 
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
