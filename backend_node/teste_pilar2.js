const catraca = require('./catraca_serpro');

// Simulamos a lentidão da Receita Federal (1 segundo para processar uma nota)
const simularSerpro = async (idCliente) => {
    return new Promise(resolve => {
        setTimeout(() => {
            console.log(`✅ [SERPRO] Nota fiscal emitida com sucesso para o Cliente ${idCliente}`);
            resolve(true);
        }, 1000); 
    });
};

async function testarEngarrafamento() {
    console.log("🚀 ATENÇÃO: 10 clientes clicaram em 'Emitir Nota' ao mesmo tempo...\n");
    
    const promessasDeNotas = [];

    // O loop dispara os 10 cliques instantaneamente
    for (let i = 1; i <= 10; i++) {
        console.log(`📥 Pedido do Cliente ${i} entrou na catraca.`);
        
        // Em vez de rodar direto, jogamos o pedido para dentro da catraca
        const pedido = catraca.adicionar(() => simularSerpro(i));
        promessasDeNotas.push(pedido);
    }

    // O Node.js aguarda TODAS as promessas da fila terminarem
    await Promise.all(promessasDeNotas);
    
    console.log("\n🏁 TUDO FINALIZADO! O servidor absorveu o impacto perfeitamente.");
}

testarEngarrafamento();
