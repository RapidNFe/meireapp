const PocketBase = require('pocketbase/cjs');
const config = require('./config');

async function test() {
    const pb = new PocketBase(config.pocketbase.url);
    try {
        console.log("🔗 Conectando ao PB:", config.pocketbase.url);
        await pb.collection('_superusers').authWithPassword(config.pocketbase.adminEmail, config.pocketbase.adminPassword);
        
        console.log("✅ Autenticado as Admin");

        const users = await pb.collection('users').getFullList({
            filter: 'status_registro = "ativado"',
            sort: '-updated'
        });
        console.log("👤 Usuários Ativados:", users.length);
        if (users.length > 0) {
            console.log("Último usuário ativado:", users[0].email, users[0].id);
        }

        const cofre = await pb.collection('cofre_certificados').getFullList({
            sort: '-updated'
        });
        console.log("🔐 Registros no Cofre:", cofre.length);
        if (cofre.length > 0) {
            console.log("Último certificado:", cofre[0].usuario, cofre[0].id);
        }

        const clientes = await pb.collection('clientes_tomadores').getFullList({
            filter: 'razao_social ~ "Ana" || apelido ~ "Ana"',
            sort: '-updated'
        });
        console.log("👥 Clientes 'Ana':", clientes.length);
        if (clientes.length > 0) {
            console.log("Cliente encontrado:", clientes[0].razao_social, clientes[0].id);
        }

    } catch (e) {
        console.error("❌ Erro:", e.message);
    }
}

test();
