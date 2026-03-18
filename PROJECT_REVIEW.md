# 🛡️ MEIRE: Revisão Soberana do Projeto v1.0

Este documento serve como a **Bússola de Contexto** do projeto. Ele deve ser lido (ou referenciado) em cada nova tarefa para evitar redundância, perda de créditos e "alucinações" sobre a arquitetura.

---

## 🏗️ 1. Arquitetura do Sistema

O Meire é um ecossistema de gestão e emissão de notas fiscais (NFS-e) construído sobre 3 camadas principais:

### 📱 Camada 1: Frontend (Flutter Web/App)
- **Local:** `lib/`
- **Stack:** Flutter + Riverpod (Gerenciamento de Estado).
- **Filosofia:** *Quiet Luxury UI* (Clean, haptic, transições suaves).
- **Build Otimizado:** `flutter build web --release --web-renderer html --tree-shake-icons`.

### ⚡ Camada 2: Middleware/Backend (Node.js)
- **Local:** `backend_node/`
- **Função:** Integrador mTLS com SERPRO (API Nacional de NFS-e).
- **Pilares de Resiliência:**
  1. **Cofre de Autenticação (`serpro_auth.js`)**: Cache em RAM de tokens SAPI para evitar custos extras e bloqueios.
  2. **Catraca de Fluxo (`catraca_serpro.js`)**: Gerenciamento de fila (Rate Limit) para evitar o erro 429 da Receita.
  3. **Fortaleza de Contingência (`vortex_emissor_nacional.js`)**: Retry automático com backoff exponencial.

### 🗄️ Camada 3: Banco de Dados (PocketBase)
- **Tecnologia:** Go + SQLite.
- **Função:** Persistência de dados, autenticação de usuários e armazenamento de certificados no "Cofre" (Vault).

---

## 📂 2. Mapa de Funcionalidades (Features)

- **`lib/features/nfse/`**: Core do sistema. Formulários de emissão, geração de DPS e consulta de notas.
- **`lib/features/clients/`**: Gestão de tomadores de serviço (CRUD de Clientes).
- **`lib/features/auth/`**: Fluxo de login e segurança biométrica/superusuário.
- **`lib/features/copiloto/`**: Assistente inteligente para suporte tributário.
- **`lib/features/landing/`**: Landing page institucional e conversão.

---

## 📑 3. Fluxo de Emissão Crítico

1. **Input User**: O usuário preenche os dados da nota no Flutter.
2. **Sync PocketBase**: Os dados são salvos localmente no PocketBase.
3. **Trigger Backend**: Chamada para o backend Node.js.
4. **Assinador Soberano**: O XML é gerado (`gerador_dps.js`) e assinado com certificado A1.
5. **Transmissão**: O `vortex` envia para a API Nacional via Serpro.
6. **Retorno**: O PDF é gerado (`danfse_service.js`) e o status é atualizado no PocketBase.

---

## 🛑 4. Regras de Engajamento e Eficiência (Proteção de Créditos)

Para evitar o consumo excessivo de tokens e processos circulares, **todo agente deve seguir estas regras rigorosamente**:

### 🚫 Regra do "Stop & Pivot" (Anti-Loop Infinito)
Se um erro persistir por **3 tentativas de correção sem sucesso**, o agente deve PARAR imediatamente, reportar o que tentou e perguntar por uma abordagem alternativa ou pedir mais logs. **Proibido tentar a 4ª correção adivinhando.**

### 🔍 Diagnóstico Antes da Ação
Antes de editar qualquer arquivo, o agente deve:
1. Ler o arquivo atual.
2. Verificar os logs de erro reais (se disponíveis).
3. Explicar em 2 linhas o que pretende mudar e por quê.

### 📦 Mudanças Atômicas
Evite substituir o arquivo inteiro. Use edições parciais (`replace_file_content` ou `multi_replace_file_content`) para manter o contexto leve.

### 🧠 Memória Curta, Contexto Longo
Não peça para o agente "revisar tudo" a cada passo. Use este arquivo `PROJECT_REVIEW.md` como âncora para economizar tokens de contexto inicial.

---

## 🚩 5. Variáveis de Ambiente e Segurança
- Os certificados e chaves de API estão protegidos no `.env` e no PocketBase Vault.
- **Nunca** exponha a `SERPRO_TOKEN` ou chaves privadas em logs de debug.
- Use sempre o `sacred_guard.js` para validar requisições no backend.

