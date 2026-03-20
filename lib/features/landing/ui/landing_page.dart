import 'package:flutter/material.dart';
import 'package:meire/features/auth/ui/login_page.dart';
import 'package:flutter_svg/flutter_svg.dart';

// ================= PALETA DE CORES =================
const Color kEmeraldDeep = Color(0xFF013220); // Verde Esmeralda Profundo
const Color kEmeraldMain = Color(0xFF005A3A); // Verde Esmeralda Base
const Color kEmeraldAccent = Color(0xFF50C878); // Verde Esmeralda Brilhante
const Color kIvoryLuxury = Color(0xFFFFFDD0); // Marfim Suave para texto

// Mapeamento das cores para manter compatibilidade com componentes existentes
const Color esmeraldaFundo = kEmeraldDeep;
const Color verdeSecundario = kEmeraldMain;
const Color verdeCard = Color(0xFF003D2A); // Tom luxuoso para os cards
const Color amareloDestaque = kEmeraldAccent;

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _featuresKey = GlobalKey();
  final GlobalKey _pricingKey = GlobalKey();
  final GlobalKey _testimonialsKey = GlobalKey();
  final GlobalKey _faqKey = GlobalKey();

  void _scrollTo(GlobalKey key) {
    final context = key.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(seconds: 1),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kEmeraldDeep, // Fundo escuro luxuoso
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          children: [
            HeaderSection(
              onFeaturesTap: () => _scrollTo(_featuresKey),
              onPricingTap: () => _scrollTo(_pricingKey),
              onTestimonialsTap: () => _scrollTo(_testimonialsKey),
              onFaqTap: () => _scrollTo(_faqKey),
            ),
            _NoBrainerPricingSection(key: _pricingKey), // Seção de preço trazida para o topo (Logo após Hero)
            const DividerSection(),
            const CustoInvisivelSection(), // A Âncora (Avareza/Ira)
            const DividerSection(),
            FeaturesSection(key: _featuresKey), // Bento Grid (Preguiça/Luxúria)
            const DividerSection(),
            TestimonialsSection(key: _testimonialsKey),
            const DividerSection(),
            FAQSection(key: _faqKey),
            const DividerSection(),
            const BottomCTASection(),
            const DividerSection(), // Separador elegante
            const FooterSection(),
          ],
        ),
      ),
    );
  }
}

// ================= SEÇÕES DA PÁGINA =================

class NavBar extends StatelessWidget {
  final VoidCallback? onFeaturesTap;
  final VoidCallback? onPricingTap;
  final VoidCallback? onTestimonialsTap;
  final VoidCallback? onFaqTap;

  const NavBar({
    super.key,
    this.onFeaturesTap,
    this.onPricingTap,
    this.onTestimonialsTap,
    this.onFaqTap,
  });

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 800;

    return Container(
      color: Colors.white,
      width: double.infinity,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 40, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SvgPicture.asset(
              'assets/images/logo.svg',
              height: isMobile ? 32 : 40,
            ),
            if (!isMobile)
              Row(
                children: [
                   HoverNavText('Funcionalidades', color: verdeSecundario, onTap: onFeaturesTap),
                   const SizedBox(width: 32),
                   HoverNavText('Planos', color: verdeSecundario, onTap: onPricingTap),
                   const SizedBox(width: 32),
                   HoverNavText('Depoimentos', color: verdeSecundario, onTap: onTestimonialsTap),
                   const SizedBox(width: 32),
                   HoverNavText('FAQ', color: verdeSecundario, onTap: onFaqTap),
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
                    child: const Text('Login', style: TextStyle(color: verdeSecundario, fontSize: 16)),
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
    final w = MediaQuery.of(context).size.width;
    final bool isMobile = w < 800;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 80),
      child: Column(
        children: [
          // ── Cabeçalho ──────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: verdeCard.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: amareloDestaque.withValues(alpha: 0.3)),
            ),
            child: const Text('✦ FUNCIONALIDADES',
                style: TextStyle(
                    color: amareloDestaque,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5)),
          ),
          const SizedBox(height: 20),
          Text(
            'Por que escolher a Meiri?',
            style: TextStyle(
                color: Colors.white,
                fontSize: isMobile ? 32 : 44,
                fontWeight: FontWeight.w800,
                height: 1.1),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          const Text(
            'Gestão completa, moderna e integrada na palma da sua mão.',
            style: TextStyle(color: Colors.white60, fontSize: 17, height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 64),

          // ── Bento Grid ─────────────────────────────────────────
          isMobile
              ? const _BentoMobile()
              : const _BentoDesktop(),
        ],
      ),
    );
  }
}

