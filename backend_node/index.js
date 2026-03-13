const { gerarXmlDPS } = require('./gerador_dps');
const { enviarParaADN } = require('./enviador_adn');
const { assinarComNodeForge } = require('./assinador_soberano'); 
const fs = require('fs');
require('dotenv').config();

const CAMINHO_CERTIFICADO = process.env.CERT_PATH_PROD || './certs/said.pfx';
const SENHA_CERTIFICADO = process.env.CERT_PASSWORD;

/**
 * Motor Antigravity - Fluxo Principal de Emissão
 */
async function processarEmissao(payloadFlutter) {
  console.log("🚀 [MOTOR] Iniciando fluxo de emissão NFS-e Nacional...");

  try {
    // PASSO 1: JSON -> XML (Fábrica)
    console.log("⚙️ [MOTOR] Passo 1: Construindo Árvore XML...");
    const { idDPS, xmlAssinavel } = gerarXmlDPS(payloadFlutter);
    console.log(`✅ [MOTOR] XML gerado. ID da Nota: ${idDPS}`);

    // PASSO 2: Assinatura Digital (Soberania)
    console.log("🖋️ [MOTOR] Passo 2: Assinando XML com RSA-SHA256...");
    const xmlAssinado = assinarComNodeForge(xmlAssinavel, CAMINHO_CERTIFICADO, SENHA_CERTIFICADO, idDPS);
    console.log("✅ [MOTOR] XML assinado com sucesso.");
    fs.writeFileSync('temp_assinado.xml', xmlAssinado);

    // PASSO 3: Envio Seguro mTLS (Impacto)
    console.log("🌐 [MOTOR] Passo 3: Transmitindo para o Governo...");
    const respostaSefaz = await enviarParaADN(xmlAssinado, CAMINHO_CERTIFICADO, SENHA_CERTIFICADO);

    // Avaliando o Retorno
    if (respostaSefaz.sucesso) {
      console.log("\n🎉 [VITÓRIA] Nota Processada pela Receita Federal!");
      console.log(JSON.stringify(respostaSefaz.dados, null, 2));
      return respostaSefaz.dados;
    } else {
      console.log(`\n💥 [IMPACTO] O Governo rejeitou a nota (Regra de Negócio). Status HTTP: ${respostaSefaz.status}`);
      console.log(JSON.stringify(respostaSefaz.dados, null, 2));
      return respostaSefaz.dados;
    }

  } catch (erro) {
    console.error("\n❌ [FALHA CRÍTICA] O motor estolou antes de completar o ciclo:");
    console.error(erro);
  }
}

// =========================================================
// TESTE DE MESA (Simulando o gatilho puxado pelo Flutter)
// =========================================================
const payloadTeste = {
  ambiente: "1", 
  dataHoraEmissao: "2026-03-13T10:54:50-03:00",
  competencia: "2026-02-28",
  numeroSerie: "70000",
  numeroDPS: "3", 
  codigoMunicipioEmissor: "5208707",
  
  prestador: { cnpj: "65354705000152", opcaoSimplesNacional: "2", regimeEspecialTributacao: "0" },
  tomador: {
    cnpj: "23061036000180", nome: "DEBORA CORTES UNIPESSOAL LTDA",
    endereco: { municipio: "5208707", cep: "74820090", logradouro: "AV SEGUNDA RADIAL", numero: "1307", complemento: "Q 145", bairro: "PEDRO LUDOVICO" }
  },
  servico: { municipioPrestacao: "5208707", codigoTribNacional: "060101", descricao: "Servico Antigravity Teste", valor: "7889.70" }
};

// Puxando o gatilho
processarEmissao(payloadTeste);
