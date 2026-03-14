const sqlite3 = require('sqlite3').verbose();
const db = new sqlite3.Database('C:/Users/Fernando/Desktop/pocketbase/pb_data/data.db');

db.serialize(() => {
    db.get("SELECT id, fields FROM _collections WHERE name = 'notas_fiscais'", (err, row) => {
        if (err || !row) {
            console.error("Erro ao buscar a collection notas_fiscais:", err);
            return;
        }

        let fields = JSON.parse(row.fields);
        let chaveAcessoField = fields.find(f => f.name === 'chave_acesso');

        if (chaveAcessoField) {
            console.log("Atualizando campo 'chave_acesso' para ser obrigatório e único...");
            chaveAcessoField.required = true;
            chaveAcessoField.unique = true; // In some PB versions this might be in options or top level depending on how it was created
            // However, PocketBase usually handles uniqueness via 'indexes' or a 'unique' flag in the field definition.
            // Let's check if there's a unique index for it too.
        } else {
            console.log("Criando campo 'chave_acesso'...");
            fields.push({
                "id": "text_chave_acesso",
                "name": "chave_acesso",
                "type": "text",
                "system": false,
                "required": true,
                "presentable": true,
                "unique": true,
                "options": {
                    "min": 50,
                    "max": 50,
                    "pattern": ""
                }
            });
        }

        db.run(`UPDATE _collections SET fields = ? WHERE id = ?`, [JSON.stringify(fields), row.id], function(updateErr) {
            if (updateErr) {
                console.error("Erro ao atualizar fields:", updateErr);
            } else {
                console.log("Fields da collection notas_fiscais atualizados!");
            }
        });
    });
});
