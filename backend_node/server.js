const config = require('./config');
const express = require('express');
const cors = require('cors');
const axios = require('axios');

// Importando a sua Engenharia
const serproAuth = require('./serpro_auth');
const catraca = require('./catraca_serpro');
const sqlite3 = require('sqlite3').verbose();
const vortex = require('./vortex_emissor_nacional');
const zlib = require('zlib');
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

// 🟢 ROTA DE STATUS (SAÚDE DO SISTEMA)
app.get('/serpro/status', (req, res) => {
    res.json({ status: "Servidor Online", ambiente: config.isProducao ? "producao" : "homologacao" });
});

// ==========================================
// 🚀 ROTA 1: EMISSÃO DE NOTA FISCAL (NFS-e) - SERPRO (ANTIGA)
// ==========================================
app.post('/api/notas/emitir', async (req, res) => {
    // ... mantendo a lógica atual do Serpro caso desejado ...
    // (Pode ser removida ou mantida para legado)
    res.status(405).json({ erro: "Use a rota /api/nacional/emitir para o novo padrão" });
});

// ==========================================
// 🚀 ROTA 1.1: EMISSÃO NACIONAL (ADN/SEFIN) - O NOVO PADRÃO
// ==========================================
app.post('/api/nacional/emitir', async (req, res) => {
    const { userId, payload } = req.body; 

    try {
        console.log(`📡 [Nacional] Requisição recebida do usuário: ${userId}`);

        // 1. Busca dados do Prestador e Certificado no Banco
        const results = await query(
            `SELECT cnpj, razao_social, producao, arquivo_pfx, senha_pfx, inscricao_municipal FROM users WHERE id = ?`, 
            [userId]
        );

        if (results.length === 0) throw new Error("Usuário não encontrado.");
        const prestadorDb = results[0];

        // 2. Configura Caminho do Certificado (Soberania do Cliente)
        let certPath = '';
        let certPass = '';

        if (prestadorDb.arquivo_pfx && prestadorDb.senha_pfx) {
            certPath = path.resolve('C:/Users/Fernando/Desktop/pocketbase/pb_data/storage/_pb_users_auth_', userId, prestadorDb.arquivo_pfx);
            certPass = prestadorDb.senha_pfx;
            console.log(`✅ Usando certificado carregado pelo cliente no Perfil.`);
        } else {
            // Fallback para o da SEFIN-PROD ou similar se não houver
            certPath = path.resolve(__dirname, process.env.CERT_PATH_PROD);
            certPass = process.env.CERT_PASSWORD;
            console.log(`⚠️ Usando certificado de fallback (SAID).`);
        }

        // 3. Enriquecendo o Payload com dados do Banco
        // Garante que o CNPJ usado na assinatura seja o do banco, não o enviado pelo front
        payload.prestador = {
            cnpj: prestadorDb.cnpj,
            im: prestadorDb.inscricao_municipal,
            opcaoSimplesNacional: payload.prestador?.opcaoSimplesNacional || "2",
            regimeEspecialTributacao: payload.prestador?.regimeEspecialTributacao || "0"
        };
        payload.ambiente = prestadorDb.producao ? "1" : "2";

        // 4. Aciona o Motor VORTEX
        const resultado = await vortex.emitirNacional(payload, certPath, certPass);

        // 5. Salva no Banco de Dados (Log de Sucesso/Chave)
        let now = new Date().toISOString().replace('T', ' ').replace('Z', '');
        const logId = Math.random().toString(36).substring(2, 17);

        await run(`
            INSERT INTO notas_fiscais (id, user, tomador_cnpj, tomador_nome, valor, status, chave_acesso, xml_nota, created, updated)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        `, [
            logId, 
            userId, 
            payload.tomador.cnpj, 
            payload.tomador.nome || payload.tomador.razaoSocial, 
            payload.servico.valor,
            resultado.sucesso ? 'emitida' : 'erro',
            resultado.dados?.chaveAcesso || null,
            resultado.dados?.xmlDecodificado || null,
            now, 
            now
        ]);

        if (resultado.sucesso) {
            res.json({ 
                sucesso: true, 
                chaveAcesso: resultado.dados.chaveAcesso,
                idNota: logId
            });
        } else {
            res.status(400).json({ 
                sucesso: false, 
                erros: resultado.dados?.erros || [{ Descricao: "Erro desconhecido no governo" }] 
            });
        }

    } catch (error) {
        console.error("❌ Erro na Emissão Nacional:", error.message);
        res.status(500).json({ sucesso: false, erro: error.message });
    }
});

