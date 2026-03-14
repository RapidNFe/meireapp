const sqlite3 = require('sqlite3').verbose();
const db = new sqlite3.Database('C:/Users/Fernando/Desktop/pocketbase/pb_data/data.db');

db.serialize(() => {
    db.get("SELECT id, name, fields FROM _collections WHERE name = 'users'", (err, row) => {
        if (err || !row) {
            console.error("Erro ao buscar a collection users:", err);
            return;
        }

        let fields;
        try {
            fields = JSON.parse(row.fields);
        } catch (e) {
            console.error("Erro ao fazer parse dos fields original:", e);
            return;
        }

        // Verifica se o campo já existe
        const fieldExists = fields.find(f => f.name === 'vencimento_pfx');
        if (fieldExists) {
            console.log("Campo 'vencimento_pfx' já existe no fields de users.");
            return;
        }

        console.log("Adicionando campo 'vencimento_pfx'...");
        fields.push({
            "system": false,
            "id": "date_venc_pfx",
            "name": "vencimento_pfx",
            "type": "date",
            "required": false,
            "presentable": false,
            "unique": false,
            "options": {
                "min": "",
                "max": ""
            }
        });

        db.run(`UPDATE _collections SET fields = ? WHERE id = ?`, [JSON.stringify(fields), row.id], function(updateErr) {
            if (updateErr) {
                console.error("Erro ao atualizar fields:", updateErr);
            } else {
                console.log("Fields da collection users atualizado com sucesso!");
            }
        });
    });
});
