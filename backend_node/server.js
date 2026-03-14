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
const { encrypt, decrypt } = require('./crypto_utils');
const forge = require('node-forge');
const fs = require('fs');
const multer = require('multer');

// Configura o Multer para RAM
const upload = multer({ 
    storage: multer.memoryStorage(),
    limits: { fileSize: 50 * 1024 } // 50KB Limite
});

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
// 🚀 ROTA 1: EMISSÃO NACIONAL (ADN/SEFIN) - MOTOR VORTEX
// ==========================================
app.post('/api/nacional/emitir', async (req, res) => {
    const { userId, payload } = req.body; 

    try {
        console.log(`📡 [Nacional] Requisição recebida do usuário: ${userId}`);

        // 1. Busca dados do Prestador e Certificado no Cofre (Joins soberanos)
        const results = await query(
            `SELECT u.cnpj, u.razao_social, u.producao, u.inscricao_municipal, u.possui_certificado,
                    c.id as cofre_id, c.arquivo_pfx, c.senha_encriptada
             FROM users u 
             LEFT JOIN cofre_certificados c ON c.usuario = u.id 
             WHERE u.id = ?`, 
            [userId]
        );

        if (results.length === 0) throw new Error("Usuário não encontrado.");
        const prestadorDb = results[0];

        // 🛡️ TRAVA SOBERANA: Sem certificado do cofre, não há emissão.
        if (!prestadorDb.possui_certificado || !prestadorDb.arquivo_pfx || !prestadorDb.senha_encriptada) {
            return res.status(403).json({ 
                sucesso: false, 
                erro: "Certificado Digital protegido não encontrado. Faça o upload no Perfil." 
            });
        }

        const certPath = path.resolve('C:/Users/Fernando/Desktop/pocketbase/pb_data/storage/cofrecertific00', prestadorDb.cofre_id, prestadorDb.arquivo_pfx);
        const certPass = decrypt(prestadorDb.senha_encriptada);

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

        // 3. Aciona o Motor VORTEX
        const resultado = await vortex.emitirNacional(payload, certPath, certPass);

        // 4. Salva no Banco de Dados (Log de Sucesso/Chave)
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
                erros: resultado.dados?.erros || [{ Descricao: "O Governo rejeitou a nota. Verifique o seu certificado e dados." }] 
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
        
        // 1. Busca do cofre isolado
        const results = await query(
            `SELECT u.cnpj, u.possui_certificado, c.id as cofre_id, c.arquivo_pfx, c.senha_encriptada
             FROM users u 
             LEFT JOIN cofre_certificados c ON c.usuario = u.id WHERE u.id = ?`, 
            [userId]
        );

        if (results.length === 0) return res.status(404).json({ error: "Usuário não encontrado" });
        const userDb = results[0];

        if (!userDb.possui_certificado || !userDb.arquivo_pfx || !userDb.senha_encriptada) {
            return res.status(403).json({ error: "Certificado não encontrado no cofre blindado." });
        }

        const certPath = path.resolve('C:/Users/Fernando/Desktop/pocketbase/pb_data/storage/cofrecertific00', userDb.cofre_id, userDb.arquivo_pfx);
        const certPass = decrypt(userDb.senha_encriptada);

        if (!certPass) {
             return res.status(403).json({ error: "Falha na descriptografia da senha. Recadastre no Perfil." });
        }

        // 2. Aciona o Serpro usando o certificado do usuário
        const resultado = await catraca.adicionar(async () => {
            const chaves = await serproAuth.getTokens(certPath, certPass);
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
// 💰 ROTA 1.2: EMISSÃO DE BOLETO DAS (MEI)
// ==========================================
app.post('/api/serpro/das/emitir', async (req, res) => {
    const { userId, periodo } = req.body; 

    try {
        const results = await query(
            `SELECT u.cnpj, u.possui_certificado, c.id as cofre_id, c.arquivo_pfx, c.senha_encriptada
             FROM users u 
             LEFT JOIN cofre_certificados c ON c.usuario = u.id WHERE u.id = ?`, 
            [userId]
        );

        if (results.length === 0) throw new Error("Usuário não encontrado.");
        const userDb = results[0];

        if (!userDb.possui_certificado || !userDb.arquivo_pfx || !userDb.senha_encriptada) {
            throw new Error("Certificado não encontrado no cofre.");
        }

        const certPath = path.resolve('C:/Users/Fernando/Desktop/pocketbase/pb_data/storage/cofrecertific00', userDb.cofre_id, userDb.arquivo_pfx);
        const certPass = decrypt(userDb.senha_encriptada);

        if (!certPass) {
             throw new Error("Falha ao abrir chave da AES Master do cofre.");
        }

        const resultado = await catraca.adicionar(async () => {
            const chaves = await serproAuth.getTokens(certPath, certPass);
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

        if (!arquivo || !senha_pfx || !userId) {
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

        // 1. Limpa cofre antigo se existir, mantendo consistência 1:1
        await pb.admins.authWithPassword(config.pocketbase.adminEmail, config.pocketbase.adminPassword);
        try {
            const existentes = await pb.collection('cofre_certificados').getFullList({ filter: `usuario="${userId}"` });
            for (let r of existentes) {
                await pb.collection('cofre_certificados').delete(r.id);
            }
        } catch(e) { }

        // 2. Transfere arquivo RAM (Buffer) => Blob (FormData PB)
        const formData = new FormData();
        formData.append('usuario', userId);
        formData.append('senha_encriptada', senhaCifrada);
        formData.append('valido', true);
        if (dataVencimentoStr) {
            formData.append('data_vencimento', dataVencimentoStr);
        }
        
        const blobArquivo = new Blob([arquivo.buffer]);
        formData.append('arquivo_pfx', blobArquivo, arquivo.originalname);

        // 3. Salva no Vault PocketBase
        const registro = await pb.collection('cofre_certificados').create(formData);

        // 4. Update de sinalização no Users (sem guardar a senha/arquivo aqui!)
        let vencimentoMsg = "Aguardando";
        if (dataVencimentoStr) {
            await pb.collection('users').update(userId, {
                vencimento_pfx: dataVencimentoStr,
                possui_certificado: true,
                // Opcional: apagar as colunas antigas 
                arquivo_pfx: null,
                senha_pfx: ''
            });
            vencimentoMsg = `Válido até ${new Date(dataVencimentoStr).toLocaleDateString('pt-BR')}`;
        }

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
        pb.authStore.clear(); // Fechar portões!
    }
});

// LIGANDO O MOTOR
// ==========================================
const PORTA = config.servidor.port;
app.listen(PORTA, () => {
    console.log(`\n🛡️  MEIRE ONLINE: Ambiente de [${config.isProducao ? 'PRODUÇÃO' : 'TESTES'}]`);
    console.log(`🟢 Servidor Meire App na porta ${PORTA}`);
    console.log(`⏳ Aguardando comandos do aplicativo...\n`);
});
