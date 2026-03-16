const PocketBase = require('pocketbase/cjs');
require('dotenv').config();

const pb = new PocketBase(process.env.PB_URL || 'http://127.0.0.1:8090');

async function cleanLegacyPdfLinks() {
    try {
        await pb.collection('_superusers').authWithPassword(process.env.PB_ADMIN_EMAIL, process.env.PB_ADMIN_PASSWORD);
        
        console.log("🧹 Iniciando limpeza de links legados de PDF...");
        
        const records = await pb.collection('notas_fiscais').getFullList({
            filter: 'pdf_nota != ""'
        });

        console.log(`🔎 Encontrados ${records.length} registros com pdf_nota preenchido.`);

        for (const record of records) {
            await pb.collection('notas_fiscais').update(record.id, {
                'pdf_nota': null 
            });
            console.log(`✅ Limpo pdf_nota para registro: ${record.id}`);
        }

        console.log("✨ Limpeza 360° concluída!");

    } catch (error) {
        console.error("❌ Erro na limpeza:", error.message);
    }
}

cleanLegacyPdfLinks();
