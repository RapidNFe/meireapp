const { SignedXml } = require('xml-crypto');
const crypto = require('crypto');
const { generateKeyPairSync } = crypto;
const { privateKey } = generateKeyPairSync('rsa', { modulusLength: 2048, privateKeyEncoding: { type: 'pkcs8', format: 'pem'} });

const xmlBruto = '<DPS xmlns="http://www.sped.fazenda.gov.br/nfse" versao="1.01"><infDPS Id="DPS123"><tpAmb>1</tpAmb></infDPS></DPS>';

const sig = new SignedXml({signatureAlgorithm: 'http://www.w3.org/2001/04/xmldsig-more#rsa-sha256'});
sig.canonicalizationAlgorithm = 'http://www.w3.org/TR/2001/REC-xml-c14n-20010315';

sig.addReference({
  xpath: '//*[local-name(.)=\'infDPS\' and @Id=\'DPS123\']',
  transforms: ['http://www.w3.org/2000/09/xmldsig#enveloped-signature', 'http://www.w3.org/TR/2001/REC-xml-c14n-20010315'],
  digestAlgorithm: 'http://www.w3.org/2001/04/xmlenc#sha256',
  uri: '#DPS123'
});

sig.privateKey = privateKey;
sig.computeSignature(xmlBruto);

console.log("=== xml-crypto .getSignedXml() ===");
console.log(sig.getSignedXml());

console.log("\n=== string injection ===");
const xmlSignature = sig.signatureXml;
console.log(xmlBruto.replace('</DPS>', xmlSignature + '</DPS>'));

console.log("\n=== are they equal? ===");
console.log(sig.getSignedXml() === xmlBruto.replace('</DPS>', xmlSignature + '</DPS>'));
