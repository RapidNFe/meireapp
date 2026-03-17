import 'package:flutter/material.dart';
import 'package:meire/core/ui/theme.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Privacidade e Soberania',
          style: TextStyle(color: MeireTheme.primaryColor, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: MeireTheme.primaryColor),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Icon(Icons.shield_outlined, size: 64, color: MeireTheme.accentColor),
              ),
              const SizedBox(height: 24),
              const Text(
                '🛡️ Política de Privacidade e Soberania de Dados (Meiri App)',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: MeireTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Última atualização: 11 de Março de 2026',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              const SizedBox(height: 32),
              _buildSection(
                'Nossa Filosofia',
                'Bem-vindo à Meiri, a plataforma de inteligência fiscal desenvolvida pela SAID Contabilidade.\n\nNossa arquitetura foi construída sob o princípio do privilégio mínimo: nós não queremos, não precisamos e não comercializamos os seus dados. O nosso ecossistema existe exclusivamente para automatizar o seu faturamento e garantir a sua conformidade tributária com "fricção zero".\n\nPara estarmos em total conformidade com a Lei Geral de Proteção de Dados (LGPD - Lei nº 13.709/2018), detalhamos abaixo, de forma transparente e direta, como a sua operação é blindada em nossos servidores.',
              ),
              _buildSection(
                '1. Os Dados que Movimentamos',
                'Coletamos estritamente o necessário para que o seu dinheiro flua e seus impostos sejam calculados corretamente:\n\n'
                '• Dados Cadastrais: Seu CNPJ, Razão Social, Nome Fantasia e e-mail de acesso.\n'
                '• Dados Operacionais (Tomadores): CNPJ, Razão Social e e-mail dos clientes para os quais você emite nota fiscal (seu CRM Fiscal).\n'
                '• Dados Transacionais: Valores de faturamento, descrições de serviço e códigos CNAE para processamento via SERPRO.',
              ),
              _buildSection(
                '2. O Motor de Processamento',
                'A Meiri atua como uma ponte criptografada (via tecnologia mTLS) entre o seu celular e a Receita Federal/Prefeituras.\n\nO payload das suas notas fiscais é transmitido diretamente para o Integrador Contador (SERPRO), que é o órgão governamental oficial para validação da NFS-e Nacional.\n\nNós não compartilhamos, alugamos ou vendemos sua lista de clientes ou histórico de faturamento para nenhuma ferramenta de marketing ou empresa de terceiros.',
              ),
              _buildSection(
                '3. Onde o seu dado repousa',
                'Seu histórico financeiro e sua carteira de clientes não ficam misturados. Utilizamos uma arquitetura de banco de dados isolada (Multi-Tenant). Isso significa que as suas chaves de acesso garantem que apenas você tem permissão matemática e algorítmica para visualizar as suas notas e os seus clientes.',
              ),
              _buildSection(
                '4. O Seu Poder de Comando (Seus Direitos LGPD)',
                'Você é o soberano da sua operação. Através do aplicativo Meiri, você tem o direito imediato de:\n\n'
                '• Acessar: Visualizar todo o seu histórico financeiro e cadastral em tempo real.\n'
                '• Retificar: Alterar dados incorretos de clientes ou do seu próprio perfil.\n'
                '• O Direito ao Esquecimento: Você pode, a qualquer momento, acessar a aba "Perfil" e acionar o botão "Excluir Minha Conta e Dados". Nossa arquitetura executará uma exclusão em cascata, pulverizando imediatamente seu usuário, suas notas processadas e sua agenda de clientes de nossos servidores. Esta ação é irreversível.',
              ),
              _buildSection(
                '5. Responsabilidade e Atuação',
                'A SAID Contabilidade opera como a Operadora da tecnologia. Você (o usuário titular do CNPJ emissor) atua como o Controlador dos dados dos seus clientes (Tomadores de Serviço). É sua responsabilidade garantir que os dados de terceiros inseridos na plataforma para emissão de notas sejam legítimos e corretos.',
              ),
              const SizedBox(height: 48),
              Center(
                child: Text(
                  'Soberania. Privacidade. Meiri.',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey.shade400,
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: MeireTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
