const sqlite3 = require('sqlite3').verbose();
const db = new sqlite3.Database('C:/Users/Fernando/Desktop/pocketbase/pb_data/data.db');

db.get("SELECT * FROM _collections WHERE name = 'users'", (err, col) => {
    if (err) return console.error(err);
    
    let fields = JSON.parse(col.fields);
    
    const fieldsToAdd = [
        { id: "text_im_custom", name: "inscricao_municipal" },
        { id: "text_cep_custom", name: "cep" },
        { id: "text_ibge_custom", name: "codigo_municipio" }
    ];

    fieldsToAdd.forEach(field => {
        if (!fields.find(f => f.name === field.name)) {
            fields.push({
                "hidden": false,
                "id": field.id,
                "name": field.name,
                "type": "text",
                "required": false
            });
            console.log(`✅ Adicionando campo: ${field.name}`);
        }
    });

    const updatedFields = JSON.stringify(fields);
    
    db.run(`UPDATE _collections SET fields = ? WHERE name = 'users'`, [updatedFields], function(err) {
        if (err) return console.error(err);
        console.log("🚀 Sincronização de schema do Perfil concluída.");
        db.close();
    });
});
