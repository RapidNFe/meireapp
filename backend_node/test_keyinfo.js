const { SignedXml } = require('xml-crypto');
const crypto = require('crypto');
const { generateKeyPairSync } = crypto;
const { privateKey } = generateKeyPairSync('rsa', { modulusLength: 2048, privateKeyEncoding: { type: 'pkcs8', format: 'pem'} });

const sig = new SignedXml();
sig.privateKey = privateKey;
sig.signatureAlgorithm = 'http://www.w3.org/2001/04/xmldsig-more#rsa-sha256';
sig.canonicalizationAlgorithm = 'http://www.w3.org/2001/10/xml-exc-c14n#';
sig.keyInfoProvider = {
  getKeyInfo: () => '<X509Data><X509Certificate>TEST</X509Certificate></X509Data>'
};
sig.addReference({
  xpath: '//*',
  transforms: ['http://www.w3.org/2000/09/xmldsig#enveloped-signature'],
  digestAlgorithm: 'http://www.w3.org/2001/04/xmlenc#sha256'
});
sig.computeSignature('<root></root>');
console.log(sig.getSignedXml());
