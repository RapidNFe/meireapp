import 'package:flutter/material.dart';
import 'package:meire/features/auth/ui/login_page.dart';

// ================= LANDING PAGE PRINCIPAL =================

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF0C2219),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _NavBar(),
            _HeroSection(),
            Divider(color: Colors.transparent, height: 60),
            _CustoInvisivelSection(),
            Divider(color: Colors.transparent, height: 60),
            _FeaturesSection(),
            Divider(color: Colors.transparent, height: 60),
            _TestimonialsSection(),
            Divider(color: Colors.transparent, height: 60),
            _PricingSection(),
            Divider(color: Colors.transparent, height: 60),
            _FAQSection(),
            Divider(color: Colors.transparent, height: 60),
            _BottomCTASection(),
            Divider(color: Colors.transparent, height: 60),
            _Footer(),
            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// ================= SEÇÕES DA PÁGINA =================

class _NavBar extends StatelessWidget {
  const _NavBar();

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 800;

    return Padding(
      padding:
          EdgeInsets.symmetric(horizontal: isMobile ? 20 : 40, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Meiri',
            style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold),
          ),
          if (!isMobile)
            const Row(
              children: [
                _NavText('Funcionalidades'),
                SizedBox(width: 20),
                _NavText('Planos'),
                SizedBox(width: 20),
                _NavText('Depoimentos'),
                SizedBox(width: 20),
                _NavText('FAQ'),
              ],
            ),
          Row(
            children: [
              if (!isMobile)
                TextButton(
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const LoginPage()));
                  },
                  child: const Text('Login',
                      style: TextStyle(color: Color(0xFFFFB800))),
                ),
              if (!isMobile) const SizedBox(width: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFB800),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const LoginPage()));
                },
                child: const Text('Assinar Agora',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          )
        ],
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection();

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 800;

    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 20 : 40, vertical: isMobile ? 20 : 40),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E3A2F),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('⭐ INTELIGÊNCIA PARA MEI',
                      style: TextStyle(
                          color: Color(0xFFFFB800),
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 20),
                Text(
                  'Inteligência real\npara o seu MEI',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: isMobile ? 36 : 48,
                      fontWeight: FontWeight.bold,
                      height: 1.1),
                ),
                const SizedBox(height: 20),
                Text(
                  'Transforme sua burocracia em crescimento com gestão premium. O braço inteligente do MEI chegou para revolucionar seu negócio com automação e clareza.',
                  style: TextStyle(
                      color: Colors.white70, fontSize: isMobile ? 14 : 16),
                ),
                const SizedBox(height: 30),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFB800),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 18),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const LoginPage()));
                      },
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Começar Agora',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward, size: 18),
                        ],
                      ),
                    ),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Acesso imediato',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold)),
                        Text('Pagamento rápido e seguro',
                            style: TextStyle(
                                color: Colors.white54, fontSize: 10)),
                      ],
                    )
                  ],
                )
              ],
            ),
          ),
          if (isMobile) const SizedBox(height: 40),
          Expanded(
            flex: isMobile ? 0 : 1,
            child: Container(
              height: isMobile ? 200 : 300,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF6A8E82),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Text('Dashboard Image',
                    style: TextStyle(color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CustoInvisivelSection extends StatelessWidget {
  const _CustoInvisivelSection();

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 800;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 40),
      child: Wrap(
        spacing: 40,
        runSpacing: 40,
        alignment: WrapAlignment.spaceBetween,
        children: [
          SizedBox(
            width: isMobile ? double.infinity : 400,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('O RISCO REAL',
                    style: TextStyle(
                        color: Color(0xFFFFB800),
                        fontWeight: FontWeight.bold,
                        fontSize: 12)),
                const SizedBox(height: 10),
                Text(
                  'O Custo Invisível da\nBurocracia Manual',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: isMobile ? 28 : 32,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Não deixe que papelada e prazos impeçam o seu negócio de decolar. Multas, DAS atrasado e falta de controle financeiro custam caro para o pequeno empreendedor.',
                  style: TextStyle(color: Colors.white70, height: 1.5),
                ),
              ],
            ),
          ),
          SizedBox(
            width: isMobile ? double.infinity : 400,
            child: const Column(
              children: [
                _InfoCard(
                  icon: Icons.warning_amber_rounded,
                  title: 'Zero Multas',
                  description:
                      'Evite multas de atraso do DAS automaticamente com alertas preventivos.',
                ),
                SizedBox(height: 20),
                _InfoCard(
                  icon: Icons.access_time,
                  title: 'Tempo Recuperado',
                  description:
                      'Recupere até 10 horas semanais gastas com burocracia desnecessária.',
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _FeaturesSection extends StatelessWidget {
  const _FeaturesSection();

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
                fontSize: isMobile ? 28 : 32,
                fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          const Text(
            'Gestão completa, moderna e integrada na palma da sua mão.',
            style: TextStyle(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          const Wrap(
            spacing: 20,
            runSpacing: 20,
            alignment: WrapAlignment.center,
            children: [
              _FeatureCard(
                  icon: Icons.receipt_long,
                  title: 'Emissão de Notas',
                  desc:
                      'Emita notas fiscais de serviço em segundos, direto para a prefeitura.'),
              _FeatureCard(
                  icon: Icons.notifications_active,
                  title: 'Alertas de DAS',
                  desc:
                      'Lembretes inteligentes via WhatsApp para você nunca mais esquecer de pagar.'),
              _FeatureCard(
                  icon: Icons.bar_chart,
                  title: 'Fluxo de Caixa',
                  desc:
                      'Visão clara de entradas e saídas com relatórios de performance financeira.'),
              _FeatureCard(
                  icon: Icons.description,
                  title: 'Declaração Anual',
                  desc:
                      'DASN pronta com um clique. Nós organizamos os seus dados fiscais.'),
              _FeatureCard(
                  icon: Icons.headset_mic,
                  title: 'Suporte Humano',
                  desc:
                      'Tire suas dúvidas diretamente com contadores especialistas em MEI.'),
              _FeatureCard(
                  icon: Icons.people,
                  title: 'Gestão de Clientes',
                  desc:
                      'Cadastre seus clientes e tenha o histórico completo de serviços prestados e faturados.'),
            ],
          )
        ],
      ),
    );
  }
}

class _TestimonialsSection extends StatelessWidget {
  const _TestimonialsSection();

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
                fontSize: isMobile ? 28 : 32,
                fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          const Wrap(
            spacing: 20,
            runSpacing: 20,
            alignment: WrapAlignment.center,
            children: [
              _TestimonialCard(
                quote:
                    '"A Meiri mudou minha forma de trabalhar. Não perco mais tempo com site da prefeitura."',
                name: 'Ana Silva',
                role: 'Designer Freelance',
              ),
              _TestimonialCard(
                quote:
                    '"O suporte é incrível e humanizado. Responderam com clareza em poucos minutos."',
                name: 'Marcos Oliveira',
                role: 'Consultor de Vendas',
              ),
            ],
          )
        ],
      ),
    );
  }
}

class _PricingSection extends StatefulWidget {
  const _PricingSection();

  @override
  State<_PricingSection> createState() => _PricingSectionState();
}

class _PricingSectionState extends State<_PricingSection> {
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
            'Escolha o plano ideal para o seu MEI',
            style: TextStyle(
                color: Colors.white,
                fontSize: isMobile ? 28 : 32,
                fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          const Text(
            'Sem taxas escondidas. Cancele quando quiser.',
            style: TextStyle(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFF163226),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () => setState(() => isAnnual = false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: !isAnnual
                          ? const Color(0xFF1E3A2F)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(26),
                    ),
                    child: Text('Mensal',
                        style: TextStyle(
                            color:
                                !isAnnual ? Colors.white : Colors.white54,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => isAnnual = true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: isAnnual
                          ? const Color(0xFF1E3A2F)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(26),
                    ),
                    child: Row(
                      children: [
                        Text('Anual',
                            style: TextStyle(
                                color: isAnnual
                                    ? Colors.white
                                    : Colors.white54,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFB800),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text('-20%',
                              style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold)),
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          Wrap(
            spacing: 24,
            runSpacing: 24,
            alignment: WrapAlignment.center,
            children: [
              _PricingCard(
                title: 'Plano Base',
                price: isAnnual
                    ? baseAnualMes
                        .toStringAsFixed(2)
                        .replaceAll('.', ',')
                    : baseMensal
                        .toStringAsFixed(2)
                        .replaceAll('.', ','),
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
              _PricingCard(
                title: 'Plano Completo',
                price: isAnnual
                    ? completoAnualMes
                        .toStringAsFixed(2)
                        .replaceAll('.', ',')
                    : completoMensal
                        .toStringAsFixed(2)
                        .replaceAll('.', ','),
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
            ],
          )
        ],
      ),
    );
  }
}

class _FAQSection extends StatelessWidget {
  const _FAQSection();

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
                fontSize: isMobile ? 28 : 32,
                fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: const Column(
              children: [
                _FaqTile(
                    title: 'É seguro colocar meus dados na plataforma?'),
                SizedBox(height: 10),
                _FaqTile(
                    title:
                        'Quais são as formas de pagamento disponíveis?'),
                SizedBox(height: 10),
                _FaqTile(
                    title:
                        'A Meiri emite nota fiscal para todas as cidades?'),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _BottomCTASection extends StatelessWidget {
  const _BottomCTASection();

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 800;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 40),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(isMobile ? 30 : 60),
        decoration: BoxDecoration(
          color: const Color(0xFFFFB800),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            Text(
              'Sua empresa merece\ncrescer com inteligência',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.black,
                  fontSize: isMobile ? 28 : 36,
                  fontWeight: FontWeight.bold,
                  height: 1.1),
            ),
            const SizedBox(height: 20),
            Text(
              'Junte-se a mais de 50.000 MEIs que simplificaram sua gestão.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.black87, fontSize: isMobile ? 14 : 16),
            ),
            const SizedBox(height: 40),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 20),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const LoginPage()));
                  },
                  child: const Text('Começar Agora',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black,
                    side: const BorderSide(color: Colors.black),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 20),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {},
                  child: const Text('Falar com Consultor',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 800;

    if (isMobile) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            Text('© 2024 Meiri Inteligência para MEI',
                style: TextStyle(color: Colors.white54, fontSize: 12)),
            SizedBox(height: 20),
            Wrap(
              spacing: 20,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                Text('Termos de Uso',
                    style:
                        TextStyle(color: Colors.white54, fontSize: 12)),
                Text('Privacidade',
                    style:
                        TextStyle(color: Colors.white54, fontSize: 12)),
                Text('Ajuda',
                    style:
                        TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.share, color: Colors.white54, size: 20),
                SizedBox(width: 20),
                Icon(Icons.email, color: Colors.white54, size: 20),
              ],
            )
          ],
        ),
      );
    }

    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('© 2024 Meiri Inteligência para MEI',
              style: TextStyle(color: Colors.white54, fontSize: 12)),
          Row(
            children: [
              Text('Termos de Uso',
                  style: TextStyle(color: Colors.white54, fontSize: 12)),
              SizedBox(width: 20),
              Text('Privacidade',
                  style: TextStyle(color: Colors.white54, fontSize: 12)),
              SizedBox(width: 20),
              Text('Ajuda',
                  style: TextStyle(color: Colors.white54, fontSize: 12)),
            ],
          ),
          Row(
            children: [
              Icon(Icons.share, color: Colors.white54, size: 16),
              SizedBox(width: 16),
              Icon(Icons.email, color: Colors.white54, size: 16),
            ],
          )
        ],
      ),
    );
  }
}

