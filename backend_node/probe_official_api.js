const axios = require('axios');
const fs = require('fs');
const https = require('https');
const path = require('path');
require('dotenv').config();

async function probeOfficialApi() {
    console.log("🕵️‍♂️ PROBING OFFICIAL NFS-E NATIONAL API...");

    const pfxPath = path.resolve(__dirname, process.env.CERT_PATH_PROD || './certs/said.pfx');
    const pfxPassword = process.env.CERT_PASSWORD;

    if (!fs.existsSync(pfxPath)) {
        console.error("❌ Certificate not found at:", pfxPath);
        return;
    }

    const agent = new https.Agent({
        pfx: fs.readFileSync(pfxPath),
        passphrase: pfxPassword,
        rejectUnauthorized: false // During probe, we might encounter dev certs
    });

    const urls = [
        'https://www.nfse.gov.br/api/nfse',
        'https://adn.nfse.gov.br/nfse',
        'https://www.nfse.gov.br/api/v1/nfs-e'
    ];

    for (const url of urls) {
        console.log(`\n🧪 Testing: ${url}`);
        try {
            // Using HEAD or GET to see if it responds or requires specific headers/auth
            const response = await axios({
                method: 'GET',
                url: url,
                httpsAgent: agent,
                timeout: 5000
            });
            console.log(`✅ Success! Status: ${response.status}`);
            console.log("Body:", JSON.stringify(response.data).substring(0, 200));
        } catch (error) {
            if (error.response) {
                console.log(`❌ Status: ${error.response.status}`);
                console.log("Body:", JSON.stringify(error.response.data).substring(0, 200));
            } else {
                console.log(`❌ Error: ${error.message}`);
                if (error.code === 'ECONNREFUSED' || error.code === 'ENOTFOUND') {
                    console.log("   (Connectivity issue)");
                }
            }
        }
    }
}

probeOfficialApi();
