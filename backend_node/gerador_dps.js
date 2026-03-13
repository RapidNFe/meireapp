const { create } = require('xmlbuilder2');

/**
 * Função principal que recebe o JSON do Flutter e converte para o XML padrão Sefaz Nacional
 */
function gerarXmlDPS(dados) {
  
  // 1. Montagem do ID da DPS (Regra da Sefaz: DPS + cMun(7) + tpInsc(1) + CNPJ(14) + Serie(5) + nDPS(15))
  const tipoInscricao = dados.prestador.cnpj.length === 14 ? '2' : '1'; 
  const numeroDpsFormatado = String(dados.numeroDPS).padStart(15, '0');
  const idDPS = `DPS${dados.codigoMunicipioEmissor}${tipoInscricao}${dados.prestador.cnpj}${dados.numeroSerie}${numeroDpsFormatado}`;

  // 2. Construindo a Árvore XML com os dados do Flutter
  const objXML = {
    DPS: {
      '@xmlns': 'http://www.sped.fazenda.gov.br/nfse',
      '@versao': '1.01',
      infDPS: {
        '@Id': idDPS,
        tpAmb: dados.ambiente,
        dhEmi: dados.dataHoraEmissao,
        verAplic: 'MeireApp1.0', // Sua assinatura no XML!
        serie: dados.numeroSerie,
        nDPS: dados.numeroDPS,
        dCompet: dados.competencia,
        tpEmit: '1', // 1 = Prestador
        cLocEmi: dados.codigoMunicipioEmissor,
        
        prest: {
          CNPJ: dados.prestador.cnpj,
          regTrib: {
            opSimpNac: dados.prestador.opcaoSimplesNacional,
            regEspTrib: dados.prestador.regimeEspecialTributacao
          }
        },
        
        toma: {
          CNPJ: dados.tomador.cnpj,
          xNome: dados.tomador.nome,
          end: {
            endNac: {
              cMun: dados.tomador.endereco.municipio,
              CEP: dados.tomador.endereco.cep
            },
            xLgr: dados.tomador.endereco.logradouro,
            nro: dados.tomador.endereco.numero,
            xCpl: dados.tomador.endereco.complemento,
            xBairro: dados.tomador.endereco.bairro
          }
        },
        
        serv: {
          locPrest: {
            cLocPrestacao: dados.servico.municipioPrestacao
          },
          cServ: {
            cTribNac: dados.servico.codigoTribNacional,
            xDescServ: dados.servico.descricao
          }
        },
        
        valores: {
          vServPrest: {
            vServ: dados.servico.valor
          },
          trib: {
            tribMun: {
              tribISSQN: '1', // 1 = Operação Tributável
              tpRetISSQN: '1' // 1 = Não Retido
            },
            totTrib: {
              indTotTrib: '0' // 0 = Não informado
            }
          }
        }
      }
    }
  };

  // 3. Gerando a string XML final
  const documentoXML = create({ version: '1.0', encoding: 'utf-8' }, objXML);
  const xmlAssinavel = documentoXML.end({ prettyPrint: false });
  
  return { idDPS, xmlAssinavel };
}

// =========================================================================
// TESTE DE MESA: Simulando o JSON limpo chegando do Flutter (Meire App)
// =========================================================================
const payloadFlutter = {
  ambiente: "1", // 1=Produção, 2=Homologação (Produção Restrita)
  dataHoraEmissao: "2026-03-13T10:54:50-03:00",
  competencia: "2026-02-28",
  numeroSerie: "70000",
  numeroDPS: "1",
  codigoMunicipioEmissor: "5208707", // Goiânia
  
  prestador: {
    cnpj: "65354705000152", // CNPJ Cascia
    opcaoSimplesNacional: "2", 
    regimeEspecialTributacao: "0" 
  },
  
  tomador: {
    cnpj: "23061036000180", // CNPJ Debora
    nome: "DEBORA CORTES UNIPESSOAL LTDA",
    endereco: {
      municipio: "5208707",
      cep: "74820090",
      logradouro: "AV SEGUNDA RADIAL",
      numero: "1307",
      complemento: "QUADRA145 LOTE 06",
      bairro: "SETOR PEDRO LUDOVICO"
    }
  },
  
  servico: {
    municipioPrestacao: "5208707",
    codigoTribNacional: "060101",
    descricao: "nota fiscal profissional parceiro referente ao mês de Fevereiro de 2026",
    valor: "7889.70"
  }
};

// Executando
const { idDPS, xmlAssinavel } = gerarXmlDPS(payloadFlutter);

console.log("🎯 ID da Nota Gerado:", idDPS);
console.log("\n📦 XML Pronto para ser Assinado pelo 'assinador_soberano.js':\n");
console.log(xmlAssinavel);

// Exportando para ser usado no seu fluxo principal
module.exports = { gerarXmlDPS };