// ==========================================
// 🛡️ ROTA 1.1: DIAGNÓSTICO CCMEI (O QUE O GOVERNO DIZ)
// ==========================================
app.get('/api/serpro/ccmei/:userId', async (req, res) => {
    try {
        const { userId } = req.params;
        const users = await query(`SELECT cnpj FROM users WHERE id = ?`, [userId]);
        if (users.length === 0) return res.status(404).json({ error: "Usuário não encontrado" });
        
        const cnpj = users[0].cnpj;

        const resultado = await catraca.adicionar(async () => {
            const chaves = await serproAuth.getTokens();
            const response = await axios({
                method: 'POST',
                url: 'https://gateway.apiserpro.serpro.gov.br/integra-contador/v1/Consultar',
                headers: { 'Authorization': `Bearer ${chaves.bearer}`, 'jwt_token': chaves.jwt, 'Content-Type': 'application/json' },
                data: {
                    "contratante": { "numero": "28413885000170", "tipo": 2 },
                    "autorPedidoDados": { "numero": "28413885000170", "tipo": 2 },
                    "contribuinte": { "numero": cnpj, "tipo": 2 },
                    "pedidoDados": {
                        "idSistema": "CCMEI",
                        "idServico": "DADOSCCMEI122",
                        "versaoSistema": "1.0",
                        "dados": JSON.stringify({ "numeroCnpj": cnpj })
                    }
                },
                httpsAgent: chaves.agente
            });
            return response.data;
        });

        res.json({ sucesso: true, dados: JSON.parse(resultado.dados || "{}") });

    } catch (error) {
        console.error("❌ Erro CCMEI:", error.response?.data || error.message);
        res.status(500).json({ sucesso: false, erro: "Falha ao consultar prontuário do governo." });
    }
});

// ==========================================
// 💰 ROTA 1.2: EMISSÃO DE BOLETO DAS (MEI)
// ==========================================
app.post('/api/serpro/das/emitir', async (req, res) => {
    const { userId, periodo } = req.body; // periodo format: 'YYYYMM'

    try {
        const users = await query(`SELECT cnpj FROM users WHERE id = ?`, [userId]);
        if (users.length === 0) throw new Error("Usuário não encontrado.");
        
        const cnpj = users[0].cnpj;

        const resultado = await catraca.adicionar(async () => {
            const chaves = await serproAuth.getTokens();
            const response = await axios({
                method: 'POST',
                url: 'https://gateway.apiserpro.serpro.gov.br/integra-contador/v1/Emitir',
                headers: { 'Authorization': `Bearer ${chaves.bearer}`, 'jwt_token': chaves.jwt, 'Content-Type': 'application/json' },
                data: {
                    "contratante": { "numero": "28413885000170", "tipo": 2 },
                    "autorPedidoDados": { "numero": "28413885000170", "tipo": 2 },
                    "contribuinte": { "numero": cnpj, "tipo": 2 },
                    "pedidoDados": {
                        "idSistema": "PGMEI",
                        "idServico": "GERARDASCODBARRA22",
                        "versaoSistema": "1.0",
                        "dados": JSON.stringify({ "periodoApuracao": periodo })
                    }
                },
                httpsAgent: chaves.agente
            });
            return response.data;
        });

        res.json({ sucesso: true, dados: resultado });

    } catch (error) {
        console.error("🕵️‍♂️ ERRO DAS:", JSON.stringify(error.response?.data || error.message, null, 2));
        const msg = error.response?.data?.mensagens?.[0]?.texto || "Erro ao gerar boleto no Serpro.";
        res.status(500).json({ sucesso: false, erro: msg });
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