// ── Desktop Bento (2 colunas, 3 linhas cada) ──────────────────────────────
class _BentoDesktop extends StatelessWidget {
  const _BentoDesktop();

  @override
  Widget build(BuildContext context) {
    const gap = 20.0;

    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Coluna Esquerda ──────────────────────────────────────
        Expanded(
          child: Column(
            children: [
              // Linha 1 – card grande destaque (Emissão de Notas)
              _BentoCardHero(
                icon: Icons.receipt_long_rounded,
                badge: 'Mais usado',
                title: 'Emissão de Notas',
                desc: 'Emita notas fiscais de serviço em segundos, direto do portal oficial da Receita Federal.',
                accent: amareloDestaque,
              ),
              SizedBox(height: gap),
              // Linha 2 – dois cards lado a lado
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _BentoCardCompact(
                        icon: Icons.bar_chart_rounded,
                        title: 'Fluxo de Caixa',
                        desc: 'Entradas e saídas com relatórios automáticos.',
                        accent: Color(0xFF34D399),
                      ),
                    ),
                    SizedBox(width: gap),
                    Expanded(
                      child: _BentoCardCompact(
                        icon: Icons.description_rounded,
                        title: 'Declaração Anual',
                        desc: 'DASN pronta com um clique.',
                        accent: Color(0xFF60A5FA),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: gap),
              // Linha 3 – card médio horizontal (Suporte)
              _BentoCardWide(
                icon: Icons.headset_mic_rounded,
                title: 'Suporte Humano',
                desc: 'Tire suas dúvidas diretamente com contadores especialistas em MEI. Atendimento real, sem chatbots.',
                accent: Color(0xFFF472B6),
              ),
            ],
          ),
        ),

        SizedBox(width: gap),

        // ── Coluna Direita ───────────────────────────────────────
        Expanded(
          child: Column(
            children: [
              // Linha 1 – dois cards lado a lado
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _BentoCardCompact(
                        icon: Icons.notifications_active_rounded,
                        title: 'Alerta de DAS',
                        desc: 'Lembretes pra você nunca perder o vencimento.',
                        accent: Color(0xFFFBBF24),
                      ),
                    ),
                    SizedBox(width: gap),
                    Expanded(
                      child: _BentoCardCompact(
                        icon: Icons.people_rounded,
                        title: 'Gestão de Clientes',
                        desc: 'Histórico completo de serviços faturados.',
                        accent: Color(0xFFA78BFA),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: gap),
              // Linha 2 – card médio
              _BentoCardWide(
                icon: Icons.lock_rounded,
                title: 'Segurança Total',
                desc: 'Seus dados protegidos com criptografia de ponta a ponta. Acesse de qualquer lugar com total tranquilidade.',
                accent: Color(0xFF34D399),
              ),
              SizedBox(height: gap),
              // Linha 3 – card de métricas / estatísticas
              _BentoCardStat(),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Mobile Bento (coluna única) ───────────────────────────────────────────
class _BentoMobile extends StatelessWidget {
  const _BentoMobile();

  @override
  Widget build(BuildContext context) {
    const gap = 16.0;
    return const Column(
      children: [
        _BentoCardHero(
          icon: Icons.receipt_long_rounded,
          badge: 'Mais usado',
          title: 'Emissão de Notas',
          desc: 'Emita notas fiscais de serviço em segundos, direto do portal oficial da Receita Federal.',
          accent: amareloDestaque,
        ),
        SizedBox(height: gap),
        Row(
          children: [
            Expanded(
              child: _BentoCardCompact(
                icon: Icons.notifications_active_rounded,
                title: 'Alerta de DAS',
                desc: 'Lembretes pra você nunca perder o vencimento.',
                accent: Color(0xFFFBBF24),
              ),
            ),
            SizedBox(width: gap),
            Expanded(
              child: _BentoCardCompact(
                icon: Icons.bar_chart_rounded,
                title: 'Caixa',
                desc: 'Relatórios automáticos.',
                accent: Color(0xFF34D399),
              ),
            ),
          ],
        ),
        SizedBox(height: gap),
        _BentoCardWide(
          icon: Icons.headset_mic_rounded,
          title: 'Suporte Humano',
          desc: 'Contadores especialistas prontos para te ajudar.',
          accent: Color(0xFFF472B6),
        ),
        SizedBox(height: gap),
        Row(
          children: [
            Expanded(
              child: _BentoCardCompact(
                icon: Icons.description_rounded,
                title: 'DASN',
                desc: '1 clique para declarar.',
                accent: Color(0xFF60A5FA),
              ),
            ),
            SizedBox(width: gap),
            Expanded(
              child: _BentoCardCompact(
                icon: Icons.people_rounded,
                title: 'Clientes',
                desc: 'Histórico de serviços.',
                accent: Color(0xFFA78BFA),
              ),
            ),
          ],
        ),
        SizedBox(height: gap),
        _BentoCardStat(),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  BENTO CARD WIDGETS
// ══════════════════════════════════════════════════════════════════

/// Card grande com gradiente, badge e ícone grande
class _BentoCardHero extends StatefulWidget {
  final IconData icon;
  final String badge;
  final String title;
  final String desc;
  final Color accent;

  const _BentoCardHero({
    required this.icon,
    required this.badge,
    required this.title,
    required this.desc,
    required this.accent,
  });

  @override
  State<_BentoCardHero> createState() => _BentoCardHeroState();
}

class _BentoCardHeroState extends State<_BentoCardHero> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, _hovered ? -6 : 0, 0),
        width: double.infinity,
        padding: const EdgeInsets.all(36),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              verdeCard,
              widget.accent.withValues(alpha: _hovered ? 0.20 : 0.08),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: _hovered
                ? widget.accent.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.07),
            width: 1.5,
          ),
          boxShadow: _hovered
              ? [
                  BoxShadow(
                      color: widget.accent.withValues(alpha: 0.18),
                      blurRadius: 30,
                      offset: const Offset(0, 12)),
                ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: widget.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                        color: widget.accent.withValues(alpha: 0.3), width: 1),
                  ),
                  child: Icon(widget.icon, color: widget.accent, size: 32),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: widget.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: widget.accent.withValues(alpha: 0.4), width: 1),
                  ),
                  child: Text(widget.badge,
                      style: TextStyle(
                          color: widget.accent,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5)),
                ),
              ],
            ),
            const SizedBox(height: 28),
            Text(widget.title,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            Text(widget.desc,
                style: const TextStyle(
                    color: Colors.white60, fontSize: 15, height: 1.6)),
          ],
        ),
      ),
    );
  }
}

