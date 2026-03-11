require('dotenv').config();
const express = require('express');
const cors = require('cors');

// Importando a sua Engenharia
const serproAuth = require('./serpro_auth');
const catraca = require('./catraca_serpro');

// Configurando o Banco de Dados (PocketBase)
const PocketBase = require('pocketbase/cjs');
const pb = new PocketBase('http://127.0.0.1:8090');

const app = express();
app.use(cors());
app.use(express.json()); // Permite que o Node entenda JSON vindo do Flutter

// ==========================================
// 🚀 ROTA 1: EMISSÃO DE NOTA FISCAL (NFS-e)
// ==========================================
app.post('/api/notas/emitir', async (req, res) => {
    // 1. O Flutter manda os dados da nota no corpo da requisição
    const { cnpjCliente, valor, servico, clienteDestino } = req.body;

    console.log(`\n📥 Recebido pedido de emissão do App para o CNPJ: ${cnpjCliente}`);

    try {
        // 2. A Mágica da Fricção Zero: Jogamos o pedido na sua Catraca!
        // O app não fica travado esperando o governo. A catraca organiza.
        const resultadoEmissao = await catraca.adicionar(async () => {
            
            // Aqui dentro o Node pega a chave no Cofre...
            const chaves = await serproAuth.getTokens();
            
            // ...e faz a chamada oficial para a Receita (simulada por enquanto)
            return new Promise(resolve => {
                setTimeout(() => {
                    resolve({ 
                        sucesso: true, 
                        mensagem: "Nota emitida com sucesso via Integra Contador!",
                        numeroNota: Math.floor(Math.random() * 100000)
                    });
                }, 1500);
            });
        });

        // 3. Devolvemos a resposta de sucesso para o Flutter
        res.status(200).json(resultadoEmissao);

    } catch (erro) {
        console.error('❌ Erro na emissão:', erro.message);
        res.status(500).json({ erro: "Falha ao processar a nota fiscal." });
    }
});
// ==========================================
// 📊 ROTA 2: CÁLCULO DE IMPOSTO (TERMÔMETRO)
// ==========================================
app.get('/api/impostos/estimativa/:userId', async (req, res) => {
    try {
        const { userId } = req.params;
        // Puxa as notas via PocketBase para somar faturamento
        // Atenção ao filtro: user = userId de acordo com o padrão do nosso app
        const records = await pb.collection('notas_fiscais').getFullList({
            filter: `user = "${userId}" && status = "emitida"`,
        });

        // Parse dos valores que vêm como strings "1500.00" do pocketbase
        const faturamentoTotal = records.reduce((acc, nota) => {
            let val = nota.valor || nota.valor_servico;
            if (typeof val === 'string') {
                val = parseFloat(val.replace(',', '.').replace(/[^0-9.]/g, '')) || 0;
            }
            return acc + (parseFloat(val) || 0);
        }, 0);
        
        // Lógica Simplificada: MEI é fixo, Simples Nacional (Anexo III) começa em 6%
        // Aqui você pode evoluir para a tabela progressiva depois
        const impostoEstimado = faturamentoTotal * 0.06; 

        res.json({
            faturamento: faturamentoTotal,
            imposto: impostoEstimado,
            referencia: "Março/2026"
        });
    } catch (error) {
        console.error('❌ Erro no cálculo de impostos:', error.message);
        res.status(500).json({ error: "Erro ao calcular impostos" });
    }
});

// ==========================================
// LIGANDO O MOTOR
// ==========================================
const PORTA = process.env.PORT || 3000;
app.listen(PORTA, () => {
    console.log(`\n🟢 Servidor da SAID Contabilidade ONLINE na porta ${PORTA}`);
    console.log(`⏳ Aguardando comandos do aplicativo Meire...\n`);
});
