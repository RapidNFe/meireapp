const sqlite3 = require('sqlite3').verbose();
const db = new sqlite3.Database('C:/Users/Fernando/Desktop/pocketbase/pb_data/data.db');

const userId = 'kgmr39ukwa4pdlr';

// Test the EXACT query from server.js
db.all("SELECT valor FROM notas_fiscais WHERE user = ? AND (LOWER(status) = 'emitida')", [userId], (err, rows) => {
    if (err) return console.error(err);
    console.log('Query Result:', rows);
    db.close();
});
