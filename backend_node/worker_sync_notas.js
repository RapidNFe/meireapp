/**
 * MEIRE CO-PILOTO - SINCRONIZADOR DE NOTAS FANTASMA
 * Este script verifica notas que ficaram presas no status 'PENDENTE'
 * e tenta validar se foram autorizadas ou se devem ser descartadas.
 */
const { query } = require('./database');
const PocketBase = require('pocketbase/cjs');
const config = require('./config');

const pb = new PocketBase(config.pocketbase.url);

async function sincronizarNotas() {
    console.log("🕰️ [CO-PILOTO] Iniciando varredura diária de notas...");

    try {
        // 1. Autentica no PocketBase
        await pb.collection('_superusers').authWithPassword(config.pocketbase.adminEmail, config.pocketbase.adminPassword);

        // 2. Busca notas PENDENTES criadas há mais de 1 hora
        const umaHoraAtras = new Date(Date.now() - 60 * 60 * 1000).toISOString();
        
        // Usamos query SQL direto para busca complexa de data se necessário, ou SDK
        const notasPendentes = await pb.collection('notas_fiscais').getFullList({
            filter: `status = "PENDENTE" && created < "${umaHoraAtras}"`,
        });

        console.log(`🔍 [CO-PILOTO] Encontradas ${notasPendentes.length} notas em limbo.`);

        for (const nota of notasPendentes) {
            console.log(`⚖️ Analisando nota ${nota.id} (DPS: ${nota.numero_notA})...`);
            
            // Aqui entraria a lógica de consulta no SERPRO/ADN para ver se a chave existe
            // Por enquanto, apenas marcamos como ERRO_SISTEMA para não travar o faturamento
            await pb.collection('notas_fiscais').update(nota.id, {
                status: 'ERRO_SISTEMA',
                motivo_rejeicao: 'Nota expirou sem confirmação do governo. Verifique manualmente.'
            });
        }

        console.log("✅ [CO-PILOTO] Varredura concluída.");

    } catch (error) {
        console.error("❌ [CO-PILOTO] Erro na sincronização:", error.message);
    } finally {
        pb.authStore.clear();
    }
}

// Executa imediatamente se rodar o script diretamente
if (require.main === module) {
    sincronizarNotas();
}

module.exports = { sincronizarNotas };
