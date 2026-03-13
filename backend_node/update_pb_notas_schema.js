const sqlite3 = require('sqlite3').verbose();
const db = new sqlite3.Database('C:/Users/Fernando/Desktop/pocketbase/pb_data/data.db');

db.serialize(() => {
    db.get("SELECT id, fields FROM _collections WHERE name = 'notas_fiscais'", (err, row) => {
        if (err || !row) return console.error("Error finding notas_fiscais collection", err);
        
        let fields = JSON.parse(row.fields);
        
        // Add chave_acesso
        if (!fields.find(f => f.name === 'chave_acesso')) {
            fields.push({
                "id": "chave_acesso_custom",
                "name": "chave_acesso",
                "type": "text",
                "system": false,
                "required": false,
                "presentable": true,
                "unique": false,
                "options": { "min": null, "max": null, "pattern": "" }
            });
            console.log("Added chave_acesso field");
        }

        // Add xml_nota (text for the full XML content)
        if (!fields.find(f => f.name === 'xml_nota')) {
            fields.push({
                "id": "xml_nota_custom",
                "name": "xml_nota",
                "type": "text",
                "system": false,
                "required": false,
                "presentable": false,
                "unique": false,
                "options": { "min": null, "max": null, "pattern": "" }
            });
            console.log("Added xml_nota field");
        }

        const updatedFields = JSON.stringify(fields);
        db.run("UPDATE _collections SET fields = ? WHERE id = ?", [updatedFields, row.id], (err) => {
            if (err) console.error("Error updating notas_fiscais fields:", err);
            else console.log("Notas_fiscais collection updated successfully.");
            db.close();
        });
    });
});
