const sqlite3 = require('sqlite3').verbose();
const DB_PATH = 'C:/Users/Fernando/Desktop/pocketbase/pb_data/data.db';

function query(sql, params = []) {
    return new Promise((resolve, reject) => {
        const db = new sqlite3.Database(DB_PATH);
        db.all(sql, params, (err, rows) => {
            db.close();
            if (err) reject(err);
            else resolve(rows);
        });
    });
}

async function run() {
    try {
        console.log("🔍 Buscando por 'Ana'...");
        const clients = await query("SELECT id, user, razao_social, cnpj, email FROM clientes_tomadores WHERE razao_social LIKE '%Ana%'");
        console.log("👥 Clientes encontrados:", JSON.stringify(clients, null, 2));

        if (clients.length > 0) {
            const userId = clients[0].user;
            const users = await query("SELECT id, name, cnpj, possui_certificado FROM users WHERE id = ?", [userId]);
            console.log("👤 Usuário proprietário:", JSON.stringify(users, null, 2));

            const certificates = await query("SELECT id, arquivo_pfx FROM cofre_certificados WHERE usuario = ?", [userId]);
            console.log("🔐 Certificados no cofre:", JSON.stringify(certificates, null, 2));
        }

    } catch (e) {
        console.error("❌ Erro:", e.message);
    }
}

run();
