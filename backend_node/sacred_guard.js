/**
 * 🛡️ ESCUDO MEIRI - O Guarda Sagrado do Emissor
 * Este script garante que o gerador de notas nunca quebre, 
 * independentemente das alterações feitas no sistema.
 */

const { gerarXmlDPS } = require('./gerador_dps');
const { create } = require('xmlbuilder2');

const mockPayload = {
    ambiente: '2',
    numeroDPS: '1',
    numeroSerie: '1',
    codigoMunicipioEmissor: '5201405',
    competencia: '2026-03-17',
    prestador: {
        cnpj: '12345678000199',
        opcaoSimplesNacional: '1',
        regimeEspecialTributacao: '0'
    },
    tomador: {
        cnpj: '00000000000191',
        nome: 'Empresa Teste do Tomador',
        endereco: {
            municipio: '5201405',
            cep: '74000000',
            logradouro: 'Rua de Teste',
            numero: '123',
            bairro: 'Centro'
        }
    },
    servico: {
        descricao: 'Teste de Servico Sagrado',
        municipioPrestacao: '5201405',
        codigoTribNacional: '0101',
        valor: '10.00'
    }
};

function runSacredTests() {
    console.log("🛡️  Iniciando Auditoria do Escudo Meiri...");
    let errors = [];

    try {
        const { idDPS, xmlAssinavel } = gerarXmlDPS(mockPayload);
        
        // TESTE 1: ID DPS (Critico para o Governo)
        if (!idDPS.startsWith("DPS")) errors.push("ERRO CRÍTICO: ID da DPS deve começar com 'DPS'");
        if (!idDPS.includes(mockPayload.prestador.cnpj)) errors.push("ERRO CRÍTICO: ID da DPS deve conter o CNPJ do prestador");

        // TESTE 2: REBRANDING (Nao pode voltar para Meire)
        if (!xmlAssinavel.includes("meiriApp1.0")) errors.push("REBRANDING QUEBRADO: verAplic deve ser 'meiriApp1.0'");

        // TESTE 3: ESTRUTURA XML
        if (!xmlAssinavel.includes("<dCompet>")) errors.push("CAMPO FALTANTE: dCompet é obrigatório");
        if (!xmlAssinavel.includes('xmlns="http://www.sped.fazenda.gov.br/nfse"')) errors.push("NAMESPACE INVÁLIDO: O Governo vai rejeitar");

        // TESTE 4: VALOR (Formato 2 casas decimais)
        if (!xmlAssinavel.includes("<vServ>10.00</vServ>")) errors.push("VALOR INVÁLIDO: O emissor deve garantir 2 casas decimais (10.00)");

        // TESTE 5: SEGURANÇA (Data de Competência sempre presente)
        const xmlSemCompetencia = gerarXmlDPS({ ...mockPayload, competencia: null });
        if (!xmlSemCompetencia.xmlAssinavel.includes("<dCompet>")) {
            errors.push("SEGURANÇA FALHOU: O XML foi gerado sem a tag dCompet!");
        } else {
            console.log("✅ Backup de Competência operando (Data de hoje assumida)");
        }

    } catch (e) {
        errors.push("FALHA TOTAL: O gerador nem rodou. Erro: " + e.message);
    }

    if (errors.length > 0) {
        console.error("\n❌❌❌ ALERTA DE SACRILÉGIO! O EMISSOR FOI VIOLADO ❌❌❌");
        errors.forEach(err => console.error(err));
        process.exit(1);
    } else {
        console.log("\n✅ O EMISSOR ESTÁ SAGRADO E SEGURO. Nenhuma alteração o quebrou.");
        process.exit(0);
    }
}

runSacredTests();
