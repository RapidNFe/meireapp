const sqlite3 = require('sqlite3').verbose();
const db = new sqlite3.Database('C:/Users/Fernando/Desktop/pocketbase/pb_data/data.db');

db.get("SELECT fields FROM _collections WHERE name = 'clientes_tomadores'", (err, row) => {
    if (err) return console.error(err);
    console.log(JSON.stringify(JSON.parse(row.fields), null, 2));
    db.close();
});
