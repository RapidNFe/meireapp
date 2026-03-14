const axios = require('axios');
const https = require('https');
const fs = require('fs');
const zlib = require('zlib');
const path = require('path');

async function enviarParaADN(xmlAssinado, caminhoCertificado, senhaCertificado, isProducao = false) {
  console.log(`🗜️ [SEFIN] Compactando Buffer em modo [${isProducao ? 'REAL' : 'TESTE'}]...`);
  
  // Certifique-se de que o XML assinado não recebeu nenhum trim() ou alteração de string após a assinatura
  const xmlBuffer = Buffer.from(xmlAssinado, 'utf-8');
  const xmlGzipado = zlib.gzipSync(xmlBuffer);
  const stringBase64 = xmlGzipado.toString('base64');

  const payloadParaEnvio = {
    "dpsXmlGZipB64": stringBase64
  };

  // 2. Configurando o Agente mTLS
  console.log(`🛡️ [SEFIN] Configurando túnel seguro mTLS (${isProducao ? 'Rigoroso' : 'Permissivo'})...`);
  const certificadoPfx = fs.readFileSync(path.resolve(caminhoCertificado));
  const agenteHttpsMtls = new https.Agent({
    pfx: certificadoPfx,
    passphrase: senhaCertificado,
    rejectUnauthorized: isProducao // Trava meticulosa: em produção o TLS deve ser perfeito
  });

  const urlAlvo = isProducao 
    ? 'https://sefin.nfse.gov.br/SefinNacional/nfse' 
    : 'https://homologacao.sefin.nfse.gov.br/SefinNacional/nfse'; 

  console.log(`🎯 [SEFIN] Disparando contra: ${urlAlvo}`);
  
  try {
    const resposta = await axios.post(urlAlvo, payloadParaEnvio, {
      httpsAgent: agenteHttpsMtls,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      }
    });
    return { sucesso: true, status: resposta.status, dados: resposta.data };
  } catch (erro) {
    if (erro.response) {
      return { sucesso: false, status: erro.response.status, dados: erro.response.data };
    }
    throw new Error(`Falha crítica de infraestrutura: ${erro.message}`);
  }
}

module.exports = { enviarParaADN };
