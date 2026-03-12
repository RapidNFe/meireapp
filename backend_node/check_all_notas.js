const sqlite3 = require('sqlite3').verbose();
const db = new sqlite3.Database('C:/Users/Fernando/Desktop/pocketbase/pb_data/data.db');

db.all("SELECT * FROM notas_fiscais", (err, rows) => {
    if (err) return console.error(err);
    console.log(JSON.stringify(rows, null, 2));
    db.close();
});
