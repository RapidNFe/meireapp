const fs = require('fs');
const forge = require('node-forge');

function debugCertificado(pfxPath, senha) {
    try {
        const p12Der = fs.readFileSync(pfxPath).toString('binary');
        const p12Asn1 = forge.asn1.fromDer(p12Der);
        const p12 = forge.pkcs12.pkcs12FromAsn1(p12Asn1, senha);

        console.log("PFX Aberto com sucesso.");
        let validade = null;

        // Iterate through safe bags to find the end-entity certificate
        for (const safeContent of p12.safeContents) {
            for (const safeBag of safeContent.safeBags) {
                if (safeBag.type === forge.pki.oids.certBag) {
                    const cert = safeBag.cert;
                    validade = cert.validity.notAfter;
                    console.log("Certificado de:", cert.subject.getField('CN') ? cert.subject.getField('CN').value : 'Desconhecido');
                    console.log("Validade:", validade);
                }
            }
        }
    } catch(err) {
        console.error("Erro:", err.message);
    }
}

// Para testar você precisa de um pfx. Mas podemos deixar preparado!
