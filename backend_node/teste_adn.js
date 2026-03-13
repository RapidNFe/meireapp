const axios = require('axios');
const https = require('https');
const fs = require('fs');
const zlib = require('zlib');
const path = require('path');
require('dotenv').config();

async function dispararMotorAntigravity() {
  console.log("🚀 Iniciando sequência de ignição (NFS-e Nacional ADN)...");

  try {
    const caminhoCertificado = path.resolve(__dirname, process.env.CERT_PATH_PROD || './certs/said.pfx'); 
    const senhaCertificado = process.env.CERT_PASSWORD; 
    const caminhoXml = path.resolve(__dirname, './52087072265354705000152000000000000126035878550339.xml');

    console.log("📦 Carregando Certificado e XML...");
    
    if (!fs.existsSync(caminhoCertificado)) {
         throw new Error(`Certificado não encontrado: ${caminhoCertificado}`);
    }
    const certificadoPfx = fs.readFileSync(caminhoCertificado);
    const xmlBruto = fs.readFileSync(caminhoXml, 'utf-8');

    console.log("🗜️ Compactando (GZip) e codificando (Base64)...");
    const xmlGzipado = zlib.gzipSync(xmlBruto);
    const stringBase64 = xmlGzipado.toString('base64');

    const payloadParaEnvio = {
      "LoteXmlGZipB64": [ stringBase64 ]
    };

    console.log("🛡️ Configurando túnel seguro mTLS...");
    const agenteHttpsMtls = new https.Agent({
      pfx: certificadoPfx,
      passphrase: senhaCertificado,
      rejectUnauthorized: false
    });

    const urlAlvo = 'https://adn.producaorestrita.nfse.gov.br/adn/DFe'; 

    console.log(`🎯 Disparando contra: ${urlAlvo}`);
    const resposta = await axios.post(urlAlvo, payloadParaEnvio, {
      httpsAgent: agenteHttpsMtls,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      }
    });

    console.log("\n✅ [IMPACTO CONFIRMADO] O Governo respondeu com Sucesso (Status 20X)!");
    console.log(JSON.stringify(resposta.data, null, 2));

  } catch (erro) {
    console.log("\n💥 [IMPACTO CONFIRMADO] O Governo barrou a requisição, mas nós chegamos lá!");
    
    if (erro.response) {
      console.log(`Status HTTP: ${erro.response.status}`);
      console.log("Mensagem da SEFAZ:");
      console.log(JSON.stringify(erro.response.data, null, 2));
    } else {
      console.error("❌ Falha de Conexão/Infraestrutura:", erro.message);
    }
  }
}

dispararMotorAntigravity();
