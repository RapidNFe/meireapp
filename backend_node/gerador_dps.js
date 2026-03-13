const { create } = require('xmlbuilder2');

/**
 * Função principal que recebe o JSON do Flutter e converte para o XML padrão Sefaz Nacional
 */
function gerarXmlDPS(dados) {
  
  // 1. Montagem do ID da DPS (Regra da Sefaz: DPS + cMun(7) + tpInsc(1) + CNPJ(14) + Serie(5) + nDPS(15))
  const tipoInscricao = dados.prestador.cnpj.length === 14 ? '2' : '1'; 
  const numeroDpsFormatado = String(dados.numeroDPS).padStart(15, '0');
  const serieFormatada = String(dados.numeroSerie).padStart(5, '0');
  const idDPS = `DPS${dados.codigoMunicipioEmissor}${tipoInscricao}${dados.prestador.cnpj}${serieFormatada}${numeroDpsFormatado}`;

  // 2. Data sem milissegundos (Fundamental para evitar E0714 em alguns servidores)
  // Ex: de 2026-03-13T10:54:50.123-03:00 para 2026-03-13T10:54:50-03:00
  const dhEmiTratada = dados.dataHoraEmissao.replace(/\.\d+(?=[+-]|Z|$)/, "");

  // 3. Construindo a Árvore XML com os dados do Flutter
  const objXML = {
    DPS: {
      '@xmlns': 'http://www.sped.fazenda.gov.br/nfse',
      '@versao': '1.01',
      infDPS: {
        '@Id': idDPS,
        tpAmb: dados.ambiente,
        dhEmi: dhEmiTratada,
        verAplic: 'MeireApp1.0', 
        serie: dados.numeroSerie,
        nDPS: dados.numeroDPS,
        dCompet: dados.competencia,
        tpEmit: '1', 
        cLocEmi: dados.codigoMunicipioEmissor,
        
        prest: {
          CNPJ: dados.prestador.cnpj,
          ...(dados.prestador.im ? { IM: dados.prestador.im } : {}),
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
            vServ: parseFloat(dados.servico.valor).toFixed(2)
          },
          trib: {
            tribMun: {
              tribISSQN: '1', 
              tpRetISSQN: '1' 
            },
            totTrib: {
              indTotTrib: '0' 
            }
          }
        }
      }
    }
  };

  // 4. Gerando a string XML final (Bruto, sem espaços)
  const documentoXML = create({ version: '1.0', encoding: 'UTF-8' }, objXML);
  const xmlAssinavel = documentoXML.end({ prettyPrint: false });
  
  return { idDPS, xmlAssinavel };
}

module.exports = { gerarXmlDPS };