/// Card compacto (1/2 largura)
class _BentoCardCompact extends StatefulWidget {
  final IconData icon;
  final String title;
  final String desc;
  final Color accent;

  const _BentoCardCompact({
    required this.icon,
    required this.title,
    required this.desc,
    required this.accent,
  });

  @override
  State<_BentoCardCompact> createState() => _BentoCardCompactState();
}

class _BentoCardCompactState extends State<_BentoCardCompact> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, _hovered ? -5 : 0, 0),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: verdeCard,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _hovered
                ? widget.accent.withValues(alpha: 0.45)
                : Colors.white.withValues(alpha: 0.06),
            width: 1.5,
          ),
          boxShadow: _hovered
              ? [
                  BoxShadow(
                      color: widget.accent.withValues(alpha: 0.15),
                      blurRadius: 24,
                      offset: const Offset(0, 8)),
                ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: widget.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(widget.icon, color: widget.accent, size: 24),
            ),
            const SizedBox(height: 20),
            Text(widget.title,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(widget.desc,
                style: const TextStyle(
                    color: Colors.white54, fontSize: 13, height: 1.5)),
          ],
        ),
      ),
    );
  }
}

/// Card horizontal largo
class _BentoCardWide extends StatefulWidget {
  final IconData icon;
  final String title;
  final String desc;
  final Color accent;

  const _BentoCardWide({
    required this.icon,
    required this.title,
    required this.desc,
    required this.accent,
  });

  @override
  State<_BentoCardWide> createState() => _BentoCardWideState();
}

class _BentoCardWideState extends State<_BentoCardWide> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, _hovered ? -4 : 0, 0),
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: verdeCard,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _hovered
                ? widget.accent.withValues(alpha: 0.45)
                : Colors.white.withValues(alpha: 0.06),
            width: 1.5,
          ),
          boxShadow: _hovered
              ? [
                  BoxShadow(
                      color: widget.accent.withValues(alpha: 0.15),
                      blurRadius: 24,
                      offset: const Offset(0, 8)),
                ]
              : [],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: widget.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(widget.icon, color: widget.accent, size: 28),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text(widget.desc,
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 14, height: 1.5)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Card de estatísticas animadas
class _BentoCardStat extends StatefulWidget {
  const _BentoCardStat();

