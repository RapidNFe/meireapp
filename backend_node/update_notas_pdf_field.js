const PocketBase = require('pocketbase/cjs');
require('dotenv').config();

const pb = new PocketBase(process.env.PB_URL || 'http://127.0.0.1:8090');

async function addPdfField() {
    try {
        await pb.collection('_superusers').authWithPassword(process.env.PB_ADMIN_EMAIL, process.env.PB_ADMIN_PASSWORD);
        
        const collection = await pb.collections.getOne('notas_fiscais');
        
        // Verifica se o campo já existe
        if (collection.fields.find(f => f.name === 'pdf_oficial')) {
            console.log("✅ Campo 'pdf_oficial' já existe.");
            return;
        }

        collection.fields.push({
            name: 'pdf_oficial',
            type: 'file',
            system: false,
            required: false,
            presentable: false,
            unique: false,
            options: {
                maxSelect: 1,
                maxSize: 5242880, // 5MB
                mimeTypes: ['application/pdf'],
                thumbs: [],
                protected: false
            }
        });

        await pb.collections.update(collection.id, collection);
        console.log("✅ Campo 'pdf_oficial' adicionado com sucesso!");

    } catch (error) {
        console.error("❌ Erro ao adicionar campo:", error.message);
    }
}

addPdfField();
