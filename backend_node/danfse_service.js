const axios = require('axios');

/**
 * Busca o PDF do DANFSe no servidor do Governo (Sefin Nacional)
 * @param {string} chaveAcesso - A chave de 50 dígitos gerada na emissão
 * @param {string|number} ambiente - 1 para Oficial (Produção), 2 para Fake (Produção Restrita)
 * @param {object} agenteMtls - O túnel seguro (httpsAgent) gerado pelo seu Cofre
 * @returns {Promise<Buffer>} - O buffer binário do PDF
 */
async function baixarDanfsePDF(chaveAcesso, ambiente, agenteMtls) {
    // 1. A Chave dos Trilhos (O Interruptor de Ambiente)
    const isOficial = String(ambiente) === '1';
    
    const baseUrl = isOficial 
        ? 'https://adn.nfse.gov.br' // MODO OFICIAL 🚀
        : 'https://adn.producaorestrita.nfse.gov.br'; // MODO FAKE 🧪

    const urlDoPdf = `${baseUrl}/danfse/${chaveAcesso}`;

    console.log(`📡 [ADN - ${isOficial ? 'OFICIAL' : 'FAKE'}] Buscando PDF da chave: ${chaveAcesso}`);

    try {
        // 2. O Disparo de Busca
        const resposta = await axios.get(urlDoPdf, {
            httpsAgent: agenteMtls, // O seu passaporte AES-256
            responseType: 'arraybuffer', // ⚠️ CRÍTICO: Se tirar isso, o Node transforma o PDF em texto e corrompe o arquivo!
            headers: {
                'Accept': 'application/pdf'
            }
        });

        console.log(`✅ [ADN] PDF capturado! Tamanho: ${resposta.data.byteLength} bytes`);
        return resposta.data; // Retorna o Buffer bruto do PDF

    } catch (erro) {
        // 3. O Radar de Anomalias (Mapeando os retornos do Governo)
        if (erro.response) {
            const status = erro.response.status;
            
            if (status === 404) {
                throw new Error("ERRO_404: DANFSe não encontrado. O governo ainda está processando a nota ou a chave não existe.");
            } else if (status === 400) {
                throw new Error("ERRO_400: Requisição mal formatada (Chave de acesso pode estar no padrão errado).");
            } else if (status >= 500) {
                throw new Error(`ERRO_500: Instabilidade no servidor do Governo Nacional. Status: ${status}`);
            }
        }
        
        throw new Error(`Falha de comunicação com a malha da Receita: ${erro.message}`);
    }
}

module.exports = { baixarDanfsePDF };
