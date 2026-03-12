const sqlite3 = require('sqlite3').verbose();
const path = require('path');

// Caminho do Banco do PocketBase
const DB_PATH = 'C:/Users/Fernando/Desktop/pocketbase/pb_data/data.db';

async function limparBase() {
    console.log("🧹 Iniciando faxina geral na Meire...");
    
    const db = new sqlite3.Database(DB_PATH);

    // 1. Limpar Notas Fiscais (Mocks e Testes)
    db.run("DELETE FROM notas_fiscais", function(err) {
        if (err) {
            console.error("❌ Erro ao limpar notas_fiscais:", err.message);
        } else {
            console.log(`✅ Notas Fiscais removidas: ${this.changes}`);
        }
    });

    // 2. Limpar Clientes Tomadores (Opcional, mas recomendado para base limpa)
    // Se quiser manter os clientes, comente a linha abaixo
    db.run("DELETE FROM clientes_tomadores", function(err) {
        if (err) {
            console.error("❌ Erro ao limpar clientes_tomadores:", err.message);
        } else {
            console.log(`✅ Clientes Tomadores removidos: ${this.changes}`);
        }
        
        // Finaliza a conexão após a última operação
        db.close();
        console.log("\n✨ Base de dados pronta para o mundo real (Oracle Cloud)!");
    });
}

limparBase();
