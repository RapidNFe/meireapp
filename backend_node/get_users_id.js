const sqlite3 = require('sqlite3').verbose();
const db = new sqlite3.Database('C:/Users/Fernando/Desktop/pocketbase/pb_data/data.db');

db.get("SELECT id FROM _collections WHERE name = 'users'", (err, row) => {
    if (err) console.error(err);
    console.log(row.id);
    db.close();
});
