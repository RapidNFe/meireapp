const sqlite3 = require('sqlite3').verbose();
const db = new sqlite3.Database('C:/Users/Fernando/Desktop/pocketbase/pb_data/data.db');

const email = 'thiago514@hotmail.com'; // E-mail do usuário principal

db.serialize(() => {
    // 1. Ativa o modo de produção e define o status como verificado (pronto para o robô)
    db.run(`UPDATE users SET producao = 1, status_registro = 'verificado' WHERE email = ?`, [email], function(err) {
        if (err) return console.error(err);
        console.log(`🚀 Modo PRODUÇÃO ativado para o usuário: ${email}`);
        console.log(`✅ Status alterado para 'verificado'.`);
    });
});

db.close();
