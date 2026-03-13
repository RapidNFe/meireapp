const forge = require('node-forge');
const { SignedXml } = require('xml-crypto');
const fs = require('fs');
const path = require('path');

function assinarComNodeForge(xmlBruto, caminhoPfx, senha, idDPS) {
  // 1. Lendo o arquivo PFX binário
  const p12Der = fs.readFileSync(path.resolve(caminhoPfx)).toString('binary');
  const p12Asn1 = forge.asn1.fromDer(p12Der);
  
  // 2. Abrindo o cofre com a senha
  const p12 = forge.pkcs12.pkcs12FromAsn1(p12Asn1, false, senha);

  let chavePrivadaPem = '';
  let certificadoPem = '';

  // 3. Minerando a Chave Privada e o Certificado Público de dentro do PFX
  // Usando um método mais seguro para extrair os bags no node-forge
  const keyBags = p12.getBags({ bagType: forge.pki.oids.pkcs8ShroudedKeyBag });
  const certBags = p12.getBags({ bagType: forge.pki.oids.certBag });

  if (keyBags[forge.pki.oids.pkcs8ShroudedKeyBag] && keyBags[forge.pki.oids.pkcs8ShroudedKeyBag].length > 0) {
      const privateKey = keyBags[forge.pki.oids.pkcs8ShroudedKeyBag][0].key;
      chavePrivadaPem = forge.pki.privateKeyToPem(privateKey);
  }

  if (certBags[forge.pki.oids.certBag] && certBags[forge.pki.oids.certBag].length > 0) {
      const cert = certBags[forge.pki.oids.certBag][0].cert;
      certificadoPem = forge.pki.certificateToPem(cert);
  }

  if (!chavePrivadaPem) {
    throw new Error("Não foi possível extrair a Chave Privada do arquivo PFX.");
  }

  // 4. Configurando o Motor de Assinatura (xml-crypto)
  // xml-crypto v6+ expects some algorithms in the constructor via options
  const sig = new SignedXml({
    signatureAlgorithm: "http://www.w3.org/2001/04/xmldsig-more#rsa-sha256"
  });
  
  // A Sefaz Nacional exige algoritmo específico para a Canonicalization do SignedInfo inteiro
  sig.canonicalizationAlgorithm = "http://www.w3.org/2001/10/xml-exc-c14n#";
  
  // Adicionando a referência da tag que será assinada (o ID dinâmico)
  // Utilizando o formato de Objeto pois o xml-crypto v6+ removeu passagem posicional
  sig.addReference({
    xpath: `//*[local-name(.)='infDPS' and @Id='${idDPS}']`, 
    transforms: [
      "http://www.w3.org/2000/09/xmldsig#enveloped-signature",
      "http://www.w3.org/2001/10/xml-exc-c14n#" 
    ],
    digestAlgorithm: "http://www.w3.org/2001/04/xmlenc#sha256",
    uri: `#${idDPS}` // Forçando a URI vazada, ignora a injeção do validador (RNG6110)
  });

  // 🎯 Alimentando a chave privada no formato PEM para o xml-crypto v4+
  sig.privateKey = Buffer.from(chavePrivadaPem);

  // Injetando o certificado público na tag <KeyInfo> sem espaços
  const certLimpo = certificadoPem
    .replace(/-----(BEGIN|END) CERTIFICATE-----/g, "")
    .replace(/\s+/g, ""); // Remove QUALQUER espaço ou quebra de linha

  sig.keyInfoProvider = {
    getKeyInfo: () => `<X509Data><X509Certificate>${certLimpo}</X509Certificate></X509Data>`
  };

  // 5. Executando a assinatura matemática
  sig.computeSignature(xmlBruto, {
    location: { reference: `//*[@Id="${idDPS}"]`, action: "after" }
  });
  
  // Retornando o XML final, blindado e pronto para o Governo
  return sig.getSignedXml();
}

module.exports = { assinarComNodeForge };
