const cron = require('node-cron');
const serproAuth = require('./serpro_auth');
const catraca = require('./catraca_serpro');
const path = require('path');
const fs = require('fs');
const PocketBase = require('pocketbase/cjs');
const config = require('./config');
const { decrypt } = require('./crypto_utils');

const pb = new PocketBase(config.pocketbase.url);

// O robô herda as configurações carregadas pelo crypto_utils e config acima.
if (!process.env.MASTER_KEY_AES) {
    console.error("❌ ERRO FATAL: MASTER_KEY_AES não carregada.");
    process.exit(1);
}

async function baixarExtratoCliente(cliente, chavesSapi) {
    // Aqui entraria a lógica real do Axios batendo no Serpro
    return new Promise(resolve => {
        setTimeout(() => {
            const identificador = cliente?.name || cliente?.razao_social || "Cliente";
            console.log(`📁 [SERPRO] Extrato de ${identificador} (CNPJ: ${cliente?.cnpj}) baixado e salvo no PocketBase!`);
            resolve(true);
        }, 800);
    });
}

async function executarRotinaNoturna() {
    console.log('\n==================================================');
    console.log(`⏰ [${new Date().toLocaleString('pt-BR')}] INICIANDO ROTINA DE MADRUGADA...`);

    try {
        // 1. Autenticação Administrativa
        await pb.collection('_superusers').authWithPassword(config.pocketbase.adminEmail, config.pocketbase.adminPassword);

        // 2. Busca todos os certificados válidos no cofre
        const registros = await pb.collection('cofre_certificados').getFullList({
            filter: 'valido = true',
            expand: 'usuario'
        });

        if (registros.length === 0) {
            console.log("🔎 NENHUM certificado ativo encontrado no cofre.");
            return;
        }

        console.log(`🤖 Processando ${registros.length} certificados ativos...`);
        const promessas = [];

        for (const registro of registros) {
            try {
                const usuario = registro.expand?.usuario;
                const usuarioNome = usuario?.name || usuario?.razao_social || "Sem Nome";
                const usuarioCNPJ = usuario?.cnpj || registro.cnpj_interessado || "CNPJ não informado";

                console.log(`\n🦉 Zelando por: ${usuarioNome} (${usuarioCNPJ})`);
                
                const storageBase = config.isProducao
                    ? '/home/ubuntu/pb_data/storage'
                    : 'C:/Users/Fernando/Desktop/pocketbase/pb_data/storage';

                const certPath = path.join(storageBase, registro.collectionId, registro.id, registro.arquivo_pfx);

                if (!fs.existsSync(certPath)) {
                    console.error(`❌ Arquivo não localizado: ${certPath}`);
                    continue;
                }

                // 4. PREPARAÇÃO DE CREDENCIAIS
                const senhaCert = decrypt(registro.senha_encriptada);
                if (!senhaCert) {
                    console.error(`❌ Falha na descriptografia para: ${usuarioNome}`);
                    continue;
                }

                // 5. ENFILEIRA NA CATRACA (Zeladoria do SERPRO)
                const tarefa = catraca.adicionar(async () => {
                    // Logamos quando o processamento REAL começa para este cliente
                    return baixarExtratoCliente(usuario, null);
                });
                promessas.push(tarefa);

            } catch (err) {
                console.error(`⚠️ Erro no registro ${registro.id}:`, err.message);
            }
        }

        await Promise.all(promessas);
        console.log(`✅ ROTINA FINALIZADA! Sistema sincronizado.`);
        console.log('==================================================\n');

    } catch (erro) {
        console.error('❌ Falha crítica na rotina noturna:', erro.message);
    } finally {
        pb.authStore.clear();
    }
}

// PROGRAMAÇÃO: Todos os dias às 03:00 da manhã (Fuso SP/Brasília)
cron.schedule('0 3 * * *', executarRotinaNoturna, {
    scheduled: true,
    timezone: "America/Sao_Paulo" 
});

// Para fins de teste imediato, se rodar 'node robo_noturno.js'
if (require.main === module) {
    executarRotinaNoturna();
}

module.exports = { executarRotinaNoturna };