---

## 🎨 6. Histórico de Refatorações Recentes

### 18/03/2026 — Landing Page: Bento Grid + Otimizações `const`

**Objetivo:** Modernizar a seção de funcionalidades com layout Bento Grid e eliminar todos os avisos de performance do linter.

#### ✅ O que foi feito:

**`lib/features/landing/ui/landing_page.dart`**

1. **Nova seção de Funcionalidades (`FeaturesSection`)** substituída por um **Bento Grid** responsivo:
   - Desktop: 2 colunas, cada uma com 3 linhas de cards variados.
   - Mobile: coluna única com os mesmos cards empilhados.
   - Cards criados: `_BentoCardHero` (destaque com gradiente), `_BentoCardCompact` (1/2 largura), `_BentoCardWide` (horizontal largo), `_BentoCardStat` (métricas animadas).
   - Todos os cards têm efeito de hover (`MouseRegion` + `AnimatedContainer` com translação Y).

2. **Otimizações `const` (linter warnings eliminados):**
   - `_BentoDesktop.build` → `return const Row(...)` — toda a árvore estática propagada de uma vez.
   - `_BentoMobile.build` → `return const Column(...)` — idem.
   - `_BentoCardStatState.build` → `child: const Column(...)` — subtree de métricas totalmente constante.
   - `_BentoCardStat` e `_Divider` receberam `const` em seus construtores.

#### 📐 Estrutura do Bento Grid (Desktop):

```
┌─────────────────────┬─────────────────────┐
│  _BentoCardHero     │  _BentoCardCompact  │  _BentoCardCompact │
│  (Emissão de Notas) │  (Alertas DAS)      │  (Gestão Clientes) │
├──────────┬──────────┼─────────────────────┤
│ Compact  │ Compact  │  _BentoCardWide     │
│ (Caixa)  │ (DASN)   │  (Segurança Total)  │
├──────────┴──────────┼─────────────────────┤
│  _BentoCardWide     │  _BentoCardStat     │
│  (Suporte Humano)   │  (Métricas: 10×/99%)│
└─────────────────────┴─────────────────────┘
```

---

### 18/03/2026 — Blindagem Tributária, Gestão de Clientes e Hiper-Performance

**Objetivo:** Garantir emissão fiscal 100% correta através do CNAE do usuário, simplificar a gestão de clientes e reduzir o tempo de deploy/carregamento do site.

#### ✅ O que foi feito:

**1. Blindagem de CNAE (Segurança Fiscal)**
- **Integração BrasilAPI:** O app consome o CNPJ do usuário logado para buscar seus CNAEs oficiais.
- **Provider de Filtro (`lc116PermitidosProvider`):** Cruza o CNAE da empresa com a tabela de correlação no PocketBase (`cnae_correlacao`).
- **Busca Restrita:** O seletor de serviços agora só mostra itens que o CNAE do usuário tem permissão legal para emitir, prevenindo rejeições no Serpro e multas.

**2. Gestão de Clientes "Lux"**
- **`TomadorSelectorLux`:** Novo componente de busca em tempo real no formulário de nota.
- **Cadastro Inteligente:** Integração com BrasilAPI na página de cadastro de clientes (`AddClientPage`). Ao digitar o CNPJ, o Meiri preenche Razão Social, Apelido e Endereço automaticamente.
- **Multi-tenancy:** Trava de segurança no PocketBase (`user = "$userId"`) garante que cada MEI veja apenas seus próprios clientes.

**3. Conformidade com Serpro (Nacional)**
- **Ajuste de Dígitos:** Refatoração do `NotasFiscaisService` para limpar e formatar códigos `cTribNac` (6 dígitos) e `itemNbs` (9 dígitos), removendo pontos e garantindo o padrão exigido pelo Governo Federal.

**4. Hiper-Performance (Infra e Web)**
- **Deploy de 60 Segundos:** Otimização do `ecosystem.config.js` (`watch: false` e limites de RAM) para acelerar o deploy via PM2 e evitar travamentos no servidor EC2/VPS.
- **Loader "Lux" no Web:** Injeção de CSS crítico e animação de carregamento no `index.html`. O usuário vê a logo e o fundo esmeralda instantaneamente enquanto o Flutter carrega em background (Fim da tela branca).
- **Asset Lean:** Compressão da logo principal de 2.5MB para 208KB.

---

*Documento atualizado em: 18/03/2026 (Fase 2 Concluída)*
