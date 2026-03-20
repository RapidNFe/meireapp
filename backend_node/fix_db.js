const sqlite3 = require('sqlite3').verbose();
const DB_PATH = 'C:/Users/Fernando/Desktop/pocketbase/pb_data/data.db';

const db = new sqlite3.Database(DB_PATH, (err) => {
    if (err) {
        console.error('Erro ao abrir o banco:', err.message);
        process.exit(1);
    }
    console.log('Conectado ao banco para manutenção.');
    
    db.run(`ALTER TABLE users ADD COLUMN inscricao_municipal TEXT`, (err) => {
        if (err) {
            if (err.message.includes('duplicate column name')) {
                console.log('Coluna inscricao_municipal já existe em users.');
            } else if (err.message.includes('no such table')) {
                console.log('Tabela users não encontrada no banco atual.');
            } else {
                console.error('Erro ao adicionar inscricao_municipal em users:', err.message);
            }
        } else {
            console.log('Coluna inscricao_municipal adicionada com sucesso em users.');
        }

        db.run(`ALTER TABLE clientes_tomadores ADD COLUMN inscricao_municipal TEXT`, (err) => {
            if (err) {
                if (err.message.includes('duplicate column name')) {
                    console.log('Coluna inscricao_municipal já existe em clientes_tomadores.');
                } else {
                    console.error('Erro ao adicionar inscricao_municipal em clientes_tomadores:', err.message);
                }
            } else {
                console.log('Coluna inscricao_municipal adicionada com sucesso em clientes_tomadores.');
            }
            db.close();
        });
    });
});
