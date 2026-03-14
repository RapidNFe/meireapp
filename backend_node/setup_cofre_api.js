const PocketBase = require('pocketbase/cjs');
require('dotenv').config();

const pb = new PocketBase('http://127.0.0.1:8090');

async function fixCofre() {
    try {
        await pb.admins.authWithPassword(process.env.PB_ADMIN_EMAIL, process.env.PB_ADMIN_PASSWORD);
        let collection;
        try {
            collection = await pb.collections.getOne('cofre_certificados');
            console.log("Cofre já existe no PB.");
            await pb.collections.delete('cofre_certificados');
            console.log("Deletado para recriar puro pelo PB!");
        } catch (e) {}

        console.log("Criando collection através do SDK oficial...");
        collection = await pb.collections.create({
            name: 'cofre_certificados',
            type: 'base',
            system: false,
            schema: [
                { "name": "usuario", "type": "relation", "required": true, "options": { "collectionId": "_pb_users_auth_", "maxSelect": 1 } },
                { "name": "senha_encriptada", "type": "text", "required": true },
                { "name": "data_vencimento", "type": "date" },
                { "name": "arquivo_pfx", "type": "file", "required": true, "options": { "maxSelect": 1, "maxSize": 5242880 } },
                { "name": "valido", "type": "bool" }
            ],
        });
        console.log("✅ Collection Criada com SDK. O PB criou a tabela física SQLite.");
        
    } catch(err) {
        console.error("Erro API PB:");
        console.error("Status:", err.status);
        console.error("Data:", JSON.stringify(err.data, null, 2));
        console.error("Mensagem:", err.message);
        if (err.data && err.data.data) {
            console.error("Erros de Validação:", JSON.stringify(err.data.data, null, 2));
        }
    }
}

fixCofre();
