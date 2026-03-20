const sqlite3 = require('sqlite3').verbose();
const path = require('path');

const DB_PATH = 'C:/Users/Fernando/Desktop/pocketbase/pb_data/data.db';

async function updateSchema() {
    const db = new sqlite3.Database(DB_PATH);

    const columnsToAdd = [
        { name: 'cep', type: 'TEXT' },
        { name: 'logradouro', type: 'TEXT' },
        { name: 'numero', type: 'TEXT' },
        { name: 'bairro', type: 'TEXT' },
        { name: 'municipio_ibge', type: 'TEXT' },
        { name: 'cidade_nome', type: 'TEXT' },
        { name: 'uf', type: 'TEXT' }
    ];

    db.serialize(() => {
        // 1. Get current columns
        db.all("PRAGMA table_info(clientes_tomadores)", (err, rows) => {
            if (err) {
                console.error("Error checking table info:", err);
                return;
            }

            const existingColumns = rows.map(r => r.name);
            
            columnsToAdd.forEach(col => {
                if (!existingColumns.includes(col.name)) {
                    db.run(`ALTER TABLE clientes_tomadores ADD COLUMN ${col.name} ${col.type}`, (err) => {
                        if (err) console.error(`Error adding ${col.name}:`, err.message);
                        else console.log(`✅ Added column: ${col.name}`);
                    });
                } else {
                    console.log(`ℹ️ Column ${col.name} already exists.`);
                }
            });
        });
    });

    // We can't easily wait for all async ALTER TABLEs in serialize without more ceremony, 
    // but for 7 fields it's usually fine. 
}

updateSchema();
