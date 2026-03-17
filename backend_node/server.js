const config = require('./config');
const express = require('express');
const cors = require('cors');
const axios = require('axios');
const proxy = require('express-http-proxy');

// Importando a sua Engenharia
const serproAuth = require('./serpro_auth');
const catraca = require('./catraca_serpro');
const sqlite3 = require('sqlite3').verbose();
const vortex = require('./vortex_emissor_nacional');
const zlib = require('zlib');
const path = require('path');
const { encrypt, decrypt } = require('./crypto_utils');
const forge = require('node-forge');
const { baixarDanfsePDF } = require('./danfse_service');
const fs = require('fs');
const multer = require('multer');

// Nicho Beleza
const { setupBeautyNiche } = require('./scripts/setup_beauty_niche');

// Configura o Multer para RAM
const upload = multer({ 
    storage: multer.memoryStorage(),
    limits: { fileSize: 500 * 1024 } // 500KB Limite para certificados maiores
});

const DB_PATH = config.isProducao 
    ? '/home/ubuntu/pb_data/data.db' 
    : 'C:/Users/Fernando/Desktop/pocketbase/pb_data/data.db';

const STORAGE_PATH = config.isProducao
    ? '/home/ubuntu/pb_data/storage'
    : 'C:/Users/Fernando/Desktop/pocketbase/pb_data/storage';

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
console.log(`🔗 Conectando ao PocketBase em: ${config.pocketbase.url} (Admin: ${config.pocketbase.adminEmail})`);

// 🛡️ MOTOR DE SOBERANIA: Autentica como SUPERUSER globalmente para ignorar API Rules
async function assegurarAutenticacao() {
    if (pb.authStore.isValid) return;
    try {
        await pb.collection('_superusers').authWithPassword(config.pocketbase.adminEmail, config.pocketbase.adminPassword);
        console.log("🚀 Backend re-autenticado como SUPERUSER.");
    } catch (e) {
        console.error("❌ Falha crítica ao autenticar superusuário no PocketBase:", e.message);
        throw e;
    }
}

// Autentica na subida
assegurarAutenticacao();

/**
 * ZELADORIA ON-DEMAND: Busca no governo, salva no PocketBase e retorna o buffer.
 */
async function sincronizarESalvarPDF(userId, chaveAcesso, notaId) {
    try {
        // 1. O Backend já opera como SUPERUSER automaticamente via startup.
        await assegurarAutenticacao();


        // 2. BUSCA O USUÁRIO (Para saber se é Produção ou Homologação)
        const userResults = await query(`SELECT producao FROM users WHERE id = ?`, [userId]);
        if (userResults.length === 0) throw new Error("Usuário não encontrado.");
        const isProducao = userResults[0].producao === 1;

        // 3. BUSCA O CERTIFICADO via SDK para pegar o collectionId dinâmico
        const certRecord = await pb.collection('cofre_certificados').getFirstListItem(`usuario="${userId}" && valido=true`);
        
        // 3.1 Construção do Caminho Absoluto Dinâmico
        const certPath = path.resolve(STORAGE_PATH, certRecord.collectionId, certRecord.id, certRecord.arquivo_pfx);
        
        console.log(`📂 [Zeladoria] Tentando abrir certificado em: ${certPath} (Ambiente: ${isProducao ? 'PRD' : 'HOM'})`);

        if (!fs.existsSync(certPath)) {
            throw new Error("ERRO_PFX: Arquivo físico do certificado não localizado no servidor.");
        }

        const certPass = decrypt(certRecord.senha_encriptada);
        if (!certPass) throw new Error("Falha na descriptografia da senha do certificado.");

        // 4. Monta o túnel mTLS e busca o PDF no Governo
        const tokensGov = await serproAuth.getTokens(certPath, certPass, isProducao);
        const ambienteGov = isProducao ? '1' : '2';
        const pdfBuffer = await baixarDanfsePDF(chaveAcesso, ambienteGov, tokensGov.agente);

        // 5. PERSISTÊNCIA: Cache no PocketBase para acessos futuros
        try {
            const formData = new FormData();
            formData.append('pdf_nota', new Blob([pdfBuffer], { type: 'application/pdf' }), `DANFSE-${chaveAcesso}.pdf`);
            formData.append('status', 'CONCLUIDA');
            await pb.collection('notas_fiscais').update(notaId, formData);
            console.log(`✅ [ZELADORIA-ON-DEMAND] PDF arquivado com sucesso no campo 'pdf_nota'.`);
        } catch (errPb) {
            console.error("⚠️ [Vault] Erro ao arquivar PDF (mas a entrega continuará):", errPb.message);
        }

        return pdfBuffer;
    } catch (err) {
        console.error("❌ [Zeladoria-Falha]:", err.message);
        throw err;
    } finally {
        // pb.authStore.clear(); // Mantemos o portão aberto para o Superusuário
    }
}

