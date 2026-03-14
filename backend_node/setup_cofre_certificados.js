const sqlite3 = require('sqlite3').verbose();
const db = new sqlite3.Database('C:/Users/Fernando/Desktop/pocketbase/pb_data/data.db');

db.serialize(() => {
    db.get("SELECT id FROM _collections WHERE name = 'users'", (err, userCol) => {
        if (err || !userCol) return console.error("Could not find users collection", err);
        const usersId = userCol.id;

        // 1. Create cofre_certificados collection
        const cofreFields = [
            { "system": false, "id": "text_id_cofre", "name": "id", "type": "text", "required": true, "presentable": false, "unique": false, "options": { "min": 15, "max": 15, "pattern": "^[a-z0-9]+$" } },
            { "system": false, "id": "rel_usuario_cofre", "name": "usuario", "type": "relation", "required": true, "presentable": false, "unique": false, "options": { "collectionId": usersId, "cascadeDelete": true, "minSelect": null, "maxSelect": 1, "displayFields": null } },
            { "system": false, "id": "text_senha_enc", "name": "senha_encriptada", "type": "text", "required": true, "presentable": false, "unique": false, "options": { "min": null, "max": null, "pattern": "" } },
            { "system": false, "id": "date_venc_cofre", "name": "data_vencimento", "type": "date", "required": false, "presentable": false, "unique": false, "options": { "min": "", "max": "" } },
            { "system": false, "id": "file_pfx", "name": "arquivo_pfx", "type": "file", "required": true, "presentable": false, "unique": false, "options": { "maxSelect": 1, "maxSize": 5242880, "mimeTypes": [], "thumbs": [], "protected": true } },
            { "system": false, "id": "bool_valido", "name": "valido", "type": "bool", "required": false, "presentable": false, "unique": false, "options": {} },
            { "system": false, "id": "autodate_created", "name": "created", "type": "autodate", "required": false, "presentable": false, "unique": false, "options": { "onCreate": true, "onUpdate": false } },
            { "system": false, "id": "autodate_updated", "name": "updated", "type": "autodate", "required": false, "presentable": false, "unique": false, "options": { "onCreate": true, "onUpdate": true } }
        ];

        const cofreCollection = {
            id: "cofrecertific00",
            name: "cofre_certificados",
            type: "base",
            system: false,
            fields: JSON.stringify(cofreFields),
            listRule: null, // ADMIN ONLY
            viewRule: null,
            createRule: null,
            updateRule: null,
            deleteRule: null,
            indexes: JSON.stringify(["CREATE UNIQUE INDEX `idx_cofre_user` ON `cofre_certificados` (`usuario`)"]),
            options: JSON.stringify({})
        };

        db.get("SELECT id FROM _collections WHERE name = 'cofre_certificados'", (err, existingCofre) => {
             if (existingCofre) {
                 db.run(`UPDATE _collections SET fields = ?, indexes = ? WHERE id = ?`, [cofreCollection.fields, cofreCollection.indexes, existingCofre.id], (err) => {
                     if (err) console.error("Error updating cofre_certificados:", err);
                     else console.log("cofre_certificados updated.");
                 });
             } else {
                 db.run(`INSERT INTO _collections (id, name, type, system, fields, listRule, viewRule, createRule, updateRule, deleteRule, indexes, options) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`, 
                    [cofreCollection.id, cofreCollection.name, cofreCollection.type, cofreCollection.system, cofreCollection.fields, cofreCollection.listRule, cofreCollection.viewRule, cofreCollection.createRule, cofreCollection.updateRule, cofreCollection.deleteRule, cofreCollection.indexes, cofreCollection.options], (err) => {
                     if (err) console.error("Error creating cofre_certificados:", err);
                     else console.log("cofre_certificados created.");
                 });
             }
        });

        // 2. Add requested fields to 'users' collection (possui_certificado)
        db.get("SELECT id, fields FROM _collections WHERE name = 'users'", (err, userRow) => {
             if (err || !userRow) return console.error("Error getting users fields:", err);
             const userFields = JSON.parse(userRow.fields);

             if (!userFields.find(f => f.name === 'possui_certificado')) {
                 userFields.push({ "system": false, "id": "bool_possui_cert", "name": "possui_certificado", "type": "bool", "required": false, "presentable": false, "unique": false, "options": {} });
                 db.run(`UPDATE _collections SET fields = ? WHERE id = ?`, [JSON.stringify(userFields), userRow.id], (err) => {
                     if (err) console.error("Error adding possui_certificado:", err);
                     else console.log("Added possui_certificado to users collection.");
                 });
             } else {
                 console.log("possui_certificado already exists in users collection.");
             }
        });
    });
});
