const sqlite3 = require('sqlite3').verbose();
const db = new sqlite3.Database('C:/Users/Fernando/Desktop/pocketbase/pb_data/data.db');

db.get("SELECT fields FROM _collections WHERE name = 'notas_fiscais'", (err, row) => {
    if (err) return console.error(err);
    console.log(row.fields);
    db.close();
});
