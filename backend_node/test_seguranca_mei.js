// teste de mesa do motor e das dicas
const payloadSimuladoAppFlutter = {
  // Simulando a construção do Frontend
  "userId": "THIAGO_MEI_ID",
  "payload": {
    "numeroDPS": "12345678",
    "dataHoraEmissao": new Date().toISOString(),
    "competencia": "2026-03-21",
    "codigoMunicipioEmissor": "5208707", // IBGE Garantido pela trava da Conta!
    "tomador": {
      "cnpj": "12345678900",
      "nome": "Cliente Exemplo SA",
      "endereco": {
        "municipio": "5208707",
        "cep": "74820090",
        "logradouro": "Rua X",
        "numero": "1",
        "bairro": "Centro"
      }
    },
    // Aqui vai o objeto consolidado com as opções do "Atalho Rápido"
    "servico": {
      "municipioPrestacao": "5208707",
      "codigoTribNacional": "060101",
      "itemNbs": "126021000",
      "descricao": "Prestação de serviços de CABELEIREIRO.\nDocumento emitido por MEI - Optante pelo SIMEI...\nLei 12.741/2012.", // Descrição automática que não foi digitada!
      "valor": "80500.00" // Um valor altíssimo pra simular a barreira!
    }
  }
};

console.log("=========================================");
console.log("🛡️ INICIANDO TESTE SOBERANO DA EMISSÃO");
console.log("=========================================");
console.log("1. Payload recebido (NFS-e Ready) via Frontend Meiri App:");
console.log(JSON.stringify(payloadSimuladoAppFlutter.payload.servico, null, 2));

console.log("\n2. Executando Trava Analítica de Limite (NODE.JS)...");

const faturamentoAnualAtualizadoBanco = 4500.00; // Simulação de um select do DB
const limiteMEI = 81000.00;

console.log(`[Banco de Dados] Faturamento Atual de THIAGO_MEI: R$ ${faturamentoAnualAtualizadoBanco}`);

const valorNovaNota = parseFloat(payloadSimuladoAppFlutter.payload.servico.valor);
console.log(`[Formulário] Valor da Emissão Recebida: R$ ${valorNovaNota}`);

if ((faturamentoAnualAtualizadoBanco + valorNovaNota) > limiteMEI) {
    console.log(`\n🛑 BARREIRA ATIVADA: Operação Interrompida!`);
    console.error(`Erro: A emissão desta nota fará você ultrapassar o limite anual do MEI (R$ 81.000,00). Emissão bloqueada por segurança fiscal.`);
} else {
    console.log(`\n✅ Aprovado: O limite não foi excedido. Disparando Motor VORTEX Nacional...`);
}

console.log("\n3. Resumo da Estrutura de Proteção Implementada:");
console.log(" - A retenção de ISS vai com 'false' blindado no PocketBase.");
console.log(" - Regime Especial sempre '6' (MEI) nos dados do PocketBase.");
console.log(" - Exigibilidade ISS sempre travada em '1'.");
console.log("=========================================");
