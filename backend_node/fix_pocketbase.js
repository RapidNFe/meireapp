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
            if (!fields.find(f => f.name === 'user')) {
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
            const userRule = "user = @request.auth.id";

            db.run(`
                UPDATE _collections 
                SET fields = ?, listRule = ?, viewRule = ?, createRule = ?, updateRule = ?, deleteRule = ?
                WHERE name = 'clientes_tomadores'
            `, [updatedFields, userRule, userRule, "@request.auth.id != ''", userRule, userRule]);
        });

        // 3. Fix notas_fiscais rules (already has user field)
        const userRule = "user = @request.auth.id";
        db.run(`
            UPDATE _collections 
            SET listRule = ?, viewRule = ?, createRule = ?, updateRule = ?, deleteRule = ?
            WHERE name = 'notas_fiscais'
        `, [userRule, userRule, "@request.auth.id != ''", userRule, userRule]);

        console.log("PocketBase rules and schema updated for multi-user security.");
    });
});
