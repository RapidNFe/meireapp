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
        const tables = ['users', 'notas_fiscais', 'clientes_tomadores', 'cofre_certificados'];
        
        for (const table of tables) {
            console.log(`\n--- SCHEMA: ${table} ---`);
            const info = await query(`PRAGMA table_info(${table})`);
            console.log(info.map(c => `${c.name} (${c.type})`).join(', '));
            
            console.log(`\n--- DATA: ${table} (Limit 3) ---`);
            const data = await query(`SELECT * FROM ${table} LIMIT 3`);
            console.log(JSON.stringify(data, null, 2));
        }

    } catch (e) {
        console.error("❌ Erro:", e.message);
    }
}

run();
