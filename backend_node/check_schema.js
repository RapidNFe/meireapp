const sqlite3 = require('sqlite3').verbose();
const config = require('./config');

const DB_PATH = config.isProducao 
    ? '/home/ubuntu/pb_data/data.db' 
    : 'C:/Users/Fernando/Desktop/pocketbase/pb_data/data.db';

const db = new sqlite3.Database(DB_PATH);

db.all("PRAGMA table_info(notas_fiscais)", (err, rows) => {
    if (err) {
        console.error(err);
    } else {
        console.log("COLUMNS IN notas_fiscais:");
        rows.forEach(row => {
            console.log(`- ${row.name} (${row.type})`);
        });
    }
    db.close();
});
