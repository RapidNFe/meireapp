const config = require('./config');
const PocketBase = require('pocketbase/cjs');
const pb = new PocketBase(config.pocketbase.url);

async function testAuth() {
    console.log('Testing auth with:', config.pocketbase.adminEmail);
    try {
        const authData = await pb.collection('_superusers').authWithPassword(config.pocketbase.adminEmail, config.pocketbase.adminPassword);
        console.log('✅ Auth successful! Token:', authData.token ? 'exists' : 'null');
        
        console.log('Testing access to cofre_certificados...');
        const list = await pb.collection('cofre_certificados').getList(1, 1);
        console.log('✅ Access successful! Items found:', list.totalItems);
    } catch (e) {
        console.error('❌ Auth failed:', e.message);
        console.error('Error detail:', JSON.stringify(e.data || e.response || {}, null, 2));
    }
}

testAuth();
