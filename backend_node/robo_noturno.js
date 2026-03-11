const cron = require('node-cron');
const serproAuth = require('./serpro_auth');
const catraca = require('./catraca_serpro');

// Simulando o seu banco de dados (PocketBase) com 5 clientes
const clientesPocketBase = [
    { id: 1, cnpj: '65057385000179', nome: 'Thiago' },
    { id: 2, cnpj: '11111111111111', nome: 'Empresa A' },
    { id: 3, cnpj: '22222222222222', nome: 'Empresa B' },
    { id: 4, cnpj: '33333333333333', nome: 'Empresa C' },
    { id: 5, cnpj: '44444444444444', nome: 'Empresa D' }
];

// A tarefa pesada que o robô vai fazer para CADA cliente
async function baixarExtratoCliente(cliente, chavesSapi) {
    return new Promise(resolve => {
        // Aqui entraria o Axios batendo no Serpro com o Bearer Token
        setTimeout(() => {
            console.log(`📁 [SERPRO] Extrato do ${cliente.nome} (CNPJ: ${cliente.cnpj}) baixado e salvo no PocketBase!`);
            resolve(true);
        }, 1500); // Simulando o tempo de download do governo
    });
}

console.log('🦉 O Robô Noturno da Meire foi ativado e está aguardando o horário programado...');

// A MÁGICA DO TEMPO: '0 3 * * *' significa "Todos os dias, às 03:00 da manhã"
// Para o teste prático de hoje, vamos usar '*/10 * * * * *' (A cada 10 segundos)
cron.schedule('*/10 * * * * *', async () => {
    console.log('\n==================================================');
    console.log(`⏰ [${new Date().toLocaleTimeString()}] INICIANDO ROTINA DE MADRUGADA...`);
    
    try {
        // 1. O Robô passa no Cofre e pega a Chave Mestra (Pilar 1)
        const chavesSapi = await serproAuth.getTokens();

        console.log(`🤖 Puxando ${clientesPocketBase.length} clientes do banco de dados...`);
        const promessasDeDownload = [];

        // 2. O Robô joga os 2.000 clientes na Catraca (Pilar 2)
        for (const cliente of clientesPocketBase) {
            // A Catraca garante que o Governo não vai nos bloquear
            const tarefa = catraca.adicionar(() => baixarExtratoCliente(cliente, chavesSapi));
            promessasDeDownload.push(tarefa);
        }

        // 3. O Robô espera todo mundo terminar
        await Promise.all(promessasDeDownload);

        console.log(`✅ ROTINA FINALIZADA! Todos os extratos foram sincronizados.`);
        console.log('==================================================\n');

    } catch (erro) {
        console.error('❌ Falha crítica na rotina noturna:', erro.message);
    }
}, {
    // Garantindo que as 03:00 AM sejam baseadas no seu fuso horário oficial (Goiânia/Brasília)
    scheduled: true,
    timezone: "America/Sao_Paulo" 
});
