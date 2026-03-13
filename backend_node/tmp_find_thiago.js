const PocketBase = require('pocketbase/cjs');
const pb = new PocketBase('http://127.0.0.1:8090');

async function findThiago() {
  try {
    await pb.collection('_superusers').authWithPassword('rapidnfeteste212@gmail.com', 'Said2026++');
    const record = await pb.collection('clientes').getFirstListItem('cnpj="65354705000152"');
    console.log(JSON.stringify(record, null, 2));
  } catch (err) {
    console.error('Error finding Thiago:', err.message);
  }
}

findThiago();
