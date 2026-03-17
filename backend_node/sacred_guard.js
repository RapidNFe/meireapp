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

        // TESTE 2: VERSÃO DO APLICATIVO
        if (!xmlAssinavel.includes("MeireApp1.0")) errors.push("ERRO DE VERSÃO: verAplic deve ser 'MeireApp1.0'");

        // TESTE 3: ESTRUTURA XML
        if (!xmlAssinavel.includes("<dCompet>")) errors.push("CAMPO FALTANTE: dCompet é obrigatório");
        if (!xmlAssinavel.includes('xmlns="http://www.sped.fazenda.gov.br/nfse"')) errors.push("NAMESPACE INVÁLIDO: O Governo vai rejeitar");

        // TESTE 4: VALOR (Formato 2 casas decimais)
        if (!xmlAssinavel.includes("<vServ>10.00</vServ>")) errors.push("VALOR INVÁLIDO: O emissor deve garantir 2 casas decimais (10.00)");

        // TESTE 5: EXCLUSIVIDADE CNPJ (Não pode existir tag CPF)
        if (xmlAssinavel.includes("<CPF>")) errors.push("VIOLAÇÃO DE SEGURANÇA: Tag <CPF> encontrada no XML. O sistema deve ser 100% CNPJ.");
        if (!xmlAssinavel.includes("<CNPJ>")) errors.push("ERRO ESTRUTURAL: Tag <CNPJ> não encontrada.");

        // TESTE 6: BLINDAGEM DE COMPETÊNCIA (Deve explodir se for nula)
        try {
            gerarXmlDPS({ ...mockPayload, competencia: null });
            errors.push("SEGURANÇA FALHOU: O gerador aceitou competência NULL sem reclamar!");
        } catch (e) {
            if (e.message.includes("obrigatória")) {
                console.log("✅ Blindagem de Competência operando: Erro lançado corretamente para NULL.");
            } else {
                errors.push("ERRO DE BLINDAGEM: O erro lançado para competência NULL foi inesperado: " + e.message);
            }
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
