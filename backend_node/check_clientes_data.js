const sqlite3 = require('sqlite3').verbose();
const db = new sqlite3.Database('C:/Users/Fernando/Desktop/pocketbase/pb_data/data.db');

db.all("SELECT id, user, apelido FROM clientes_tomadores", (err, rows) => {
    if (err) return console.error(err);
    console.log(rows);
    db.close();
});