// Nota: Removemos checkPBAuth porque agora o Node fala direto com o BD SQLITE do PocketBase
// para evitar conflitos de versão do SDK ou regras de acesso (403/404).

const app = express();

// CONFIGURAÇÃO DE SEGURANÇA CORS (PRODUÇÃO)
app.use(cors({
    origin: (origin, callback) => {
        // Permite qualquer localhost (comum no Flutter Web debug) ou os domínios oficiais
        if (!origin || origin.startsWith('http://localhost:') || origin.startsWith('http://127.0.0.1:') || 
            origin === 'https://meireapp.com.br' || origin === 'https://www.meireapp.com.br') {
            callback(null, true);
        } else {
            callback(new Error('Bloqueado pelo CORS do Meire'));
        }
    },
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With', 'Accept'],
    credentials: true
}));

app.use(express.json());

// Log de Debug para todas as requisições
app.use((req, res, next) => {
    console.log(`🌐 [${new Date().toLocaleTimeString()}] ${req.method} ${req.url}`);
    if (Object.keys(req.body || {}).length > 0) {
        console.log(`   📦 Body keys: ${Object.keys(req.body || {}).join(', ')}`);
    }
    next();
});



// Middleware para capturar 404 residuais (Caso o proxy falhe)
const catch404 = (req, res) => {
    console.warn(`⚠️ [404] Rota não encontrada: ${req.method} ${req.originalUrl}`);
    res.status(404).json({ error: "Recurso não encontrado no ecossistema Meire." });
};

// 🟢 ROTA DE STATUS (SAÚDE DO SISTEMA)
app.get('/api/status', (req, res) => {
    res.json({ 
        sucesso: true,
        status: "OPERACIONAL",
        motor: "Meire Engine v2.2.0",
        ambiente: config.isProducao ? "PRODUÇÃO" : "TESTES",
        vault: "Conectado",
        timestmap: new Date().toISOString()
    });
});

// 🔍 ROTA 6: BUSCA DE CNPJ (BRASIL API)
app.get('/api/cnpj/:cnpj', async (req, res) => {
    try {
        const { cnpj } = req.params;
        const cleanCnpj = cnpj.replace(/\D/g, '');
        
        console.log(`🔍 [CNPJ] Buscando dados da empresa: ${cleanCnpj}`);
        
        const response = await axios.get(`https://brasilapi.com.br/api/cnpj/v1/${cleanCnpj}`, {
            timeout: 5000 // 5 segundos de limite
        });

        if (response.data) {
            const data = response.data;
            
            // Verifica se a empresa está ativa
            if (data.descricao_situacao_cadastral !== 'ATIVA') {
                return res.status(400).json({ 
                    sucesso: false, 
                    erro: 'Este CNPJ não está ATIVO na Receita Federal.' 
                });
            }

            res.json({
                sucesso: true,
                razao_social: data.razao_social,
                nome_fantasia: data.nome_fantasia || data.razao_social,
                situacao: data.descricao_situacao_cadastral,
                cep: data.cep,
                logradouro: data.logradouro,
                numero: data.numero,
                bairro: data.bairro,
                municipio: data.municipio,
                uf: data.uf
            });
        }
    } catch (error) {
        console.error("❌ [CNPJ] Erro na consulta:", error.message);
        if (error.response?.status === 404) {
            return res.status(404).json({ sucesso: false, erro: "CNPJ não encontrado na base do Governo." });
        }
        res.status(500).json({ sucesso: false, erro: "Falha técnica ao consultar o Governo. Tente novamente." });
    }
});

