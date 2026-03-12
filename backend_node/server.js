const config = require('./config');
const express = require('express');
const cors = require('cors');
const axios = require('axios');

// Importando a sua Engenharia
const serproAuth = require('./serpro_auth');
const catraca = require('./catraca_serpro');
const sqlite3 = require('sqlite3').verbose();
const path = require('path');

// Caminho do Banco do PocketBase
const DB_PATH = 'C:/Users/Fernando/Desktop/pocketbase/pb_data/data.db';

function query(sql, params = []) {
    return new Promise((resolve, reject) => {
        const db = new sqlite3.Database(DB_PATH);
        db.all(sql, params, (err, rows) => {
            db.close();
            if (err) reject(err);
            else resolve(rows);
        });
    });
}

function run(sql, params = []) {
    return new Promise((resolve, reject) => {
        const db = new sqlite3.Database(DB_PATH);
        db.run(sql, params, function (err) {
            const id = this.lastID;
            db.close();
            if (err) reject(err);
            else resolve({ id, changes: this.changes });
        });
    });
}

// Configurando o Banco de Dados (PocketBase)
const PocketBase = require('pocketbase/cjs');
const pb = new PocketBase(config.pocketbase.url);

// Nota: Removemos checkPBAuth porque agora o Node fala direto com o BD SQLITE do PocketBase
// para evitar conflitos de versão do SDK ou regras de acesso (403/404).

const app = express();

// LIBERAR CORS PARA O CHROME NO NOTEBOOK
app.use(cors({
    origin: '*',
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization']
}));

app.use(express.json());

// Log de Debug para todas as requisições
app.use((req, res, next) => {
    console.log(`🌐 [${new Date().toLocaleTimeString()}] ${req.method} ${req.url}`);
    next();
});