// ================= WIDGETS REUTILIZÁVEIS =================

class _NavText extends StatelessWidget {
  final String text;
  const _NavText(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(
            color: Colors.white70, fontWeight: FontWeight.w500));
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _InfoCard(
      {required this.icon, required this.title, required this.description});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF163226),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: const Color(0xFF1E3A2F),
                borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: const Color(0xFFFFB800), size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
                const SizedBox(height: 8),
                Text(description,
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 14)),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;

  const _FeatureCard(
      {required this.icon, required this.title, required this.desc});

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 800;

    return Container(
      width: isMobile ? double.infinity : 320,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF163226),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFFFFB800), size: 32),
          const SizedBox(height: 20),
          Text(title,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20)),
          const SizedBox(height: 12),
          Text(desc,
              style:
                  const TextStyle(color: Colors.white70, height: 1.5)),
        ],
      ),
    );
  }
}

class _TestimonialCard extends StatelessWidget {
  final String quote;
  final String name;
  final String role;

  const _TestimonialCard(
      {required this.quote, required this.name, required this.role});

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 800;

    return Container(
      width: isMobile ? double.infinity : 480,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF163226),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(
                5,
                (index) => const Icon(Icons.star,
                    color: Color(0xFFFFB800), size: 16)),
          ),
          const SizedBox(height: 20),
          Text(quote,
              style: const TextStyle(
                  color: Colors.white,
                  fontStyle: FontStyle.italic,
                  fontSize: 16,
                  height: 1.5)),
          const SizedBox(height: 30),
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xFF1E3A2F),
                child: Icon(Icons.person, color: Color(0xFFFFB800)),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold)),
                  Text(role,
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 12)),
                ],
              )
            ],
          )
        ],
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  final String title;

  const _FaqTile({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF163226),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ExpansionTile(
        title: Text(title,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w500)),
        iconColor: const Color(0xFFFFB800),
        collapsedIconColor: Colors.white54,
        shape: const Border(),
        children: const [
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Aqui vai a resposta detalhada para a pergunta.',
              style: TextStyle(color: Colors.white70),
            ),
          )
        ],
      ),
    );
  }
}

