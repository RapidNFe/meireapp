const sqlite3 = require('sqlite3').verbose();
const db = new sqlite3.Database('C:/Users/Fernando/Desktop/pocketbase/pb_data/data.db');

db.serialize(() => {
    // 1. Get users collection ID
    db.get("SELECT id FROM _collections WHERE name = 'users'", (err, userCol) => {
        if (err || !userCol) return console.error("Could not find users collection", err);
        const usersId = userCol.id;

        // 2. Fix clientes_tomadores
        db.get("SELECT * FROM _collections WHERE name = 'clientes_tomadores'", (err, col) => {
            if (err) return console.error(err);
            
            let fields = JSON.parse(col.fields);
            let userField = fields.find(f => f.name === 'user');
            
            if (userField) {
                console.log("Updating existing 'user' field to type: relation");
                userField.type = "relation";
                userField.collectionId = usersId;
                userField.maxSelect = 1;
                userField.minSelect = 0;
                userField.required = true;
                // Cleanup text fields
                delete userField.autogeneratePattern;
                delete userField.pattern;
                delete userField.max;
                delete userField.min;
            } else {
                console.log("Adding new 'user' field as relation");
                fields.push({
                    "hidden": false,
                    "id": "rel_user_custom",
                    "maxSelect": 1,
                    "minSelect": 0,
                    "name": "user",
                    "presentable": false,
                    "required": true,
                    "system": false,
                    "type": "relation",
                    "collectionId": usersId,
                    "cascadeDelete": true
                });
            }

            const updatedFields = JSON.stringify(fields);
            
            // Rules: We use @request.auth.id != '' for list/view to be extra sure they work, 
            // but keep user = @request.auth.id as the main filter.
            // Actually, setting them to empty string makes them PUBLIC. 
            // Let's use user = @request.auth.id but ensure they aren't NULL.
            const userRule = "user = @request.auth.id";

            db.run(`
                UPDATE _collections 
                SET fields = ?, listRule = ?, viewRule = ?, createRule = ?, updateRule = ?, deleteRule = ?
                WHERE name = 'clientes_tomadores'
            `, [updatedFields, userRule, userRule, "@request.auth.id != ''", userRule, userRule], function(err) {
                if (err) return console.error(err);
                console.log("Successfully updated clientes_tomadores schema and rules.");
            });
        });

        // 3. Ensure notas_fiscais rules are also set
        const userRule = "user = @request.auth.id";
        db.run(`
            UPDATE _collections 
            SET listRule = ?, viewRule = ?, createRule = ?, updateRule = ?, deleteRule = ?
            WHERE name = 'notas_fiscais'
        `, [userRule, userRule, "@request.auth.id != ''", userRule, userRule], function(err) {
            if (err) return console.error(err);
            console.log("Successfully updated notas_fiscais rules.");
        });
    });
});