// ==========================================
// 🌸 ROTA 0: ONBOARDING NICHO BELEZA
// ==========================================
app.post('/api/onboarding/beauty', async (req, res) => {
    await assegurarAutenticacao();
    const { userId } = req.body;
    try {
        const record = await setupBeautyNiche(userId);
        res.json({ sucesso: true, mensagem: "Configuração de Beleza concluída!", favoritoId: record.id });
    } catch (e) {
        res.status(500).json({ sucesso: false, erro: e.message });
    }
});

// ==========================================
// 🚀 ROTA 1: EMISSÃO NACIONAL (ADN/SEFIN) - MOTOR VORTEX
// 🛡️ ESCUDO MEIRI: Proibido alterar sem rodar sacred_guard.js
// ==========================================
app.post('/api/nacional/emit', async (req, res) => {
    await assegurarAutenticacao();
    const { userId, payload } = req.body; 

    try {
        console.log(`📡 [Nacional] Requisição recebida do usuário: ${userId}`);
        
        // 🔒 BLINDAGEM DA COMPETÊNCIA: Nunca assumir o dia atual.
        if (!payload?.competencia) {
            console.error("❌ [Erro] Tentativa de emissão sem competência definida.");
            return res.status(400).json({ sucesso: false, erro: "A data de competência é obrigatória e não foi informada pelo aplicativo." });
        }

        console.log(`📌 [Competência] Mês de Referência: ${payload.competencia}`);

        // 1. Busca dados do Prestador
        const results = await query(`SELECT cnpj, razao_social, producao, inscricao_municipal FROM users WHERE id = ?`, [userId]);
        if (results.length === 0) throw new Error("Usuário não encontrado.");
        const prestadorDb = results[0];

        // 2. Busca o Certificado via SDK (Cofre Blindado)
        const certRecord = await pb.collection('cofre_certificados').getFirstListItem(`usuario="${userId}" && valido=true`);
        
        const certPath = path.resolve(STORAGE_PATH, certRecord.collectionId, certRecord.id, certRecord.arquivo_pfx);
        const certPass = decrypt(certRecord.senha_encriptada);

        if (!certPass) {
             return res.status(403).json({ sucesso: false, erro: "Senha do cofre inválida ou corrompida. Por favor, recadastre o certificado." });
        }

        // 2. Enriquecendo o Payload com dados do Banco
        payload.prestador = {
            cnpj: prestadorDb.cnpj,
            im: prestadorDb.inscricao_municipal,
            opcaoSimplesNacional: payload.prestador?.opcaoSimplesNacional || "2",
            regimeEspecialTributacao: payload.prestador?.regimeEspecialTributacao || "0"
        };
        payload.ambiente = prestadorDb.producao ? "1" : "2";

        console.log(`🌍 [Nacional] Ambiente: ${payload.ambiente === "1" ? "PRODUÇÃO" : "HOMOLOGAÇÃO"}`);
        console.log(`🏢 [Nacional] Prestador: ${payload.prestador.cnpj}`);
        console.log(`👤 [Nacional] Tomador: ${payload.tomador.cnpj} (${payload.tomador.nome})`);

        // 3. Aciona o Motor VORTEX (Com Trava Real/Teste Dinâmica)
        console.log(`📡 [VORTEX] Payload Final para Motor:`, JSON.stringify({ 
            ...payload, 
            prestador: { ...payload.prestador, certPath: 'redacted' } 
        }, null, 2));
        const resultado = await vortex.emitirNacional(payload, certPath, certPass, prestadorDb.producao);

        let novoRegistroId = null;
        // 4. Salva no Banco de Dados via SDK (Mais seguro que SQL direto para colunas novas)
        try {
            // O Backend já opera como SUPERUSER
            
            const logData = {
                "user": userId,
                "tomador_cnpj": payload.tomador.cnpj,
                "tomador_nome": payload.tomador.nome || payload.tomador.razaoSocial,
                "valor": parseFloat(payload.servico.valor) || 0,
                "servico": payload.servico.descricao,
                "numero_nota": payload.numeroDPS,
                "status": resultado.sucesso ? 'CONCLUIDA' : 'ERRO',
                "chave_acesso": resultado.dados?.chaveAcesso || '',
                "xml_nota": resultado.dados?.xmlDecodificado || '',
                "competencia": payload.competencia,
                "motivo_rejeicao": resultado.sucesso ? '' : (resultado.dados?.erros?.[0]?.Descricao || 'Rejeição desconhecida pelo Governo')
            };

            console.log("📝 Tentando registrar no PocketBase...");
            // console.log("Dados do Log:", JSON.stringify(logData, null, 2));

            const novoRegistro = await pb.collection('notas_fiscais').create(logData);
            novoRegistroId = novoRegistro.id;
            console.log("✅ Log salvo com sucesso! ID:", novoRegistroId);
        } catch (errLog) {
            console.error("❌ ERRO NO POCKETBASE:", JSON.stringify(errLog.data || errLog.message, null, 2));
            console.error("⚠️ [Vault] Erro ao salvar log no PocketBase (mas a emissão ocorreu):", errLog.message);
        } finally {
            // pb.authStore.clear(); 
        }

        if (resultado.sucesso) {
            console.log(`✅ [Nacional] Nota emitida com sucesso! Chave: ${resultado.dados.chaveAcesso}`);
            res.json({ 
                sucesso: true, 
                chaveAcesso: resultado.dados.chaveAcesso,
                idNota: novoRegistroId
            });
        } else {
            console.error("❌ [Nacional] O Governo REJEITOU a nota:", JSON.stringify(resultado.dados, null, 2));
            res.status(400).json({ 
                sucesso: false, 
                erros: resultado.dados?.erros || [{ Descricao: "O Governo rejeitou a nota. Verifique o seu certificado e dados." }] 
            });
        }

    } catch (error) {
        console.error("❌ Erro na Emissão Nacional:", error.message);
        res.status(500).json({ sucesso: false, erro: error.message });
    }
});

