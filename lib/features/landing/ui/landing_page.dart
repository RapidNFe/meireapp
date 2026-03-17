import 'package:flutter/material.dart';
import 'package:meire/features/auth/ui/login_page.dart';

// ================= PALETA DE CORES =================
const Color esmeraldaFundo = Color(0xFF022C22);
const Color verdeSecundario = Color(0xFF064E3B);
const Color verdeCard = Color(0xFF065F46);
const Color amareloDestaque = Color(0xFFFFB800);

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: esmeraldaFundo,
      body: SingleChildScrollView(
        child: Column(
          children: [
            const NavBar(),
            const HeroSection(),
            Container(
              color: verdeSecundario,
              padding: const EdgeInsets.symmetric(vertical: 80),
              child: const CustoInvisivelSection(),
            ),
            Container(
              color: esmeraldaFundo,
              padding: const EdgeInsets.symmetric(vertical: 80),
              child: const FeaturesSection(),
            ),
            Container(
              color: verdeSecundario,
              padding: const EdgeInsets.symmetric(vertical: 80),
              child: const TestimonialsSection(),
            ),
            Container(
              color: esmeraldaFundo,
              padding: const EdgeInsets.symmetric(vertical: 80),
              child: const PricingSection(),
            ),
            Container(
              color: verdeSecundario,
              padding: const EdgeInsets.symmetric(vertical: 80),
              child: const FAQSection(),
            ),
            Container(
              color: esmeraldaFundo,
              padding: const EdgeInsets.symmetric(vertical: 80),
              child: const BottomCTASection(),
            ),
            const Footer(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// ================= SEÇÕES DA PÁGINA =================

class NavBar extends StatelessWidget {
  const NavBar({super.key});

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 800;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 40, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Meiri',
            style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2),
          ),
          if (!isMobile)
            const Row(
              children: [
                HoverNavText('Funcionalidades'),
                SizedBox(width: 32),
                HoverNavText('Planos'),
                SizedBox(width: 32),
                HoverNavText('Depoimentos'),
                SizedBox(width: 32),
                HoverNavText('FAQ'),
              ],
            ),
          Row(
            children: [
              if (!isMobile)
                TextButton(
                  onPressed: () {
                    Navigator.push(
                        context, MaterialPageRoute(builder: (context) => const LoginPage()));
                  },
                  child: const Text('Login', style: TextStyle(color: amareloDestaque, fontSize: 16)),
                ),
              if (!isMobile) const SizedBox(width: 16),
              HoverButton(
                text: 'Assinar Agora',
                onPressed: () {
                  Navigator.push(
                      context, MaterialPageRoute(builder: (context) => const LoginPage()));
                },
              ),
            ],
          )
        ],
      ),
    );
  }
}