// ==========================================
// 🚀 ROTA 1: EMISSÃO DE NOTA FISCAL (NFS-e)
// ==========================================
app.post('/api/notas/emitir', async (req, res) => {
    const { userId, tomadorCnpj, tomadorNome, valor, servico } = req.body;

    try {
        // 0. Buscamos os dados SOBERANOS do Prestador (o Usuário logado)
        const prestadores = await query(`SELECT cnpj, nome_fantasia, razao_social, producao FROM users WHERE id = ?`, [userId]);

        if (prestadores.length === 0) {
            throw new Error("Prestador não encontrado no banco de dados.");
        }

        const prestador = prestadores[0];
        const cnpjPrestador = prestador.cnpj;
        const nomePrestador = prestador.nome_fantasia || prestador.razao_social;

        // 🛡️ TRAVA DE AMBIENTE INDIVIDUAL: Se o usuário ativou o producao no Perfil, tpAmb = 1 (Real), senão 2 (Homologação)
        const isProducao = prestador.producao === 1 || prestador.producao === true;
        const tpAmbiente = isProducao ? 1 : 2;

        const urlSerpro = isProducao
            ? 'https://gateway.apiserpro.serpro.gov.br/integra-contador/v1/Consultar'
            : 'https://gateway.apiserpro.serpro.gov.br/integra-contador-homologacao/v1/Consultar';

        console.log(`🚀 [Emissão] [Ambiente: ${isProducao ? 'PRODUÇÃO' : 'TESTES'}] Iniciando nota para ${nomePrestador}`);

        // 1. Criamos o Registro 'Processando' (Segurança de Auditoria)
        let now = new Date().toISOString().replace('T', ' ').replace('Z', '');
        const logId = Math.random().toString(36).substring(2, 17);

        await run(`
            INSERT INTO notas_fiscais (id, user, tomador_cnpj, tomador_nome, valor, servico, status, created, updated)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        `, [logId, userId, tomadorCnpj, tomadorNome, valor, servico, 'processando', now, now]);

        // 2. A Catraca entra em ação com o Payload Oficial do Governo
        const resultado = await catraca.adicionar(async () => {
            const chaves = await serproAuth.getTokens();

            // O "Envelope" que o Serpro exige (Baseado no seu manual)
            const payloadGoverno = {
                "tpAmb": tpAmbiente,
                "contratante": { "numero": cnpjPrestador, "tipo": 2 },
                "autorPedidoDados": { "numero": cnpjPrestador, "tipo": 2 },
                "contribuinte": { "numero": tomadorCnpj, "tipo": 2 },
                "pedidoDados": {
                    "idSistema": "NFSE",
                    "idServico": "EMITIR_NOTA_V1",
                    "versaoSistema": "1.0",
                    "dados": JSON.stringify({
                        "valorServico": valor,
                        "discriminacao": servico,
                        "prestador": {
                            "cnpj": cnpjPrestador,
                            "razaoSocial": prestador.razao_social || prestador.nome_fantasia
                        },
                        "codigoCnae": "6201501",
                        "issRetido": 2
                    })
                }
            };

            // Chamada Real (A ponte mTLS que validamos)
            const response = await axios({
                method: 'POST',
                url: urlSerpro,
                headers: {
                    'Authorization': `Bearer ${chaves.bearer}`,
                    'jwt_token': chaves.jwt,
                    'Content-Type': 'application/json'
                },
                data: payloadGoverno,
                httpsAgent: chaves.agente
            });

            return response.data;
        });

        // 3. Sucesso! Atualizamos o banco
        now = new Date().toISOString().replace('T', ' ').replace('Z', '');
        await run(`
            UPDATE notas_fiscais 
            SET status = 'emitida', numero_nota = ?, updated = ?
            WHERE id = ?
        `, [resultado.dados?.numeroNota || "Gerada", now, logId]);

        res.json({ sucesso: true, numero: resultado.dados?.numeroNota });

    } catch (error) {
        console.error("💥 Falha na Emissão Real:", error.message);

        let logId = null;
        try {
            // Find the most recent 'processando' note for this user if logNota is not in scope of the catch
            const recent = await pb.collection('notas_fiscais').getFirstListItem(`user_id="${userId}" && status="processando"`, { sort: '-created' });
            logId = recent.id;
        } catch (e) {
            // ignore
        }

        // Se falhar tudo, marcamos como erro no banco para o Thiago ver
        if (logId) {
            now = new Date().toISOString().replace('T', ' ').replace('Z', '');
            await run(`UPDATE notas_fiscais SET status = 'erro', updated = ? WHERE id = ?`, [now, logId]);
        }

        res.status(500).json({ sucesso: false, erro: "O Governo rejeitou a nota. Tente novamente." });
    }
});
// ==========================================
// 📊 ROTA 2: CÁLCULO DE IMPOSTO (TERMÔMETRO)
// ==========================================
app.get('/api/impostos/estimativa/:userId', async (req, res) => {
    try {
        const { userId } = req.params;
        const agora = new Date();
        const mesAtualNum = (agora.getMonth() + 1).toString().padStart(2, '0');
        const anoAtual = agora.getFullYear();
        
        const mesesLabels = ["Janeiro", "Fevereiro", "Março", "Abril", "Maio", "Junho", "Julho", "Agosto", "Setembro", "Outubro", "Novembro", "Dezembro"];
        const refMes = `${mesesLabels[agora.getMonth()]}/${anoAtual}`;

        console.log(`📊 Calculando impostos para o usuário: ${userId} (${refMes})`);

        // Buscamos notas 'emitida' ou 'processando' deste mês
        const records = await query(`
            SELECT valor FROM notas_fiscais 
            WHERE user = ? 
            AND status IN ('emitida', 'processando')
            AND created LIKE ?
        `, [userId, `${anoAtual}-${mesAtualNum}%`]);

        console.log(`✅ Notas filtradas (Mês Atual): ${records.length}`);

        // Parse dos valores
        const faturamentoMensal = records.reduce((acc, nota) => {
            let val = nota.valor;
            if (typeof val === 'string') {
                val = parseFloat(val.replace(',', '.').replace(/[^0-9.]/g, '')) || 0;
            }
            return acc + (parseFloat(val) || 0);
        }, 0);

        // O imposto do cliente é fixo (Regra MEI/Said)
        const impostoEstimado = 86.00;

        res.json({
            faturamento: faturamentoMensal,
            imposto: impostoEstimado,
            referencia: refMes
        });
    } catch (error) {
        console.error('❌ Erro no cálculo de impostos:', error.message);
        res.status(500).json({ error: "Erro ao calcular impostos" });
    }
});

