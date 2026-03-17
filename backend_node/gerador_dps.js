const { create } = require('xmlbuilder2');

/**
 * Função principal que recebe o JSON do Flutter e converte para o XML padrão Sefaz Nacional
 */
function gerarXmlDPS(dados) {
  
  // 1. Montagem do ID da DPS (Regra da Sefaz: DPS + cMun(7) + tpInsc(1) + CNPJ(14) + Serie(5) + nDPS(15))
  const tipoInscricao = '2'; // SEMPRE CNPJ (Tipo 2)
  const numeroDpsFormatado = String(dados.numeroDPS).padStart(15, '0');
  const serieFormatada = String(dados.numeroSerie).padStart(5, '0');

  // CORREÇÃO: Blindagem do Município. Se vier vazio, assume 5201405 (Aparecida de Goiânia - Caso da Ana)
  const cLocEmiTratado = dados.codigoMunicipioEmissor || "5201405"; 
  
  const idDPS = `DPS${cLocEmiTratado}${tipoInscricao}${dados.prestador.cnpj}${serieFormatada}${numeroDpsFormatado}`;

  // 2. MÁQUINA DE LAVAR TEXTOS (Remove Enters e quebras de linha que o Governo odeia)
  const nomeTomadorLimpo = dados.tomador.nome ? dados.tomador.nome.replace(/[\r\n]+/g, " ").trim() : "";
  const descricaoLimpa = dados.servico.descricao ? dados.servico.descricao.replace(/[\r\n]+/g, " ").trim() : "";
  const logradouroLimpo = dados.tomador.endereco.logradouro ? dados.tomador.endereco.logradouro.replace(/[\r\n]+/g, " ").trim() : "Nao Informado";

  // 3. O RELÓGIO SEGURO (Força a hora atual do Brasil UTC-3, independentemente de onde o servidor está)
  const agora = new Date();
  
  // Converte a hora atual para o fuso horário de São Paulo/Brasília (-3 horas ou -180 minutos)
  const offsetBrasilMinutos = -180;
  const dataBrasil = new Date(agora.getTime() + (agora.getTimezoneOffset() + offsetBrasilMinutos) * 60000);
  
  // Atrasa 5 minutos por segurança
  dataBrasil.setMinutes(dataBrasil.getMinutes() - 5);
  
  const pad = n => String(n).padStart(2, '0');
  
  // Formata perfeitamente: YYYY-MM-DDTHH:mm:ss-03:00
  const dhEmiTratada = `${dataBrasil.getFullYear()}-${pad(dataBrasil.getMonth()+1)}-${pad(dataBrasil.getDate())}T${pad(dataBrasil.getHours())}:${pad(dataBrasil.getMinutes())}:${pad(dataBrasil.getSeconds())}-03:00`;
  
  // 1. TRATAMENTO RIGOROSO DA VARIÁVEL:
  // Removemos o fallback de dataBrasil. Agora usamos apenas o que o cliente enviou.
  const dCompetTratada = dados.competencia ? dados.competencia.substring(0, 10) : null;

  // LOG DE AUDITORIA CRÍTICO:
  if (!dCompetTratada) {
      console.error(`❌ [Gerador] ERRO CRÍTICO: Competência não informada pelo cliente!`);
      throw new Error("A data de competência é obrigatória para gerar o XML.");
  }

  console.log(`🖋️ [Gerador] dCompet Final no XML: ${dCompetTratada}`);

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
        dCompet: dCompetTratada,
        tpEmit: '1', 
        cLocEmi: cLocEmiTratado,
        
        prest: {
          CNPJ: dados.prestador.cnpj,
          // ❌ REMOVIDO: O Governo Nacional recusa Inscrição Municipal para MEIs na maioria das cidades
          // ...(dados.prestador.im ? { IM: dados.prestador.im } : {}),
          regTrib: {
            opSimpNac: dados.prestador.opcaoSimplesNacional,
            regEspTrib: dados.prestador.regimeEspecialTributacao
          }
        },
        
        toma: {
          CNPJ: dados.tomador.cnpj.replaceAll(/[^\d]/g, ''),
          xNome: nomeTomadorLimpo,
          end: {
            endNac: {
              cMun: dados.tomador.endereco.municipio,
              CEP: dados.tomador.endereco.cep
            },
            xLgr: logradouroLimpo,
            nro: dados.tomador.endereco.numero || "S/N", 
            ...(dados.tomador.endereco.complemento ? { xCpl: dados.tomador.endereco.complemento } : {}),
            xBairro: dados.tomador.endereco.bairro
          }
        },
        
        serv: {
          locPrest: {
            cLocPrestacao: dados.servico.municipioPrestacao
          },
          cServ: {
            cTribNac: dados.servico.codigoTribNacional,
            xDescServ: descricaoLimpa
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