// ==========================================
// 📊 ROTA 1.0.1: RESUMO DO DASHBOARD (MÉTRICAS METICULOSAS)
// ==========================================
app.get('/api/dashboard/resumo/:userId', async (req, res) => {
    try {
        const { userId } = req.params;
        const anoAtual = new Date().getFullYear();
        // Formato SQLite: YYYY-MM-DD HH:MM:SS
        const inicioAno = `${anoAtual}-01-01 00:00:00`; 

        // 1. Busca o faturamento acumulado do ano (priorizando a data de competência)
        const somaRows = await query(`
            SELECT SUM(valor) as total, COUNT(id) as qtd 
            FROM notas_fiscais 
            WHERE user = ? AND status = 'CONCLUIDA' AND (competencia >= ? OR (competencia IS NULL AND created >= ?))
        `, [userId, inicioAno, inicioAno]);

        const faturamentoTotal = somaRows[0].total || 0;
        const qtdEmitida = somaRows[0].qtd || 0;
        const limiteMEI = 81000;
        const percentualUso = (faturamentoTotal / limiteMEI) * 100;

        // 2. Pega as últimas 5 notas para o histórico rápido
        const notas = await query(`
            SELECT id, tomador_nome, valor, created, status, chave_acesso 
            FROM notas_fiscais 
            WHERE user = ? 
            ORDER BY created DESC 
            LIMIT 5
        `, [userId]);

        const notasFormatadas = notas.map(nota => ({
            id: nota.id,
            tomador: nota.tomador_nome,
            valor: nota.valor,
            data: nota.created,
            status: nota.status,
            chave_acesso: nota.chave_acesso
        }));

        res.status(200).json({
            faturamento_ano: faturamentoTotal,
            limite_mei: limiteMEI,
            percentual_atingido: percentualUso.toFixed(2),
            qtd_notas_emitidas: qtdEmitida,
            notas_recentes: notasFormatadas 
        });

    } catch (error) {
        console.error("❌ Erro no Motor do Dashboard:", error.message);
        res.status(500).json({ erro: "Falha ao carregar métricas do dashboard." });
    }
});

