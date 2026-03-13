const { SignedXml } = require('xml-crypto');
const fs = require('fs');
const { DOMParser } = require('@xmldom/xmldom');
require('dotenv').config();

function auditSignature() {
  try {
    const xml = fs.readFileSync('temp_assinado.xml', 'utf-8');
    const doc = new DOMParser().parseFromString(xml);
    
    // 1. Localizar Signature
    const signatures = doc.getElementsByTagNameNS("http://www.w3.org/2000/09/xmldsig#", "Signature");
    const signatureNode = signatures[0];
    if (!signatureNode) throw new Error("Tag <Signature> não encontrada!");

    const sig = new SignedXml();
    sig.loadSignature(signatureNode);

    // 2. Extrair Certificado do XML para validar (se houver)
    const certificates = doc.getElementsByTagNameNS("*", "X509Certificate");
    if (certificates.length > 0) {
        const certContent = certificates[0].textContent.replace(/\s+/g, "");
        const certPem = `-----BEGIN CERTIFICATE-----\n${certContent.match(/.{1,64}/g).join('\n')}\n-----END CERTIFICATE-----`;
        sig.publicCert = Buffer.from(certPem);
    } else {
        console.warn("⚠️  Aviso: Tag <X509Certificate> não encontrada no XML. Isso PODE ser o motivo do erro E0714!");
        // Tenta carregar do arquivo .env como fallback para o teste local
        if (process.env.CERT_PATH_PROD) {
             console.log("ℹ️  Tentando validar usando o certificado local do .env...");
             // Este trecho precisaria extrair do PFX, mas vamos focar no fato de que ESTÁ FALTANDO no XML
        }
    }

    // 3. Validar
    const isValid = sig.checkSignature(xml);
    
    console.log("\n🔍 --- RELATÓRIO DE AUDITORIA ---");
    console.log(isValid ? "✅ ASSINATURA MATEMATICAMENTE VÁLIDA (O Hash bate)" : "❌ ASSINATURA MATEMATICAMENTE INVÁLIDA");
    
    if (!isValid) {
      console.log("\n⚠️ DETALHES DO ERRO:");
      if (sig.validationErrors && sig.validationErrors.length > 0) {
        sig.validationErrors.forEach(err => console.log("- " + err));
      } else {
        console.log("- Erro desconhecido na validação.");
      }
    }

    if (certificates.length === 0) {
        console.log("\n🚨 CONCLUSÃO CRÍTICA: O XML está assinado, mas o CERTIFICADO PÚBLICO não foi incluído na tag <KeyInfo>. O Governo REJEITA notas sem o certificado embutido.");
    }

  } catch (err) {
    console.error("Erro no scanner:", err.message);
  }
}

auditSignature();
