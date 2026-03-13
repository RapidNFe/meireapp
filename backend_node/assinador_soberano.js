const forge = require('node-forge');
const { SignedXml } = require('xml-crypto');
const fs = require('fs');
const path = require('path');

/**
 * ASSINADOR SOBERANO - VERSÃO "FORCED KEYINFO"
 * Esta versão garante que o certificado público SEJA incluído no XML.
 */
function assinarComNodeForge(xmlBruto, caminhoPfx, senha, idDPS) {
  const p12Der = fs.readFileSync(path.resolve(caminhoPfx)).toString('binary');
  const p12Asn1 = forge.asn1.fromDer(p12Der);
  const p12 = forge.pkcs12.pkcs12FromAsn1(p12Asn1, false, senha);

  let chavePrivadaPem = '';
  let certificadoPem = '';

  const keyBags = p12.getBags({ bagType: forge.pki.oids.pkcs8ShroudedKeyBag });
  const certBags = p12.getBags({ bagType: forge.pki.oids.certBag });

  if (keyBags[forge.pki.oids.pkcs8ShroudedKeyBag] && keyBags[forge.pki.oids.pkcs8ShroudedKeyBag].length > 0) {
      chavePrivadaPem = forge.pki.privateKeyToPem(keyBags[forge.pki.oids.pkcs8ShroudedKeyBag][0].key);
  }

  if (certBags[forge.pki.oids.certBag] && certBags[forge.pki.oids.certBag].length > 0) {
      certificadoPem = forge.pki.certificateToPem(certBags[forge.pki.oids.certBag][0].cert);
  }

  const certLimpo = certificadoPem
    .replace(/-----(BEGIN|END) CERTIFICATE-----/g, "")
    .replace(/\s+/g, "");

  const sig = new SignedXml({
    signatureAlgorithm: "http://www.w3.org/2001/04/xmldsig-more#rsa-sha256"
  });
  
  sig.canonicalizationAlgorithm = "http://www.w3.org/2001/10/xml-exc-c14n#";
  
  sig.addReference({
    xpath: `//*[local-name(.)='infDPS' and @Id='${idDPS}']`, 
    transforms: [
      "http://www.w3.org/2000/09/xmldsig#enveloped-signature",
      "http://www.w3.org/2001/10/xml-exc-c14n#" 
    ],
    digestAlgorithm: "http://www.w3.org/2001/04/xmlenc#sha256",
    uri: `#${idDPS}`
  });

  sig.privateKey = Buffer.from(chavePrivadaPem);
  
  // 🎯 KEYINFO - Forçamos a injeção do conteúdo X509Certificate
  sig.keyInfoAttributes = { xmlns: "http://www.w3.org/2000/09/xmldsig#" };
  sig.getKeyInfoContent = () => {
    return `<X509Data><X509Certificate>${certLimpo}</X509Certificate></X509Data>`;
  };

  sig.computeSignature(xmlBruto, {
    location: { reference: `//*[local-name(.)='infDPS' and @Id='${idDPS}']`, action: "after" }
  });
  
  return sig.getSignedXml();
}

module.exports = { assinarComNodeForge };
