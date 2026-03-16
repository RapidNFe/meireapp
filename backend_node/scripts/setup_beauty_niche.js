const PocketBase = require('pocketbase/cjs');
const config = require('../config');

async function setupBeautyNiche(userId) {
    const pb = new PocketBase(config.pocketbase.url);
    
    try {
        // Autentica como Admin
        await pb.collection('_superusers').authWithPassword(config.pocketbase.adminEmail, config.pocketbase.adminPassword);
        
        console.log(`🌸 [Onboarding] Configurando Nicho de Beleza para Usuário: ${userId}`);

        // 1. Criar o cliente "Salão Parceiro" Padrão (Opcional, mas ajuda no 1-clique)
        // Aqui poderíamos buscar se já existe um cliente com CNPJ genérico ou pedir no onboarding.
        
        // 2. Injetar o Favorito "Comissão Quinzena"
        const favoritoData = {
            "user": userId,
            "apelido": "COMISSÃO SALÃO (QUINZENA)",
            "descricao_padrao": "Nota fiscal referente a serviços de estética e beleza (Salão Parceiro) prestados no período de {QUINZENA_PASSADA}.",
            "valor_base": 1200.00,
            "codigo_nacional": "060101",
            "iss_retido": false,
            "is_nicho_beleza": true
        };

        const record = await pb.collection('servicos_favoritos').create(favoritoData);
        console.log(`✅ Favorito "Comissão Quinzena" injetado com sucesso! ID: ${record.id}`);
        
        return record;
    } catch (e) {
        console.error(`❌ Erro no Onboarding de Beleza:`, e.message);
        throw e;
    }
}

// Se rodar via linha de comando: node scripts/setup_beauty_niche.js <userId>
if (require.main === module) {
    const userId = process.argv[2];
    if (!userId) {
        console.error("Uso: node setup_beauty_niche.js <userId>");
        process.exit(1);
    }
    setupBeautyNiche(userId);
}

module.exports = { setupBeautyNiche };
