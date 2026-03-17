1. Visão Geral do ProdutoO Assistente MEI (Meire) é uma plataforma integrada para simplificar a vida do microempreendedor brasileiro, eliminando burocracias, prazos confusos e riscos fiscais. O foco da V1.0 é a centralização de obrigações, emissão de notas e controle rigoroso de faturamento.
2. Stack Tecnológica (Sovereign Stack)
Frontend (Foco Inicial): Flutter (WebApp e Mobile via Antigravity).

Backend de Automação: Node.js + Puppeteer (Robôs para e-CAC e Emissor Nacional).

Banco de Dados & Auth: PocketBase (Hospedagem própria).

Infraestrutura Alvo: Oracle Cloud (Instância Ampere A1 - 24GB RAM - Always Free).

Comunicação: Notificações 100% In-App via Firebase Cloud Messaging (FCM).
3. Fluxo de Cadastro e Onboarding (V1.0)O processo de cadastro é projetado para ser seguro e automatizado, utilizando autenticação via gov.br:Coleta Inicial: Nome Completo, Telefone, E-mail e Senha gov.br.Validação e-CAC (Robô 1): O usuário insere o código de acesso gerado no app Gov.br; o robô extrai Nome da Mãe, Título de Eleitor e Recibos de IRPF.Criptografia: Os dados sensíveis são armazenados de forma oculta e protegida no banco de dados.Ativação NFS-e (Robô 2): O robô utiliza os dados minerados para criar o acesso no Sistema de Emissão de NFS-e da Receita Federal.Confirmação: O usuário insere o código recebido por e-mail para validar o primeiro acesso por Login/Senha no emissor nacional.
4. Funcionalidades Detalhadas (V1.0)📊 Business Hub (Interface Principal)Painel de Vencimentos: Exibição de prazos com contagem regressiva para pagamento do DAS.Emissão Rápida de NFS-e: Botão para gerar notas fiscais de serviço em poucos cliques.Gráfico de Faturamento: Visualização mensal acumulada para monitoramento de receita.Alertas de Limite: Notificações visuais quando o faturamento se aproxima do limite anual legal.⚙️ Gestão Fiscal e TributáriaEmissão de DAS: Geração rápida do boleto mensal diretamente pelo app.Controle de Receita: Armazenamento dos valores de cada NFS-e emitida para cálculo automático de faturamento.Domicílio Tributário (DTE-SN): Acesso centralizado para receber comunicações oficiais da Receita Federal.Regularização: Ferramentas para alteração de dados e correção de pendências cadastrais.
5. Arquitetura de Dados (PocketBase Schema)
Collection users: Cadastro básico (Nome, e-mail, telefone, status de ativação).

Collection invoices: Metadados das notas (Valor bruto, data de emissão, número da nota).

Collection tax_payments: Controle de DAS (Mês de referência, valor, data de vencimento, status de pagamento).

Collection fiscal_vault: Dados sensíveis ocultos (Nome da mãe, Título de eleitor, Recibos IRPF, Tokens de acesso).
6. Regras de Negócio e SegurançaComunicação: Proibido o disparo de e-mails para notificações; todos os alertas de vencimentos e prazos são estritamente In-App.Segurança: Uso de criptografia de dados para proteger informações fiscais e autenticação integrada ao gov.br.Soberania Técnica: O Flutter deve permanecer leve, delegando o processamento pesado de automação ao backend isolado.

