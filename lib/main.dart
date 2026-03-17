import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:meire/core/ui/theme.dart';
import 'package:meire/features/auth/ui/login_page.dart';
import 'package:meire/features/auth/ui/register_stepper_page.dart';
import 'package:meire/features/auth/ui/success_page.dart';
import 'package:meire/features/hub/ui/dashboard_page.dart';
import 'package:meire/features/nfse/ui/favorite_service_form_page.dart';
import 'package:meire/features/nfse/ui/nfse_form_page.dart';
import 'package:meire/features/nfse/ui/nfse_success_page.dart';
import 'package:meire/features/admin/ui/admin_dashboard_page.dart';
import 'package:meire/features/clients/ui/add_client_page.dart';
import 'package:meire/features/clients/ui/customer_central_page.dart';
import 'package:meire/core/services/pocketbase_service.dart';
import 'package:meire/core/provider/settings_provider.dart';
import 'package:meire/features/shared/ui/privacy_policy_page.dart';
import 'package:meire/features/copiloto/ui/dasn_copiloto_page.dart';
import 'package:meire/features/nfse/ui/pdf_viewer_page.dart';
import 'package:meire/features/landing/ui/landing_page.dart';

// Create a global navigator key to allow navigation from anywhere, like auth listeners
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await pocketBaseAuthStore.init(); // Load the token securely before app starts
  
  if (pb.authStore.isValid) {
    try {
      await pb.collection('users').authRefresh();
    } catch (_) {
      pb.authStore.clear();
    }
  }
  
  await initializeDateFormatting('pt_BR', null);
  runApp(const ProviderScope(child: MeireApp()));
}

class MeireApp extends ConsumerWidget {
  const MeireApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Check settings for theme and compactness
    final settings = ref.watch(settingsProvider);

    // Check if session is valid for auto-login
    final isAuthenticated = ref.watch(pbProvider).authStore.isValid;
    final isAdmin = ref.watch(pbProvider).authStore.record?.getStringValue('email') == 'thiago514@hotmail.com';

    // Listen to Auth State globally
    ref.listen(pbAuthChangeProvider, (previous, next) {
      if (next.hasValue) {
        final event = next.value;
        if (event == null) return;

        final isLoggedOut = event.token.isEmpty || event.record == null;
        
        // Só redirecionamos se houver uma mudança real de status (Login -> Logout ou vice-versa)
        // Caso contrário, deixamos o usuário onde ele está (ex: salvando perfil)
        final wasLoggedOut = previous?.value?.token.isEmpty ?? !isAuthenticated;

        if (isLoggedOut && !wasLoggedOut) {
          navigatorKey.currentState?.pushNamedAndRemoveUntil('/login', (route) => false);
        } else if (!isLoggedOut && wasLoggedOut) {
          final eventIsAdmin = event.record?.getStringValue('email') == 'thiago514@hotmail.com';
          navigatorKey.currentState?.pushNamedAndRemoveUntil(eventIsAdmin ? '/admin_hub' : '/hub', (route) => false);
        }
      }
    });

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Meiri',
      theme: MeireTheme.lightTheme(settings.isCompact),
      darkTheme: MeireTheme.darkTheme(settings.isCompact),
      themeMode: settings.themeMode,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('pt', 'BR'),
      ],
      locale: const Locale('pt', 'BR'),
      home: isAuthenticated ? (isAdmin ? const AdminDashboardPage() : const HubPage()) : const LandingPage(),
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterStepperPage(),
        '/success': (context) => const SuccessPage(),
        '/hub': (context) => const HubPage(),
        '/clientes': (context) => const CustomerCentralPage(),
        '/admin_hub': (context) => const AdminDashboardPage(),
        '/nfse_form': (context) => const NfseFormPage(),
        '/nfse_success': (context) => const NfseSuccessPage(),
        '/favorite_service_form': (context) => const FavoriteServiceFormPage(),
        '/add_client': (context) => const AddClientPage(),
        '/privacy_policy': (context) => const PrivacyPolicyPage(),
        '/dasn_copiloto': (context) => const DasnCopilotoPage(),
        '/pdf_viewer': (context) => const PdfViewerPage(),
        '/landing': (context) => const LandingPage(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