class _PricingCard extends StatelessWidget {
  final String title;
  final String price;
  final String billingText;
  final List<String> features;
  final bool isHighlighted;

  const _PricingCard({
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
      width: isMobile ? double.infinity : 340,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isHighlighted
            ? const Color(0xFF1E3A2F)
            : const Color(0xFF163226),
        borderRadius: BorderRadius.circular(24),
        border: isHighlighted
            ? Border.all(color: const Color(0xFFFFB800), width: 2)
            : Border.all(color: Colors.transparent, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isHighlighted)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFB800),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('RECOMENDADO',
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
            ),
          Text(title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('R\$ ',
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
              Text(price,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      height: 1)),
              const Text(' /mês',
                  style:
                      TextStyle(color: Colors.white70, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 8),
          Text(billingText,
              style: const TextStyle(
                  color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 24),
          const Divider(color: Colors.white24),
          const SizedBox(height: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: features
                .map((feature) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle,
                              color: isHighlighted
                                  ? const Color(0xFFFFB800)
                                  : const Color(0xFF6A8E82),
                              size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(feature,
                                style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14)),
                          )
                        ],
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isHighlighted
                    ? const Color(0xFFFFB800)
                    : const Color(0xFF2C4A3E),
                foregroundColor:
                    isHighlighted ? Colors.black : Colors.white,
                padding:
                    const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const LoginPage()));
              },
              child: Text('Assinar $title',
                  style:
                      const TextStyle(fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }
}
