const sqlite3 = require('sqlite3').verbose();
const db = new sqlite3.Database('C:/Users/Fernando/Desktop/pocketbase/pb_data/data.db');

db.get("SELECT * FROM _collections WHERE name = 'users'", (err, col) => {
    if (err) return console.error(err);
    
    let fields = JSON.parse(col.fields);
    
    // Add inscricao_municipal if it doesn't exist
    if (!fields.find(f => f.name === 'inscricao_municipal')) {
        fields.push({
            "hidden": false,
            "id": "text_im_custom",
            "name": "inscricao_municipal",
            "type": "text",
            "required": false
        });
    }

    // Add cep if it doesn't exist
    if (!fields.find(f => f.name === 'cep')) {
        fields.push({
            "hidden": false,
            "id": "text_cep_custom",
            "name": "cep",
            "type": "text",
            "required": false
        });
    }

    const updatedFields = JSON.stringify(fields);
    
    db.run(`UPDATE _collections SET fields = ? WHERE name = 'users'`, [updatedFields], function(err) {
        if (err) return console.error(err);
        console.log("Successfully added inscricao_municipal and cep to users collection.");
        db.close();
    });
});
