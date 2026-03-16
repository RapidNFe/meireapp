const { gerarXmlDPS } = require('./gerador_dps');
const { enviarParaADN } = require('./enviador_adn');
const { assinarComNodeForge } = require('./assinador_soberano'); 
const fs = require('fs');
const zlib = require('zlib');

const config = require('./config');

/**
 * VORTEX - MOTOR DINÂMICO DE EMISSÃO NACIONAL
 * 
 * @param {Object} payload - Dados da nota (Prestador, Tomador, Serviço)
 * @param {string} certPath - Caminho absoluto ou relativo para o arquivo .pfx
 * @param {string} certPassword - Senha do certificado
 * @param {boolean} isProducao - Trava de segurança Real vs Teste do Usuário
 * @returns {Promise<Object>} - Resultado da emissão
 */
async function emitirNacional(payload, certPath, certPassword, isProducao) {
  console.log(`🚀 [VORTEX] Iniciando emissão para CNPJ ${payload.prestador.cnpj}...`);

  try {
    // 1. GERAÇÃO DO XML DPS
    const { idDPS, xmlAssinavel } = gerarXmlDPS(payload);
    console.log(`✅ [VORTEX] XML DPS Gerado: ${idDPS}`);
    console.log("=== XML ASSINÁVEL ===");
    console.log(xmlAssinavel);
    console.log("=====================");

    // 2. ASSINATURA DIGITAL
    // Passamos o certificado e senha dinâmicos do cliente
    const xmlAssinado = assinarComNodeForge(xmlAssinavel, certPath, certPassword, idDPS);
    console.log("🖋️ [VORTEX] XML Assinado com sucesso.");

    // 3. TRANSMISSÃO ADN (Sefin Nacional)
    console.log(`🌐 [VORTEX] Transmitindo para o Ambiente [${isProducao ? 'PRODUÇÃO' : 'TESTE'}]...`);
    const resposta = await enviarParaADN(xmlAssinado, certPath, certPassword, isProducao);

    if (resposta.sucesso && resposta.dados.chaveAcesso) {
      console.log(`🏆 [VORTEX] SUCESSO! Chave: ${resposta.dados.chaveAcesso}`);
      
      // Decodificação opcional para log/auditoria
      if (resposta.dados.nfseXmlGZipB64) {
        const bufferGzip = Buffer.from(resposta.dados.nfseXmlGZipB64, 'base64');
        resposta.dados.xmlDecodificado = zlib.gunzipSync(bufferGzip).toString('utf-8');
      }
      
      return { sucesso: true, dados: resposta.dados };
    } else {
      console.error("❌ [VORTEX] O Governo rejeitou a nota.");
      return { sucesso: false, dados: resposta.dados, status: resposta.status };
    }

  } catch (error) {
    console.error("💥 [VORTEX] Falha catastrófica no motor:", error.message);
    throw error;
  }
}

module.exports = { emitirNacional };
