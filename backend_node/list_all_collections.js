const sqlite3 = require('sqlite3').verbose();
const db = new sqlite3.Database('C:/Users/Fernando/Desktop/pocketbase/pb_data/data.db');

db.all("SELECT name, fields FROM _collections", (err, rows) => {
    if (err) return console.error(err);
    rows.forEach(row => {
        console.log(`--- ${row.name} ---`);
        console.log(row.fields);
    });
    db.close();
});
