const axios = require('axios');
const fs = require('fs');
const https = require('https');
const path = require('path');
require('dotenv').config();

async function probeOfficialApiPaths() {
    console.log("🕵️‍♂️ PROBING OFFICIAL NFS-E NATIONAL API PATHS...");

    const agent = new https.Agent({
        pfx: fs.readFileSync(path.resolve(__dirname, process.env.CERT_PATH_PROD || './certs/said.pfx')),
        passphrase: process.env.CERT_PASSWORD,
        rejectUnauthorized: false
    });

    const trials = [
        'https://www.nfse.gov.br/swagger/v1/swagger.json',
        'https://www.nfse.gov.br/api/swagger.json',
        'https://www.nfse.gov.br/api/v1/swagger.json',
        'https://adn.nfse.gov.br/swagger.json',
        'https://adn.nfse.gov.br/docs/index.html'
    ];

    for (const url of trials) {
        console.log(`\n🧪 Testing: ${url}`);
        try {
            const response = await axios({
                method: 'GET',
                url: url,
                httpsAgent: agent,
                timeout: 5000
            });
            console.log(`✅ Success! Status: ${response.status}`);
            console.log("Body snippet:", JSON.stringify(response.data).substring(0, 500));
        } catch (error) {
            console.log(`❌ Status: ${error.response ? error.response.status : error.message}`);
        }
    }
}

probeOfficialApiPaths();
