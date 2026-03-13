const axios = require('axios');
const https = require('https');
const fs = require('fs');
const path = require('path');
require('dotenv').config();

async function probeSefinProducao() {
  const certificadoPfx = fs.readFileSync(path.resolve(process.env.CERT_PATH_PROD || './certs/said.pfx'));
  const agenteHttpsMtls = new https.Agent({
    pfx: certificadoPfx,
    passphrase: process.env.CERT_PASSWORD,
    rejectUnauthorized: false
  });

  const urlAlvo = 'https://sefin.nfse.gov.br/SefinNacional/nfse'; 
  console.log(`🎯 Testando: ${urlAlvo}`);
  try {
    const resposta = await axios.post(urlAlvo, { "dpsXmlGZipB64": "teste" }, {
      httpsAgent: agenteHttpsMtls,
      headers: { 'Content-Type': 'application/json', 'Accept': 'application/json' }
    });
    console.log("✅ OK", resposta.data);
  } catch (error) {
    console.log("❌ Status:", error.response?.status, error.response?.data);
  }
}
probeSefinProducao();
