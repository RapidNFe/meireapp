require('dotenv').config();
const fs = require('fs');
const https = require('https');
const axios = require('axios');

async function testarConexaoReceita() {
    console.log('🛡️ Iniciando comunicação oficial com o Serpro...');

    try {
        // 1. Carrega o certificado físico
        const pfxPath = process.env.CAMINHO_CERTIFICADO_PFX || './certs/SAID CONTABILIDADE E TREINAMENTOS CONTABEIS LTDA_28413885000170 senha Said2026++.pfx';
        const pfxPassword = process.env.SERPRO_CERTIFICADO_SENHA;
        
        if (!fs.existsSync(pfxPath)) {
            throw new Error(`Arquivo do certificado não encontrado em: ${pfxPath}`);
        }

        const certificadoPfx = fs.readFileSync(pfxPath);

        // 2. Monta o túnel seguro (mTLS)
        const agenteSeguro = new https.Agent({
            pfx: certificadoPfx,
            passphrase: pfxPassword,
            rejectUnauthorized: false
        });

        // 3. Prepara as credenciais em Base64
        const credenciaisBase64 = Buffer.from(
            `${process.env.SERPRO_CONSUMER_KEY}:${process.env.SERPRO_CONSUMER_SECRET}`
        ).toString('base64');

        console.log('⏳ Solicitando Token Bearer ao Governo...');

        // 4. Bate na porta do Governo
        const resposta = await axios({
            method: 'POST',
            url: 'https://gateway.apiserpro.serpro.gov.br/token',
            headers: {
                'Authorization': `Basic ${credenciaisBase64}`,
                'Content-Type': 'application/x-www-form-urlencoded'
            },
            data: 'grant_type=client_credentials',
            httpsAgent: agenteSeguro
        });

        console.log('\n✅ SUCESSO ABSOLUTO! A porta abriu.');
        console.log('🔑 Seu Token Oficial (Validade de ~60min):');
        console.log(resposta.data.access_token);
        console.log('\nA arquitetura da Meire está oficialmente conectada à Receita Federal.');

    } catch (erro) {
        console.error('\n❌ Falha na conexão com o Serpro:');
        if (erro.response) {
            console.error('Status:', erro.response.status);
            console.error('Detalhe:', erro.response.data);
        } else {
            console.error(erro.message);
        }
    }
}

testarConexaoReceita();
