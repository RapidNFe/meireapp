const axios = require('axios');

async function testAuth() {
    try {
        const response = await axios.post('http://127.0.0.1:8090/api/collections/_superusers/auth-with-password', {
            identity: 'rapidnfeteste212@gmail.com',
            password: 'Said2026++'
        });
        console.log('Success with _superusers:', response.status);
    } catch (e) {
        console.log('Failed with _superusers:', e.response ? e.response.status : e.message);
        
        try {
            const response2 = await axios.post('http://127.0.0.1:8090/api/admins/auth-with-password', {
                email: 'rapidnfeteste212@gmail.com',
                password: 'Said2026++'
            });
            console.log('Success with admins:', response2.status);
        } catch (e2) {
            console.log('Failed with admins:', e2.response ? e2.response.status : e2.message);
        }
    }
}

testAuth();
