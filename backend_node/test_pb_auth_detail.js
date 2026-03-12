const axios = require('axios');

async function testAuth() {
    try {
        const response = await axios.post('http://127.0.0.1:8090/api/collections/_superusers/auth-with-password', {
            identity: 'rapidnfeteste212@gmail.com',
            password: 'Said2026++'
        });
        console.log('Success with _superusers:', response.status);
    } catch (e) {
        console.log('Failed with _superusers:', e.response ? JSON.stringify(e.response.data) : e.message);
    }
}

testAuth();
