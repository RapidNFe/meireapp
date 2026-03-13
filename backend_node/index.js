const { gerarXmlDPS } = require('./gerador_dps');
const { enviarParaADN } = require('./enviador_adn');
const { assinarComNodeForge } = require('./assinador_soberano'); 
const fs = require('fs');

/**
 * Motor Antigravity - Versão Soberana (Apenas Referência)
 * 
 * Este arquivo serve como referência de como o motor executa o fluxo
 * de emissão nacional. Na produção, o servidor server.js gerencia 
 * os certificados dinamicamente por usuário.
 */
async function processarEmissao(payload, certPath, certPass) {
  console.log("🚀 [MOTOR] Iniciando fluxo de emissão Soberano...");

  try {
    const { idDPS, xmlAssinavel } = gerarXmlDPS(payload);
    const xmlAssinado = assinarComNodeForge(xmlAssinavel, certPath, certPass, idDPS);
    const respostaSefaz = await enviarParaADN(xmlAssinado, certPath, certPass);
    return respostaSefaz;
  } catch (erro) {
    console.error("❌ Erro no motor:", erro.message);
  }
}

module.exports = { processarEmissao };
