const sqlite3 = require('sqlite3').verbose();
const db = new sqlite3.Database('C:/Users/Fernando/Desktop/pocketbase/pb_data/data.db');

db.all("SELECT name FROM sqlite_master WHERE type='table'", (err, tables) => {
    if (err) {
        console.error(err);
        process.exit(1);
    }
    console.log("Tables:", tables.map(t => t.name).join(", "));
    
    // Pick common table names
    const likelyTable = tables.find(t => t.name === 'notas_fiscais');
    if (likelyTable) {
        db.all("SELECT * FROM notas_fiscais", (err, rows) => {
            console.log("\nData in notas_fiscais:", JSON.stringify(rows, null, 2));
            db.close();
        });
    } else {
        console.log("\nTable 'notas_fiscais' not found.");
        db.close();
    }
});
