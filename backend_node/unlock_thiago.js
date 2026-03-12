const sqlite3 = require('sqlite3').verbose();
const db = new sqlite3.Database('C:/Users/Fernando/Desktop/pocketbase/pb_data/data.db');

db.run(`UPDATE users SET status_registro = 'verificado' WHERE email = 'thiago514@hotmail.com'`, function (err) {
  if (err) {
    return console.error(err.message);
  }
  console.log(`Row(s) updated: ${this.changes}`);
});

db.close();