// ==========================================
// 📈 ROTA 3: HISTÓRICO DE FATURAMENTO (SPARKLINE)
// ==========================================
app.get('/api/faturamento/historico/:userId', async (req, res) => {
    try {
        const { userId } = req.params;
        console.log(`📈 Gerando histórico para o usuário: ${userId}`);

        // Buscamos notas 'emitida' ou 'processando'
        const records = await query(`
            SELECT valor, created FROM notas_fiscais 
            WHERE user = ? 
            AND status IN ('emitida', 'processando')
            ORDER BY created DESC
        `, [userId]);

        console.log(`✅ Notas no histórico: ${records.length}`);

        // 2. Preparamos o esqueleto dos últimos 6 meses (garante que meses sem nota apareçam como 0)
        const mesesLabels = ["Jan", "Fev", "Mar", "Abr", "Mai", "Jun", "Jul", "Ago", "Set", "Out", "Nov", "Dez"];
        const hoje = new Date();
        let historico = [];

        for (let i = 5; i >= 0; i--) {
            const d = new Date(hoje.getFullYear(), hoje.getMonth() - i, 1);
            historico.push({
                mes: mesesLabels[d.getMonth()],
                mesNum: d.getMonth(),
                ano: d.getFullYear(),
                total: 0
            });
        }

        // 3. Agregamos os valores das notas no mês correspondente
        records.forEach(nota => {
            // PocketBase armazena datas ISO UTC. Convertemos para local do servidor
            const dataNota = new Date(nota.created);
            
            // Encontramos o bucket de mês/ano correto no histórico
            const item = historico.find(h => h.mesNum === dataNota.getMonth() && h.ano === dataNota.getFullYear());
            
            if (item) {
                let val = nota.valor;
                if (typeof val === 'string') {
                    // Resiliência para valores formatados (vírgula/ponto)
                    val = parseFloat(val.replace(',', '.').replace(/[^0-9.]/g, '')) || 0;
                }
                item.total += (parseFloat(val) || 0);
            }
        });

        // 4. Retornamos apenas o essencial para o CustomPaint do Flutter
        const resultadoFinal = historico.map(h => ({ label: h.mes, valor: h.total }));

        res.json(resultadoFinal);

    } catch (error) {
        console.error("Erro no histórico:", error.message);
        res.status(500).json({ error: "Falha ao processar histórico financeiro" });
    }
});

// ==========================================
// 📜 ROTA 4: EXPORTAÇÃO DE DADOS (LGPD - DIREITO À PORTABILIDADE)
// ==========================================
app.get('/api/meus-dados/:userId', async (req, res) => {
    try {
        const { userId } = req.params;
        console.log(`📜 [LGPD] Exportando pacote de dados para o usuário: ${userId}`);

        // 1. Buscamos todas as notas fiscais emitidas
        const notas = await query(`
            SELECT * FROM notas_fiscais 
            WHERE user = ?
        `, [userId]);

        // 2. Buscamos a agenda de clientes (tomadores)
        const clientes = await query(`
            SELECT * FROM clientes_tomadores 
            WHERE user_id = ?
        `, [userId]);

        // 3. Montamos o pacote Soberano
        const pacoteDados = {
            usuario_id: userId,
            data_exportacao: new Date().toISOString(),
            status_lgpd: "Concluído",
            historico_faturamentos: notas,
            agenda_clientes: clientes,
            mensagem: "Este arquivo contém todos os seus dados processados pela Meire (SAID Contabilidade). Você tem o direito de portabilidade desses dados conforme a LGPD."
        };

        res.json(pacoteDados);

    } catch (error) {
        console.error("❌ [LGPD] Falha na exportação:", error.message);
        res.status(500).json({ error: "Falha ao gerar pacote de dados para exportação." });
    }
});

// LIGANDO O MOTOR
// ==========================================
const PORTA = config.servidor.port;
app.listen(PORTA, () => {
    console.log(`\n🛡️  MEIRE ONLINE: Ambiente de [${config.isProducao ? 'PRODUÇÃO' : 'TESTES'}]`);
    console.log(`🟢 Servidor da SAID Contabilidade na porta ${PORTA}`);
    console.log(`⏳ Aguardando comandos do aplicativo Meire...\n`);
});