class HeroSection extends StatelessWidget {
  const HeroSection({super.key});

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 800;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 40, vertical: isMobile ? 40 : 80),
      child: Flex(
        direction: isMobile ? Axis.vertical : Axis.horizontal,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: isMobile ? 0 : 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: verdeCard.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: amareloDestaque.withValues(alpha: 0.3)),
                  ),
                  child: const Text('⭐ INTELIGÊNCIA PARA MEI',
                      style: TextStyle(
                          color: amareloDestaque,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1)),
                ),
                const SizedBox(height: 24),
                Text(
                  'Inteligência real\npara o seu MEI',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: isMobile ? 40 : 56,
                      fontWeight: FontWeight.w800,
                      height: 1.1),
                ),
                const SizedBox(height: 24),
                Text(
                  'Transforme sua burocracia em crescimento com gestão premium. O braço inteligente do MEI chegou para revolucionar seu negócio com automação e clareza.',
                  style: TextStyle(color: Colors.white70, fontSize: isMobile ? 16 : 18, height: 1.5),
                ),
                const SizedBox(height: 40),
                Wrap(
                  spacing: 20,
                  runSpacing: 20,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    HoverButton(
                      text: 'Começar Agora',
                      showArrow: true,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                      onPressed: () {
                        Navigator.push(
                            context, MaterialPageRoute(builder: (context) => const LoginPage()));
                      },
                    ),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Acesso imediato',
                            style: TextStyle(
                                color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        Text('Pagamento rápido e seguro',
                            style: TextStyle(color: Colors.white54, fontSize: 12)),
                      ],
                    )
                  ],
                )
              ],
            ),
          ),
          if (isMobile) const SizedBox(height: 60),
          Expanded(
            flex: isMobile ? 0 : 1,
            child: AnimatedHoverCard(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  constraints: BoxConstraints(maxHeight: isMobile ? 300 : 500),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: verdeCard,
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 30,
                          offset: const Offset(0, 15))
                    ],
                  ),
                  child: Image.asset(
                    'assets/images/dashboard.png',
                    fit: BoxFit.contain, // Garante que a imagem não seja cortada
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CustoInvisivelSection extends StatelessWidget {
  const CustoInvisivelSection({super.key});

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 800;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 40),
      child: Wrap(
        spacing: 60,
        runSpacing: 40,
        alignment: WrapAlignment.spaceBetween,
        children: [
          SizedBox(
            width: isMobile ? double.infinity : 450,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('O RISCO REAL',
                    style: TextStyle(
                        color: amareloDestaque,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: 1.5)),
                const SizedBox(height: 16),
                Text(
                  'O Custo Invisível da\nBurocracia Manual',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: isMobile ? 32 : 40,
                      fontWeight: FontWeight.bold,
                      height: 1.2),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Não deixe que papelada e prazos impeçam o seu negócio de decolar. Multas, DAS atrasado e falta de controle financeiro custam caro para o pequeno empreendedor.',
                  style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.6),
                ),
              ],
            ),
          ),
          SizedBox(
            width: isMobile ? double.infinity : 400,
            child: const Column(
              children: [
                AnimatedHoverCard(
                  child: InfoCard(
                    icon: Icons.warning_amber_rounded,
                    title: 'Zero Multas',
                    description:
                        'Evite multas de atraso do DAS automaticamente com alertas preventivos.',
                  ),
                ),
                SizedBox(height: 24),
                AnimatedHoverCard(
                  child: InfoCard(
                    icon: Icons.access_time,
                    title: 'Tempo Recuperado',
                    description:
                        'Recupere até 10 horas semanais gastas com burocracia desnecessária.',
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class FeaturesSection extends StatelessWidget {
  const FeaturesSection({super.key});

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 800;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 40),
      child: Column(
        children: [
          Text(
            'Por que escolher a Meiri?',
            style: TextStyle(
                color: Colors.white,
                fontSize: isMobile ? 32 : 40,
                fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'Gestão completa, moderna e integrada na palma da sua mão.',
            style: TextStyle(color: Colors.white70, fontSize: 18),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 60),
          const Wrap(
            spacing: 24,
            runSpacing: 24,
            alignment: WrapAlignment.center,
            children: [
              AnimatedHoverCard(
                child: FeatureCard(
                    icon: Icons.receipt_long,
                    title: 'Emissão de Notas',
                    desc: 'Emita notas fiscais de serviço em segundos, direto para a prefeitura.'),
              ),
              AnimatedHoverCard(
                child: FeatureCard(
                    icon: Icons.notifications_active,
                    title: 'Alertas de DAS',
                    desc:
                        'Lembretes inteligentes via WhatsApp para você nunca mais esquecer de pagar.'),
              ),
              AnimatedHoverCard(
                child: FeatureCard(
                    icon: Icons.bar_chart,
                    title: 'Fluxo de Caixa',
                    desc: 'Visão clara de entradas e saídas com relatórios de performance financeira.'),
              ),
              AnimatedHoverCard(
                child: FeatureCard(
                    icon: Icons.description,
                    title: 'Declaração Anual',
                    desc: 'DASN pronta com um clique. Nós organizamos os seus dados fiscais.'),
              ),
              AnimatedHoverCard(
                child: FeatureCard(
                    icon: Icons.headset_mic,
                    title: 'Suporte Humano',
                    desc: 'Tire suas dúvidas diretamente com contadores especialistas em MEI.'),
              ),
              AnimatedHoverCard(
                child: FeatureCard(
                    icon: Icons.people,
                    title: 'Gestão de Clientes',
                    desc: 'Cadastre seus clientes e tenha o histórico completo de serviços faturados.'),
              ),
            ],
          )
        ],
      ),
    );
  }
}

class TestimonialsSection extends StatelessWidget {
  const TestimonialsSection({super.key});

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 800;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 40),
      child: Column(
        children: [
          Text(
            'O que dizem os MEIs',
            style: TextStyle(
                color: Colors.white,
                fontSize: isMobile ? 32 : 40,
                fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 60),
          const Wrap(
            spacing: 32,
            runSpacing: 32,
            alignment: WrapAlignment.center,
            children: [
              AnimatedHoverCard(
                child: TestimonialCard(
                  quote:
                      '"A Meiri mudou minha forma de trabalhar. Não perco mais tempo com site da prefeitura."',
                  name: 'Ana Silva',
                  role: 'Designer Freelance',
                ),
              ),
              AnimatedHoverCard(
                child: TestimonialCard(
                  quote:
                      '"O suporte é incrível e humanizado. Responderam com clareza em poucos minutos."',
                  name: 'Marcos Oliveira',
                  role: 'Consultor de Vendas',
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}

class PricingSection extends StatefulWidget {
  const PricingSection({super.key});

  @override
  State<PricingSection> createState() => _PricingSectionState();
}

class _PricingSectionState extends State<PricingSection> {
  bool isAnnual = true;

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 800;

    const double baseMensal = 27.90;
    const double completoMensal = 67.90;
    const double baseAnualMes = baseMensal * 0.8;
    const double completoAnualMes = completoMensal * 0.8;
    const double baseAnualTotal = baseAnualMes * 12;
    const double completoAnualTotal = completoAnualMes * 12;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 40),
      child: Column(
        children: [
          Text(
            'Escolha o plano ideal',
            style: TextStyle(
                color: Colors.white,
                fontSize: isMobile ? 32 : 40,
                fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'Sem taxas escondidas. Cancele quando quiser.',
            style: TextStyle(color: Colors.white70, fontSize: 18),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: verdeCard,
              borderRadius: BorderRadius.circular(40),
              border: Border.all(color: verdeSecundario, width: 2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () => setState(() => isAnnual = false),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    decoration: BoxDecoration(
                      color: !isAnnual ? esmeraldaFundo : Colors.transparent,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: !isAnnual
                          ? [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 8)]
                          : [],
                    ),
                    child: Text('Mensal',
                        style: TextStyle(
                            color: !isAnnual ? Colors.white : Colors.white54,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => isAnnual = true),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    decoration: BoxDecoration(
                      color: isAnnual ? esmeraldaFundo : Colors.transparent,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: isAnnual
                          ? [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 8)]
                          : [],
                    ),
                    child: Row(
                      children: [
                        Text('Anual',
                            style: TextStyle(
                                color: isAnnual ? Colors.white : Colors.white54,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                              color: amareloDestaque, borderRadius: BorderRadius.circular(12)),
                          child: const Text('-20%',
                              style: TextStyle(
                                  color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 60),
          Wrap(
            spacing: 32,
            runSpacing: 32,
            alignment: WrapAlignment.center,
            children: [
              AnimatedHoverCard(
                child: PricingCard(
                  title: 'Plano Base',
                  price: isAnnual
                      ? baseAnualMes.toStringAsFixed(2).replaceAll('.', ',')
                      : baseMensal.toStringAsFixed(2).replaceAll('.', ','),
                  billingText: isAnnual
                      ? 'cobrado R\$ ${baseAnualTotal.toStringAsFixed(2).replaceAll('.', ',')} por ano'
                      : 'cobrado mensalmente',
                  features: const [
                    'Até 10 Notas Fiscais por mês',
                    'Alertas de DAS via E-mail',
                    'Controle financeiro básico',
                    'Suporte via e-mail (até 48h)',
                  ],
                  isHighlighted: false,
                ),
              ),
              AnimatedHoverCard(
                scaleAmount: 1.05, // Destaca um pouco mais no hover
                child: PricingCard(
                  title: 'Plano Completo',
                  price: isAnnual
                      ? completoAnualMes.toStringAsFixed(2).replaceAll('.', ',')
                      : completoMensal.toStringAsFixed(2).replaceAll('.', ','),
                  billingText: isAnnual
                      ? 'cobrado R\$ ${completoAnualTotal.toStringAsFixed(2).replaceAll('.', ',')} por ano'
                      : 'cobrado mensalmente',
                  features: const [
                    'Emissão de Notas Ilimitada',
                    'Alertas de DAS via WhatsApp',
                    'Relatórios automáticos de Caixa',
                    'Declaração Anual (DASN) em 1 clique',
                    'Suporte prioritário via Chat',
                  ],
                  isHighlighted: true,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}

class FAQSection extends StatelessWidget {
  const FAQSection({super.key});

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 800;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 40),
      child: Column(
        children: [
          Text(
            'Perguntas Frequentes',
            style: TextStyle(
                color: Colors.white,
                fontSize: isMobile ? 32 : 40,
                fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: const Column(
              children: [
                FaqTile(
                  title: 'Preciso ter um contador para usar a Meiri?',
                  answer:
                      'Não! A Meiri foi desenhada para automatizar a burocracia para que você mesmo consiga gerenciar seu CNPJ com facilidade. Além disso, no Plano Completo, você tem acesso ao nosso suporte via chat com especialistas para tirar dúvidas.',
                ),
                SizedBox(height: 16),
                FaqTile(
                  title: 'Como funciona o alerta do DAS?',
                  answer:
                      'Nós monitoramos a situação do seu CNPJ e enviamos lembretes inteligentes antes do vencimento (via e-mail no plano base, ou WhatsApp no completo), já com o código Pix para pagamento. Você nunca mais vai pagar juros por esquecimento.',
                ),
                SizedBox(height: 16),
                FaqTile(
                  title: 'A Meiri emite nota fiscal para a minha cidade?',
                  answer:
                      'Sim! Nosso sistema é integrado com o padrão nacional (NFS-e) e com a maioria das prefeituras do Brasil. Caso sua cidade use um sistema muito específico, nosso suporte te ajuda na configuração inicial.',
                ),
                SizedBox(height: 16),
                FaqTile(
                  title: 'Posso cancelar minha assinatura quando quiser?',
                  answer:
                      'Sim, sem burocracia. Não exigimos tempo mínimo de fidelidade nem cobramos multas de cancelamento. Você tem total liberdade para cancelar a qualquer momento direto pelo seu painel.',
                ),
                SizedBox(height: 16),
                FaqTile(
                  title: 'O que acontece se eu estourar o limite de faturamento do MEI?',
                  answer:
                      'A Meiri monitora o seu fluxo de caixa e te avisa preventivamente caso você esteja se aproximando do teto anual do MEI. Se precisar desenquadrar e virar uma ME (Microempresa), nosso time te orienta sobre os próximos passos.',
                ),
                SizedBox(height: 16),
                FaqTile(
                  title: 'Quais são as formas de pagamento disponíveis?',
                  answer:
                      'Você pode assinar a Meiri pagando via Pix, Boleto ou Cartão de Crédito (com aprovação imediata e liberação instantânea do sistema).',
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class BottomCTASection extends StatelessWidget {
  const BottomCTASection({super.key});

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 800;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 40),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(isMobile ? 40 : 80),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [amareloDestaque, Color(0xFFE5A600)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
                color: amareloDestaque.withValues(alpha: 0.2),
                blurRadius: 30,
                offset: const Offset(0, 10))
          ],
        ),
        child: Column(
          children: [
            Text(
              'Sua empresa merece\ncrescer com inteligência',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.black,
                  fontSize: isMobile ? 32 : 48,
                  fontWeight: FontWeight.w900,
                  height: 1.1),
            ),
            const SizedBox(height: 24),
            Text(
              'Junte-se a milhares de MEIs que simplificaram sua gestão.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black87, fontSize: isMobile ? 16 : 20),
            ),
            const SizedBox(height: 48),
            Wrap(
              spacing: 20,
              runSpacing: 20,
              alignment: WrapAlignment.center,
              children: [
                HoverButton(
                  text: 'Começar Agora',
                  isPrimary: false, // Fundo escuro para contrastar no amarelo
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
                  onPressed: () {
                    Navigator.push(
                        context, MaterialPageRoute(builder: (context) => const LoginPage()));
                  },
                ),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black,
                    side: const BorderSide(color: Colors.black, width: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {},
                  child: const Text('Falar com Consultor',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class Footer extends StatelessWidget {
  const Footer({super.key});

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 800;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 40, vertical: 20),
      child: isMobile
          ? const Column(
              children: [
                Text('© 2024 Meiri Inteligência para MEI',
                    style: TextStyle(color: Colors.white54, fontSize: 14)),
                SizedBox(height: 24),
                Wrap(
                  spacing: 24,
                  runSpacing: 16,
                  alignment: WrapAlignment.center,
                  children: [
                    HoverNavText('Termos de Uso', isFooter: true),
                    HoverNavText('Privacidade', isFooter: true),
                    HoverNavText('Ajuda', isFooter: true),
                  ],
                ),
              ],
            )
          : const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('© 2024 Meiri Inteligência para MEI',
                    style: TextStyle(color: Colors.white54, fontSize: 14)),
                Row(
                  children: [
                    HoverNavText('Termos de Uso', isFooter: true),
                    SizedBox(width: 32),
                    HoverNavText('Privacidade', isFooter: true),
                    SizedBox(width: 32),
                    HoverNavText('Ajuda', isFooter: true),
                  ],
                ),
                Row(
                  children: [
                    Icon(Icons.share, color: Colors.white54, size: 20),
                    SizedBox(width: 24),
                    Icon(Icons.email, color: Colors.white54, size: 20),
                  ],
                )
              ],
            ),
    );
  }
}

// ================= WIDGETS ANIMADOS E REUTILIZÁVEIS =================

class HoverNavText extends StatefulWidget {
  final String text;
  final bool isFooter;
  const HoverNavText(this.text, {super.key, this.isFooter = false});

  @override
  State<HoverNavText> createState() => _HoverNavTextState();
}

class _HoverNavTextState extends State<HoverNavText> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isHovered ? amareloDestaque : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          widget.text,
          style: TextStyle(
            color: isHovered
                ? amareloDestaque
                : (widget.isFooter ? Colors.white54 : Colors.white70),
            fontWeight: FontWeight.w500,
            fontSize: widget.isFooter ? 14 : 16,
          ),
        ),
      ),
    );
  }
}

class HoverButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final bool showArrow;
  final bool isPrimary;
  final EdgeInsets padding;

  const HoverButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.showArrow = false,
    this.isPrimary = true,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
  });

  @override
  State<HoverButton> createState() => _HoverButtonState();
}

class _HoverButtonState extends State<HoverButton> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.translationValues(0.0, isHovered ? -3.0 : 0.0, 0.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.isPrimary ? amareloDestaque : esmeraldaFundo,
            foregroundColor: widget.isPrimary ? Colors.black : Colors.white,
            padding: widget.padding,
            elevation: isHovered ? 8 : 0,
            shadowColor: widget.isPrimary ? amareloDestaque.withValues(alpha: 0.5) : Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: widget.onPressed,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.text,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              if (widget.showArrow) ...[
                const SizedBox(width: 8),
                AnimatedSlide(
                  offset: isHovered ? const Offset(0.2, 0) : Offset.zero,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(Icons.arrow_forward, size: 20),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}

class AnimatedHoverCard extends StatefulWidget {
  final Widget child;
  final double scaleAmount;

  const AnimatedHoverCard({super.key, required this.child, this.scaleAmount = 1.02});

  @override
  State<AnimatedHoverCard> createState() => _AnimatedHoverCardState();
}

class _AnimatedHoverCardState extends State<AnimatedHoverCard> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        transform: Matrix4.diagonal3Values(
            isHovered ? widget.scaleAmount : 1.0,
            isHovered ? widget.scaleAmount : 1.0,
            1.0),
        decoration: BoxDecoration(
          boxShadow: isHovered
              ? [
                  BoxShadow(
                      color: verdeCard.withValues(alpha: 0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 10))
                ]
              : [],
          borderRadius: BorderRadius.circular(24),
        ),
        child: widget.child,
      ),
    );
  }
}

class InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const InfoCard({super.key, required this.icon, required this.title, required this.description});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: verdeCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration:
                BoxDecoration(color: esmeraldaFundo, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: amareloDestaque, size: 24),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style:
                        const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 12),
                Text(description,
                    style: const TextStyle(color: Colors.white70, fontSize: 15, height: 1.5)),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;

  const FeatureCard({super.key, required this.icon, required this.title, required this.desc});

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 800;

    return Container(
      width: isMobile ? double.infinity : 340,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: verdeCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration:
                BoxDecoration(color: esmeraldaFundo, borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, color: amareloDestaque, size: 32),
          ),
          const SizedBox(height: 24),
          Text(title,
              style:
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22)),
          const SizedBox(height: 16),
          Text(desc, style: const TextStyle(color: Colors.white70, height: 1.6, fontSize: 15)),
        ],
      ),
    );
  }
}

class TestimonialCard extends StatelessWidget {
  final String quote;
  final String name;
  final String role;

  const TestimonialCard(
      {super.key, required this.quote, required this.name, required this.role});

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 800;

    return Container(
      width: isMobile ? double.infinity : 480,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: verdeCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
              children: List.generate(
                  5, (index) => const Icon(Icons.star, color: amareloDestaque, size: 20))),
          const SizedBox(height: 24),
          Text(quote,
              style: const TextStyle(
                  color: Colors.white,
                  fontStyle: FontStyle.italic,
                  fontSize: 18,
                  height: 1.6)),
          const SizedBox(height: 32),
          Row(
            children: [
              const CircleAvatar(
                radius: 24,
                backgroundColor: esmeraldaFundo,
                child: Icon(Icons.person, color: amareloDestaque),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style:
                          const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(role, style: const TextStyle(color: Colors.white54, fontSize: 14)),
                ],
              )
            ],
          )
        ],
      ),
    );
  }
}

class PricingCard extends StatelessWidget {
  final String title;
  final String price;
  final String billingText;
  final List<String> features;
  final bool isHighlighted;

  const PricingCard({
    super.key,
    required this.title,
    required this.price,
    required this.billingText,
    required this.features,
    required this.isHighlighted,
  });

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 800;

    return Container(
      width: isMobile ? double.infinity : 360,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: isHighlighted ? verdeSecundario : verdeCard,
        borderRadius: BorderRadius.circular(32),
        border: isHighlighted
            ? Border.all(color: amareloDestaque, width: 2)
            : Border.all(color: Colors.white.withValues(alpha: 0.05), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isHighlighted)
            Container(
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration:
                  BoxDecoration(color: amareloDestaque, borderRadius: BorderRadius.circular(20)),
              child: const Text('RECOMENDADO',
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1)),
            ),
          Text(title,
              style:
                  const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('R\$ ',
                  style:
                      TextStyle(color: Colors.white70, fontSize: 20, fontWeight: FontWeight.bold)),
              Text(price,
                  style:
                      const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w900, height: 1)),
              const Text(' /mês', style: TextStyle(color: Colors.white70, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 8),
          Text(billingText, style: const TextStyle(color: Colors.white54, fontSize: 14)),
          const SizedBox(height: 32),
          const Divider(color: Colors.white24),
          const SizedBox(height: 32),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: features
                .map((feature) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle,
                              color: isHighlighted ? amareloDestaque : Colors.white54, size: 24),
                          const SizedBox(width: 16),
                          Expanded(
                              child: Text(feature,
                                  style: const TextStyle(color: Colors.white70, fontSize: 15))),
                        ],
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: HoverButton(
              text: 'Assinar $title',
              isPrimary: isHighlighted,
              onPressed: () {},
            ),
          )
        ],
      ),
    );
  }
}

// Widget atualizado para receber a \"answer\" (resposta)
class FaqTile extends StatelessWidget {
  final String title;
  final String answer; // Nova variável para a resposta

  const FaqTile({super.key, required this.title, required this.answer});

  @override
  Widget build(BuildContext context) {
    // Usando as cores da paleta que definimos antes
    const Color verdeCard = Color(0xFF065F46);
    const Color amareloDestaque = Color(0xFFFFB800);

    return Container(
      decoration: BoxDecoration(
        color: verdeCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: ExpansionTile(
        title: Text(title,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
        iconColor: amareloDestaque,
        collapsedIconColor: Colors.white54,
        shape: const Border(), // Remove as linhas padrão do Flutter ao expandir
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 24.0, right: 24.0, bottom: 24.0, top: 8.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                answer, // Mostra a resposta passada lá em cima
                style: const TextStyle(color: Colors.white70, fontSize: 15, height: 1.6),
              ),
            ),
          )
        ],
      ),
    );
  }
}