// ==========================================
// 🛡️ ROTA 1.1: DIAGNÓSTICO CCMEI (O QUE O GOVERNO DIZ)
// ==========================================
app.get('/api/serpro/ccmei/:userId', async (req, res) => {
    try {
        const { userId } = req.params;
        
        // 1. Busca o usuário
        const results = await query(`SELECT cnpj, producao FROM users WHERE id = ?`, [userId]);
        if (results.length === 0) return res.status(404).json({ error: "Usuário não encontrado" });
        const userDb = results[0];

        // 2. Busca o certificado via SDK (Dinâmico)
        const certRecord = await pb.collection('cofre_certificados').getFirstListItem(`usuario="${userId}" && valido=true`);
        
        const certPath = path.resolve(STORAGE_PATH, certRecord.collectionId, certRecord.id, certRecord.arquivo_pfx);
        const certPass = decrypt(certRecord.senha_encriptada);

        if (!certPass) {
             return res.status(403).json({ error: "Falha na descriptografia da senha. Recadastre no Perfil." });
        }

        // 2. Aciona o Serpro usando o certificado do usuário
        const resultado = await catraca.adicionar(async () => {
            const chaves = await serproAuth.getTokens(certPath, certPass, userDb.producao);
            const response = await axios({
                method: 'POST',
                url: 'https://gateway.apiserpro.serpro.gov.br/integra-contador/v1/Consultar',
                headers: { 
                    'Authorization': `Bearer ${chaves.bearer}`, 
                    'jwt_token': chaves.jwt, 
                    'Content-Type': 'application/json' 
                },
                data: {
                    "contratante": { "numero": userDb.cnpj, "tipo": 2 },
                    "autorPedidoDados": { "numero": userDb.cnpj, "tipo": 2 },
                    "contribuinte": { "numero": userDb.cnpj, "tipo": 2 },
                    "pedidoDados": {
                        "idSistema": "CCMEI",
                        "idServico": "DADOSCCMEI122",
                        "versaoSistema": "1.0",
                        "dados": JSON.stringify({ "numeroCnpj": userDb.cnpj })
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
// 📄 ROTA 1.3: BUSCAR PDF DO DANFSE (JSON para Flutter)
// ==========================================
app.get('/api/nacional/danfse/:userId/:chaveAcesso', async (req, res) => {
    try {
        const { userId, chaveAcesso } = req.params;

        const notaCheck = await query(
            `SELECT id, status, pdf_nota FROM notas_fiscais WHERE user = ? AND chave_acesso = ?`,
            [userId, chaveAcesso]
        );

        if (notaCheck.length === 0) {
            return res.status(404).json({ sucesso: false, erro: "Nota não encontrada." });
        }

        const notaDb = notaCheck[0];

        // 1. CHECAGEM DE CACHE LOCAL
        if (notaDb.pdf_nota) {
            const storagePathNf = config.isProducao
                ? `/home/ubuntu/pb_data/storage/pbc_423607009/${notaDb.id}/${notaDb.pdf_nota}`
                : `C:/Users/Fernando/Desktop/pocketbase/pb_data/storage/pbc_423607009/${notaDb.id}/${notaDb.pdf_nota}`;
            
            if (fs.existsSync(storagePathNf)) {
                console.log(`⚡ [Cache] Enviando PDF local para: ${chaveAcesso}`);
                const pdfBuffer = fs.readFileSync(storagePathNf);
                return res.json({
                    sucesso: true,
                    pdfBase64: pdfBuffer.toString('base64'),
                    nomeArquivo: `Meire_NotaFiscal_${chaveAcesso}.pdf`,
                    origem: 'cache_local'
                });
            }
        }

        // 2. DISPARO DE ZELADORIA ON-DEMAND (Se não tem no cache)
        console.log(`🌐 [Zeladoria] Capturando PDF oficial no Governo para: ${chaveAcesso}`);
        const pdfBuffer = await sincronizarESalvarPDF(userId, chaveAcesso, notaDb.id);

        res.json({
            sucesso: true,
            pdfBase64: pdfBuffer.toString('base64'),
            nomeArquivo: `Meire_NotaFiscal_${chaveAcesso}.pdf`,
            origem: 'governo_real'
        });

    } catch (error) {
        console.error("❌ Erro ao buscar DANFSe:", error.message);
        const isGovWait = error.message.includes('ERRO_404') || error.message.includes('not found');
        res.status(isGovWait ? 404 : 500).json({ 
            sucesso: false, 
            erro: isGovWait ? "O Governo ainda está gerando o PDF. Aguarde 60s e tente novamente." : error.message 
        });
    }
});

// ==========================================
// 📄 ROTA 1.3.1: BUSCAR PDF BINÁRIO (Proxy Direto / Navegador)
// ==========================================
app.get('/api/nacional/pdf/:userId/:chaveAcesso', async (req, res) => {
    try {
        const { userId, chaveAcesso } = req.params;

        // 1. Localizar nota
        const notaCheck = await query(
            `SELECT id, status, pdf_nota FROM notas_fiscais WHERE user = ? AND chave_acesso = ?`,
            [userId, chaveAcesso]
        );

        if (notaCheck.length === 0) return res.status(404).send("Nota não encontrada.");
        const notaDb = notaCheck[0];

        // 2. Cache ou Governo
        let pdfBuffer;
        if (notaDb.pdf_nota) {
            const storagePathNf = config.isProducao
                ? `/home/ubuntu/pb_data/storage/pbc_423607009/${notaDb.id}/${notaDb.pdf_nota}`
                : `C:/Users/Fernando/Desktop/pocketbase/pb_data/storage/pbc_423607009/${notaDb.id}/${notaDb.pdf_nota}`;
            
            if (fs.existsSync(storagePathNf)) {
                pdfBuffer = fs.readFileSync(storagePathNf);
            }
        }

        if (!pdfBuffer) {
            pdfBuffer = await sincronizarESalvarPDF(userId, chaveAcesso, notaDb.id);
        }

        res.contentType("application/pdf");
        res.setHeader("Content-Disposition", `inline; filename=DANFSE-${chaveAcesso}.pdf`);
        res.send(pdfBuffer);

    } catch (error) {
        console.error("❌ [PDF-PROXY] Erro:", error.message);
        res.status(404).send("PDF ainda não disponível no Governo. Tente em instantes.");
    }
});

// ==========================================
// 💰 ROTA 1.4: EMISSÃO DE BOLETO DAS (MEI)
// ==========================================
app.post('/api/serpro/das/emitir', async (req, res) => {
    const { userId, periodo } = req.body; 

    try {
        // 1. Busca dados do usuário
        const results = await query(`SELECT cnpj, producao FROM users WHERE id = ?`, [userId]);
        if (results.length === 0) throw new Error("Usuário não encontrado.");
        const userDb = results[0];

        // 2. Busca o certificado via SDK
        const certRecord = await pb.collection('cofre_certificados').getFirstListItem(`usuario="${userId}" && valido=true`);
        
        const certPath = path.resolve(STORAGE_PATH, certRecord.collectionId, certRecord.id, certRecord.arquivo_pfx);
        const certPass = decrypt(certRecord.senha_encriptada);

        if (!certPass) {
             throw new Error("Falha ao abrir chave da AES Master do cofre.");
        }

        const resultado = await catraca.adicionar(async () => {
            const chaves = await serproAuth.getTokens(certPath, certPass, userDb.producao);
            const response = await axios({
                method: 'POST',
                url: 'https://gateway.apiserpro.serpro.gov.br/integra-contador/v1/Emitir',
                headers: { 
                    'Authorization': `Bearer ${chaves.bearer}`, 
                    'jwt_token': chaves.jwt, 
                    'Content-Type': 'application/json' 
                },
                data: {
                    "contratante": { "numero": userDb.cnpj, "tipo": 2 },
                    "autorPedidoDados": { "numero": userDb.cnpj, "tipo": 2 },
                    "contribuinte": { "numero": userDb.cnpj, "tipo": 2 },
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

        // Buscamos notas pelo campo de competência (mais preciso para impostos)
        const records = await query(`
            SELECT valor FROM notas_fiscais 
            WHERE user = ? 
            AND status IN ('emitida', 'CONCLUIDA', 'Autorizada')
            AND (competencia LIKE ? OR (competencia IS NULL AND created LIKE ?))
        `, [userId, `${anoAtual}-${mesAtualNum}%`, `${anoAtual}-${mesAtualNum}%`]);

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

        // Priorizamos a data de competência para o histórico visual
        const records = await query(`
            SELECT valor, created, competencia FROM notas_fiscais 
            WHERE user = ? 
            AND status IN ('emitida', 'CONCLUIDA', 'Autorizada')
            ORDER BY COALESCE(competencia, created) DESC
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
            // Usa competência se disponível, senão usa a data de criação
            const dataBase = nota.competencia || nota.created;
            const dataNota = new Date(dataBase);
            
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
            mensagem: "Este arquivo contém todos os seus dados processados pela Meire App. Você tem o direito de portabilidade desses dados conforme a LGPD."
        };

        res.json(pacoteDados);

    } catch (error) {
        console.error("❌ [LGPD] Falha na exportação:", error.message);
        res.status(500).json({ error: "Falha ao gerar pacote de dados para exportação." });
    }
});

// ==========================================
// 🔐 ROTA 5: UPLOAD PARA COFRE BLINDADO (MULTER EM RAM)
// ==========================================
app.post('/api/certificados/upload', upload.single('arquivo_pfx'), async (req, res) => {
    try {
        const { userId, senha_pfx } = req.body;
        const arquivo = req.file;

        console.log(`📥 [Upload] Recebida tentativa de upload para usuário: ${userId}`);
        console.log(`   - Arquivo: ${arquivo ? arquivo.originalname : 'Nulo'}`);
        console.log(`   - Tamanho: ${arquivo ? arquivo.size : 0} bytes`);

        if (!arquivo || !senha_pfx || !userId) {
            console.error("❌ [Upload] Dados incompletos");
            return res.status(400).json({ erro: "Faltam dados obrigatórios. Arquivo ou senha perdidos." });
        }

        console.log(`🔐 [Vault] Encriptando cofre do usuário na memória: ${userId}`);
        const senhaCifrada = encrypt(senha_pfx);
        if (!senhaCifrada) {
            throw new Error("Falha ao criptografar a senha na memória.");
        }

        // Tenta Extrair Data Validade no ar (da memória!)
        let dataVencimentoStr = null;
        try {
            const p12Der = arquivo.buffer.toString('binary');
            const p12Asn1 = forge.asn1.fromDer(p12Der);
            const p12 = forge.pkcs12.pkcs12FromAsn1(p12Asn1, senha_pfx);

            Extrator: for (const safeContent of p12.safeContents) {
                for (const safeBag of safeContent.safeBags) {
                    if (safeBag.type === forge.pki.oids.certBag && safeBag.cert && safeBag.cert.validity) {
                        dataVencimentoStr = safeBag.cert.validity.notAfter.toISOString();
                        break Extrator;
                    }
                }
            }
        } catch (errExt) {
            console.warn(`⚠️ [Vault] Senha errada ou PFX corrompido para usuario ${userId}`, errExt.message);
            return res.status(400).json({ erro: "A senha fornecida está incorreta para este certificado, ou formato do PFX não suportado." });
        }

        // 1. Autentica como Superusuário (Necessário para acessar coleções com regras restritas)
        await assegurarAutenticacao();


        // 2. Transfere arquivo RAM (Buffer) => File (Padrão PB SDK)
        const formData = new FormData();
        formData.append('usuario', userId);
        formData.append('senha_encriptada', senhaCifrada);
        formData.append('valido', 'true');
        if (dataVencimentoStr) {
            formData.append('data_vencimento', dataVencimentoStr);
        }
        
        // Criamos um File que o SDK do PB ama (Node 24+)
        const fileArquivo = new File([arquivo.buffer], arquivo.originalname, { type: 'application/x-pkcs12' });
        formData.append('arquivo_pfx', fileArquivo);

        // 3. Salva no Vault PocketBase (Lógica de Upsert Soberana)
        let registro;
        try {
            // Tenta buscar se o usuário JÁ TEM um cofre
            const cofreExistente = await pb.collection('cofre_certificados').getFirstListItem(`usuario="${userId}"`);
            console.log(`🔄 [Vault] Atualizando cofre existente para: ${userId}`);
            registro = await pb.collection('cofre_certificados').update(cofreExistente.id, formData);
        } catch (errUpsert) {
            if (errUpsert.status === 404) {
                console.log(`✨ [Vault] Criando novo cofre para: ${userId}`);
                registro = await pb.collection('cofre_certificados').create(formData);
            } else {
                throw errUpsert;
            }
        }

        // 4. Update de sinalização no Users (sem guardar a senha/arquivo aqui!)
        const updateData = {
            possui_certificado: true,
            arquivo_pfx: null,
            senha_pfx: ''
        };

        if (dataVencimentoStr) {
            updateData.vencimento_pfx = dataVencimentoStr;
        }

        await pb.collection('users').update(userId, updateData);

        const vencimentoMsg = dataVencimentoStr 
            ? `Válido até ${new Date(dataVencimentoStr).toLocaleDateString('pt-BR')}`
            : "Certificado Ativo (Data não extraída)";

        // A senha morre quando essa função limpa o stack!
        res.status(201).json({ 
            mensagem: "Certificado guardado no cofre isolado com sucesso!",
            idRegistro: registro.id,
            vencimento: vencimentoMsg 
        });

    } catch (error) {
        console.error("❌ Erro no Vault Blindado:", error.message);
        res.status(500).json({ erro: "Falha interna ao depositar no cofre." });
    } finally {
        // pb.authStore.clear(); // Mantenha os portões abertos para o Admin
    }
});

// 🔄 GATEWAY INTELIGENTE (ESTRATÉGIA MEIRE) - REDIRECIONAMENTO PARA POCKETBASE
app.use('/', proxy('http://127.0.0.1:8090', {
    proxyReqPathResolver: (req) => {
        console.log(`🚀 [PROXY] Encaminhando: ${req.method} ${req.originalUrl}`);
        return req.originalUrl;
    },
    // A MÁGICA: Empacota o body de novo se o Node já o tiver consumido (express.json)
    proxyReqBodyDecorator: function(bodyContent, srcReq) {
        if (['POST', 'PATCH', 'PUT'].includes(srcReq.method) && srcReq.body && Object.keys(srcReq.body).length > 0) {
            return JSON.stringify(srcReq.body);
        }
        return bodyContent;
    },
    proxyReqOptDecorator: function(proxyReqOpts, srcReq) {
        if (['POST', 'PATCH', 'PUT'].includes(srcReq.method) && srcReq.body && Object.keys(srcReq.body).length > 0) {
            proxyReqOpts.headers['Content-Type'] = 'application/json';
        }
        return proxyReqOpts;
    },
    // Aumentamos o timeout para suportar SSE (Realtime) do PocketBase
    proxyTimeout: 0, 
    userResHeaderDecorator: (headers, userReq, userRes, proxyReq, proxyRes) => {
        // Para Realtime (SSE), precisamos evitar que o proxy faça buffer
        if (userReq.originalUrl.includes('/api/realtime')) {
            headers['cache-control'] = 'no-cache';
            headers['connection'] = 'keep-alive';
            headers['x-accel-buffering'] = 'no'; // Importante se houver Nginx/Cloudflare
        }

        // Força os headers de CORS da Meire para evitar bloqueios no Flutter
        const origin = userReq.headers.origin;
        if (origin && (origin.startsWith('http://localhost:') || origin.startsWith('http://127.0.0.1:'))) {
            headers['access-control-allow-origin'] = origin;
        } else {
            headers['access-control-allow-origin'] = 'https://meireapp.com.br';
        }
        headers['access-control-allow-credentials'] = 'true';
        headers['access-control-allow-methods'] = 'GET,POST,PUT,PATCH,DELETE,OPTIONS';
        headers['access-control-allow-headers'] = 'Content-Type, Authorization, X-Requested-With, Accept';
        
        return headers;
    },
    userResDecorator: function(proxyRes, proxyResData, userReq, userRes) {
        if (proxyRes.statusCode >= 400) {
            console.error(`❌ [PROXY-ERROR] ${userReq.method} ${userReq.url} -> Status ${proxyRes.statusCode}`);
            console.error(`📦 [PROXY-ERROR-BODY] ${proxyResData.toString()}`);
        }
        return proxyResData;
    }
}));

// Captura rotas não encontradas (Deve ser a última antes do listen)
app.use(catch404);

// LIGANDO O MOTOR
// ==========================================
const PORTA = config.servidor.port;
app.listen(PORTA, () => {
    console.log(`\n🛡️  MEIRE ONLINE: Ambiente de [${config.isProducao ? 'PRODUÇÃO' : 'TESTES'}]`);
    console.log(`🟢 Servidor Meire App na porta ${PORTA}`);
    console.log(`⏳ Aguardando comandos do aplicativo...\n`);
});
