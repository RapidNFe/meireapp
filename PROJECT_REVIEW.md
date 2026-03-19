# 🛡️ MEIRI: BÚSSOLA DE CONTEXTO & REVISÃO ESTRATÉGICA

**Códinome:** Meiri - A Assistente Inteligente Soberana (v2.1 - SOBERANIA EDITION)
**Data da Última Atualização:** 19/03/2026
**Status do Deploy:** Pronto para Produção (Arquitetura Flexível & Blindada)

---

## 🏛️ 1. SCHEMA ÚNICO & SOBERANO: "A UNIFICAÇÃO" (v2.1)
Migramos toda a inteligência de lançamentos para uma collection única e flexível no PocketBase, eliminando a fragmentação de dados:

- **Collection `servicos`**: O coração do app. Consolida lançamentos de canais distintos (Salão vs. Direto) em uma estrutura padronizada.
- **Campos Estratégicos**: Implementamos `modalidade_fluxo`, `status_faturamento` (aberto/faturado), `id_agrupador` e `comissao_aplicada`.
- **Lógica de Agrupamento**: O `id_agrupador` dinâmico permite que o Meiri some 15 dias de trabalho em uma única nota fiscal final, sem perder a rastreabilidade de cada serviço.

---

## 🦅 2. DASHBOARD DE SOBERANIA (BENTO GRID PREMIUM)
Elevamos o nível visual e funcional da aba **Vendas** para passar autoridade e clareza financeira:

- **ResumoFaturamentoCard**: Um widget de elite que utiliza o **Ouro Meiri (#CC8B00)** para destacar a "Sua Parte Soberana".
- **Bento Grid de Fechamento**: Separação visual clara entre *Total Bruto* (entrada), *Cota-Parte* (retenção em vermelho suave) e *Lucro Real* (net profit).
- **Floating Action Button (FAB) Dinâmico**: O botão "FECHAR FATURAMENTO 🚀" aparece apenas quando há saldo pendente, agindo como um gatilho de recompensa e organização.

---

## ⚡ 3. FLEXIBLE LAUNCH: "TROCA DE CHAVE"
O Quick Launch Card evoluiu para lidar com a dualidade do MEI moderno:

- **Canais de Venda**: O usuário pode alternar entre **SALÃO** (onde o Meiri aplica a comissão acordada) e **DIRETO** (onde o sistema trava a comissão em 100% automaticamente).
- **Cálculo em Tempo Real**: O app calcula a cota-parte instantaneamente no momento do lançamento, alimentando o dashboard sem atrasos.

---

## 🚀 4. MOTOR DE CONSOLIDAÇÃO: "FATURAMENTO BATCH"
Implementamos o `FaturamentoService` para automatizar o encerramento de ciclos produtivos:

- **Fechamento em Massa**: Com um único clique, o Meiri marca todos os serviços abertos do período selecionado como `faturado`.
- **Integridade de Fila**: Evita bitributação e garante que o saldo acumulado seja transformado em NF-e com precisão cirúrgica.
- **Haptic Context**: Feedback tátil pesado ao consolidar faturamentos, gerando uma sensação física de "missão cumprida".

---

## 🎯 5. PRÓXIMOS PASSOS (A PRÓXIMA FRONTEIRA)
1. **Integração BrasilAPI**: No TomadorSelector, para busca automática de CNPJs de salões.
2. **Histórico de Relatórios**: Persistir uma cópia de cada extrato PDF gerado no PocketBase vinculado ao ciclo faturado.
3. **Filtro Temporal Avançado**: Seletor de data para visualização de ciclos passados diretamente no Bento Grid.

---

## 🦅 6. BLINDAGEM POR CNAE & PERFIL ADAPTATIVO
Inteligência que separa o Meiri de soluções genéricas:

- **Automação no Cadastro**: Consulta CNAE via BrasilAPI e classificação automática (*Estética/Beleza* vs. *Serviços Gerais*).
- **Interface Camaleão**: O seletor de Salão no Quick Launch e o card de Cota-Parte se ocultam automaticamente para perfis que não pertencem ao nicho de beleza, mantendo o app limpo e focado.
- **Configuração no Perfil**: Seção dedicada de "Salão Parceiro" integrada ao `ProfilePage` para gestão de CNPJ e comissão padrão do parceiro principal.

---

*Assinado: Antigravity - Seu Par de Programação de Alta Performance.* 🦅🌑
