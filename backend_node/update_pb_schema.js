const sqlite3 = require('sqlite3').verbose();
const db = new sqlite3.Database('C:/Users/Fernando/Desktop/pocketbase/pb_data/data.db');

db.serialize(() => {
    db.get("SELECT id, fields FROM _collections WHERE name = 'users'", (err, row) => {
        if (err || !row) return console.error("Error finding users collection", err);
        
        let fields = JSON.parse(row.fields);
        
        // Add arquivo_pfx if not exists
        if (!fields.find(f => f.name === 'arquivo_pfx')) {
            fields.push({
                "id": "file_pfx_custom",
                "name": "arquivo_pfx",
                "type": "file",
                "system": false,
                "required": false,
                "presentable": false,
                "unique": false,
                "options": {
                    "maxSelect": 1,
                    "maxSize": 5242880,
                    "mimeTypes": [],
                    "thumbs": [],
                    "protected": false
                }
            });
            console.log("Added arquivo_pfx field");
        }

        // Add senha_pfx if not exists
        if (!fields.find(f => f.name === 'senha_pfx')) {
            fields.push({
                "id": "text_pfx_pass_custom",
                "name": "senha_pfx",
                "type": "text",
                "system": false,
                "required": false,
                "presentable": false,
                "unique": false,
                "options": {
                    "min": null,
                    "max": null,
                    "pattern": ""
                }
            });
            console.log("Added senha_pfx field");
        }

        const updatedFields = JSON.stringify(fields);
        db.run("UPDATE _collections SET fields = ? WHERE id = ?", [updatedFields, row.id], (err) => {
            if (err) console.error("Error updating users fields:", err);
            else console.log("Users collection updated successfully.");
            db.close();
        });
    });
});
