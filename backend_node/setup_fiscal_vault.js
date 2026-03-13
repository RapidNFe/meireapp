const sqlite3 = require('sqlite3').verbose();
const db = new sqlite3.Database('C:/Users/Fernando/Desktop/pocketbase/pb_data/data.db');

db.serialize(() => {
    // 1. Get users collection ID
    db.get("SELECT id FROM _collections WHERE name = 'users'", (err, userCol) => {
        if (err || !userCol) return console.error("Could not find users collection", err);
        const usersId = userCol.id;

        // 2. Define fiscal_vault fields
        const fields = [
            {
                "hidden": false,
                "id": "text3208210256",
                "max": 15,
                "min": 15,
                "name": "id",
                "pattern": "^[a-z0-9]+$",
                "presentable": false,
                "primaryKey": true,
                "required": true,
                "system": true,
                "type": "text"
            },
            {
                "hidden": false,
                "id": "rel_user_vault",
                "maxSelect": 1,
                "minSelect": 0,
                "name": "user",
                "presentable": false,
                "required": true,
                "system": false,
                "type": "relation",
                "collectionId": usersId,
                "cascadeDelete": true
            },
            {
                "hidden": false,
                "id": "text_mae",
                "name": "nome_mae",
                "type": "text",
                "required": true
            },
            {
                "hidden": false,
                "id": "text_titulo",
                "name": "titulo_eleitor",
                "type": "text",
                "required": true
            },
            {
                "hidden": false,
                "id": "text_recibos",
                "name": "recibos_irpf",
                "type": "text",
                "required": false
            },
            {
                "hidden": true,
                "id": "text_pwd_gov",
                "name": "gov_br_pwd",
                "type": "text",
                "required": true
            },
            {
                "hidden": false,
                "id": "autodate2990389176",
                "name": "created",
                "onCreate": true,
                "onUpdate": false,
                "system": false,
                "type": "autodate"
            },
            {
                "hidden": false,
                "id": "autodate3332085495",
                "name": "updated",
                "onCreate": true,
                "onUpdate": true,
                "system": false,
                "type": "autodate"
            }
        ];

        const userRule = "user = @request.auth.id";
        const createRule = "@request.auth.id != ''";
        
        const vaultCollection = {
            id: "fiscalvault0001",
            name: "fiscal_vault",
            type: "base",
            system: false,
            fields: JSON.stringify(fields),
            listRule: userRule,
            viewRule: userRule,
            createRule: createRule,
            updateRule: userRule,
            deleteRule: userRule,
            indexes: ["CREATE UNIQUE INDEX `idx_vault_user` ON `fiscal_vault` (`user`)"],
            options: {}
        };

        // 3. Insert or Update fiscal_vault
        db.get("SELECT id FROM _collections WHERE name = 'fiscal_vault'", (err, existing) => {
            if (existing) {
                console.log("Collection 'fiscal_vault' already exists. Updating fields...");
                db.run(`UPDATE _collections SET fields = ?, listRule = ?, viewRule = ?, createRule = ?, updateRule = ?, deleteRule = ? WHERE name = 'fiscal_vault'`, 
                    [vaultCollection.fields, userRule, userRule, createRule, userRule, userRule], 
                    function(err) {
                        if (err) console.error(err);
                        else console.log("Fiscal Vault updated.");
                    });
            } else {
                console.log("Creating 'fiscal_vault' collection...");
                db.run(`INSERT INTO _collections (id, name, type, system, fields, listRule, viewRule, createRule, updateRule, deleteRule, indexes, options) 
                        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
                    [vaultCollection.id, vaultCollection.name, vaultCollection.type, vaultCollection.system, vaultCollection.fields, 
                     vaultCollection.listRule, vaultCollection.viewRule, vaultCollection.createRule, vaultCollection.updateRule, vaultCollection.deleteRule, 
                     JSON.stringify(vaultCollection.indexes), JSON.stringify(vaultCollection.options)],
                    function(err) {
                        if (err) console.error(err);
                        else console.log("Fiscal Vault created successfully.");
                    });
            }
        });
    });
});
