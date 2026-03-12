const sqlite3 = require('sqlite3').verbose();
const db = new sqlite3.Database('C:/Users/Fernando/Desktop/pocketbase/pb_data/data.db');

const sql = `
  UPDATE _collections 
  SET 
    listRule = '', 
    viewRule = '', 
    createRule = '', 
    updateRule = '', 
    deleteRule = '' 
  WHERE name = 'clientes_tomadores'
`;

db.run(sql, function(err) {
  if (err) {
    return console.error(err.message);
  }
  console.log(`Successfully updated rules for clientes_tomadores. Rows affected: ${this.changes}`);
});

db.close();
