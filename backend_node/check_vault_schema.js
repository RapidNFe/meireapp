const sqlite3 = require('sqlite3').verbose();
const db = new sqlite3.Database('C:/Users/Fernando/Desktop/pocketbase/pb_data/data.db');

db.get("SELECT * FROM _collections WHERE name = 'fiscal_vault'", (err, row) => {
    if (err) return console.error(err);
    if (row) {
        console.log("Collection 'fiscal_vault' exists.");
        console.log(JSON.stringify(JSON.parse(row.fields), null, 2));
    } else {
        console.log("Collection 'fiscal_vault' does not exist.");
    }
    db.close();
});
