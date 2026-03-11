import 'package:flutter/material.dart';
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
import 'package:meire/core/services/pocketbase_service.dart';
import 'package:meire/core/provider/settings_provider.dart';

// Create a global navigator key to allow navigation from anywhere, like auth listeners
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await pocketBaseAuthStore.init(); // Load the token securely before app starts
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

    // Listen to Auth State globally
    ref.listen(pbAuthChangeProvider, (previous, next) {
      if (next.hasValue) {
        final event = next.value;
        if (event != null) {
          if (event.token.isEmpty || event.record == null) {
            // User logged out entirely, throw them to login instantly
            navigatorKey.currentState
                ?.pushNamedAndRemoveUntil('/login', (route) => false);
          } else {
            // Re-authenticated properly, move to hub if we are on login screen
            navigatorKey.currentState
                ?.pushNamedAndRemoveUntil('/hub', (route) => false);
          }
        }
      }
    });

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Meire',
      theme: MeireTheme.lightTheme(settings.isCompact),
      darkTheme: MeireTheme.darkTheme(settings.isCompact),
      themeMode: settings.themeMode,
      home: isAuthenticated ? const HubPage() : const LoginPage(),
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterStepperPage(),
        '/success': (context) => const SuccessPage(),
        '/hub': (context) => const HubPage(),
        '/nfse_form': (context) => const NfseFormPage(),
        '/nfse_success': (context) => const NfseSuccessPage(),
        '/favorite_service_form': (context) => const FavoriteServiceFormPage(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