  @override
  State<_BentoCardStat> createState() => _BentoCardStatState();
}

class _BentoCardStatState extends State<_BentoCardStat> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, _hovered ? -4 : 0, 0),
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              verdeCard,
              amareloDestaque.withValues(alpha: _hovered ? 0.18 : 0.07),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _hovered
                ? amareloDestaque.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.06),
            width: 1.5,
          ),
          boxShadow: _hovered
              ? [
                  BoxShadow(
                      color: amareloDestaque.withValues(alpha: 0.15),
                      blurRadius: 24,
                      offset: const Offset(0, 8)),
                ]
              : [],
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Números que impressionam',
                style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5)),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(value: '10×', label: 'mais rápido'),
                _Divider(),
                _StatItem(value: '99%', label: 'satisfação'),
                _Divider(),
                _StatItem(value: '0 multas', label: 'garantido'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                color: amareloDestaque,
                fontSize: 28,
                fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(color: Colors.white54, fontSize: 13)),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(
        height: 40, width: 1, color: Colors.white.withValues(alpha: 0.1));
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
          ? Column(
              children: [
                Text('© ${DateTime.now().year} Meiri Inteligência para MEI',
                    style: const TextStyle(color: Colors.white54, fontSize: 14)),
                const SizedBox(height: 24),
                const Wrap(
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
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('© ${DateTime.now().year} Meiri Inteligência para MEI',
                    style: const TextStyle(color: Colors.white54, fontSize: 14)),
                const Row(
                  children: [
                    HoverNavText('Termos de Uso', isFooter: true),
                    SizedBox(width: 32),
                    HoverNavText('Privacidade', isFooter: true),
                    SizedBox(width: 32),
                    HoverNavText('Ajuda', isFooter: true),
                  ],
                ),
                const Row(
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
  final Color? color;
  final VoidCallback? onTap;
  const HoverNavText(this.text, {super.key, this.isFooter = false, this.color, this.onTap});

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
      child: GestureDetector(
        onTap: widget.onTap,
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
                  : (widget.isFooter ? Colors.white54 : (widget.color ?? Colors.white70)),
              fontWeight: FontWeight.w500,
              fontSize: widget.isFooter ? 14 : 16,
            ),
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
// ==============================================================================
// NOVAS SEÇÕES E COMPONENTES
// ==============================================================================

class HeaderSection extends StatelessWidget {
  final VoidCallback? onFeaturesTap;
  final VoidCallback? onPricingTap;
  final VoidCallback? onTestimonialsTap;
  final VoidCallback? onFaqTap;

  const HeaderSection({
    super.key,
    this.onFeaturesTap,
    this.onPricingTap,
    this.onTestimonialsTap,
    this.onFaqTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        NavBar(
          onFeaturesTap: onFeaturesTap,
          onPricingTap: onPricingTap,
          onTestimonialsTap: onTestimonialsTap,
          onFaqTap: onFaqTap,
        ),
        const HeroSection(),
      ],
    );
  }
}

class DividerSection extends StatelessWidget {
  const DividerSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 100, vertical: 20),
      child: Center(
        child: Container(
          width: 200,
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                kEmeraldAccent.withValues(alpha: 0.3),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class FooterSection extends StatelessWidget {
  const FooterSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Footer(),
        SizedBox(height: 40),
      ],
    );
  }
}

// ------------------------------------------------------------------------------
// NOVA SEÇÃO DE PREÇO
// ------------------------------------------------------------------------------

class _NoBrainerPricingSection extends StatelessWidget {
  const _NoBrainerPricingSection({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 900;

        return Container(
          padding: EdgeInsets.all(isDesktop ? 100 : 20),
          decoration: const BoxDecoration(
            color: kEmeraldDeep,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [kEmeraldDeep, Color(0xFF01291B)],
            ),
          ),
          child: Column(
            children: [
              // Título (Ira/Avareza - Resolvendo a dor por pouco)
              Text(
                "O Fim da Burocracia tem Preço Único e Justo.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: kIvoryLuxury,
                  fontSize: isDesktop ? 48 : 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.5,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 20),
              // Subtítulo (Gula - Ter tudo sem travas)
              const Opacity(
                opacity: 0.8,
                child: Text(
                  "Acesso completo e irrestrito ao seu emissor fiscal. Sem letras miúdas.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: kIvoryLuxury,
                    fontSize: 18,
                    fontWeight: FontWeight.w300,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: 80),

              // O CARD DE PREÇO
              isDesktop ? _buildDesktopCard() : _buildMobileCard(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDesktopCard() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 800),
        child: const IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: 3, child: _PlanDetails()),
              Expanded(flex: 2, child: _PriceAndCallToAction()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileCard() {
    return const Column(
      children: [
        _PlanDetails(isMobile: true),
        _PriceAndCallToAction(isMobile: true),
      ],
    );
  }
}

class _PlanDetails extends StatelessWidget {
  final bool isMobile;
  const _PlanDetails({this.isMobile = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: const Color(0xFF003D2A), // Fundo interno ligeiramente mais claro
        borderRadius: isMobile
            ? const BorderRadius.vertical(top: Radius.circular(24))
            : const BorderRadius.horizontal(left: Radius.circular(24)),
        border: isMobile
            ? const Border(bottom: BorderSide(color: Color(0xFF013B2A), width: 1))
            : const Border(right: BorderSide(color: Color(0xFF013B2A), width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPill("PLANO COMPLETO DESTRAVADO"),
          const SizedBox(height: 16),
          const Text(
            "Você Foca no Dinheiro,\nA Gente no Governo.",
            style: TextStyle(
              color: kIvoryLuxury,
              fontSize: 24,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 32),
          const _BenefitItemSexy(icon: Icons.check_circle_outline, text: "Emissões Ilimitadas no Padrão Nacional"),
          const _BenefitItemSexy(icon: Icons.auto_awesome_outlined, text: "Seu Assistente Pessoal Meiri"),
          const _BenefitItemSexy(icon: Icons.shield_outlined, text: "Proteção Total do seu Certificado"),
          const _BenefitItemSexy(icon: Icons.restore_page_outlined, text: "Sua nota emitida na hora, sem falhas"),
          const _BenefitItemSexy(icon: Icons.palette_outlined, text: "Notas Fiscais Elegantes e Profissionais"),
        ],
      ),
    );
  }

  Widget _buildPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: kEmeraldAccent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kEmeraldAccent.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: kEmeraldAccent,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _BenefitItemSexy extends StatelessWidget {
  final IconData icon;
  final String text;
  const _BenefitItemSexy({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, color: kEmeraldAccent, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: kIvoryLuxury,
                fontSize: 16,
                fontWeight: FontWeight.w400,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceAndCallToAction extends StatelessWidget {
  final bool isMobile;
  const _PriceAndCallToAction({this.isMobile = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: const Color(0xFF003827), // Fundo ligeiramente diferente para o CTA
        borderRadius: isMobile
            ? const BorderRadius.vertical(bottom: Radius.circular(24))
            : const BorderRadius.horizontal(right: Radius.circular(24)),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Opacity(
            opacity: 0.7,
            child: Text(
              "A escolha ideal para você:",
              style: TextStyle(color: kIvoryLuxury, fontSize: 14),
            ),
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                "R\$",
                style: TextStyle(color: kEmeraldAccent, fontSize: 24, fontWeight: FontWeight.w800),
              ),
              SizedBox(width: 4),
              Text(
                "29,90",
                style: TextStyle(
                  color: kEmeraldAccent,
                  fontSize: 64,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -2,
                ),
              ),
            ],
          ),
          Opacity(
            opacity: 0.7,
            child: Text(
              "por mês / plano único",
              style: TextStyle(color: kIvoryLuxury, fontSize: 14),
            ),
          ),
          SizedBox(height: 48),

          _LuxActionButton(),

          SizedBox(height: 16),
          Opacity(
            opacity: 0.6,
            child: Text(
              "Cancele quando quiser.",
              style: TextStyle(color: kIvoryLuxury, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _LuxActionButton extends StatefulWidget {
  const _LuxActionButton();

  @override
  State<_LuxActionButton> createState() => _LuxActionButtonState();
}

class _LuxActionButtonState extends State<_LuxActionButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        transform: Matrix4.identity()..translateByDouble(0, _isHovered ? -4.0 : 0.0, 0.0, 1.0),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
        decoration: BoxDecoration(
          color: _isHovered ? kIvoryLuxury : kEmeraldAccent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: kEmeraldAccent.withValues(alpha: _isHovered ? 0.6 : 0.3),
              blurRadius: _isHovered ? 30 : 10,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: const Center(
          child: Text(
            "ASSINAR AGORA",
            style: TextStyle(
              color: kEmeraldDeep,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
            ),
          ),
        ),
      ),
    );
  }
}
