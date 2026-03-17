import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meire/core/ui/theme.dart';
import 'package:meire/core/error/ui/government_error_view.dart';
import 'package:meire/features/history/ui/invoice_history_page.dart';
import 'package:meire/features/nfse/ui/nfse_form_page.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('pt_BR', null);
  });

  group('Golden Tests - Visual Guardrails', () {
    Widget buildTestableWidget(Widget child) {
      return ProviderScope(
        child: MaterialApp(
          // Use standard theme to avoid executing GoogleFonts.interTextTheme()
          // which is statically evaluated inside MeireTheme.lightTheme
          theme: ThemeData.light().copyWith(
            primaryColor: MeireTheme.primaryColor,
            scaffoldBackgroundColor: MeireTheme.backgroundColor,
            colorScheme:
                const ColorScheme.light(primary: MeireTheme.primaryColor),
          ),
          debugShowCheckedModeBanner: false,
          home: Scaffold(body: child),
        ),
      );
    }

    testWidgets('GovernmentErrorView matches golden file',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget(
        GovernmentErrorView(onRetry: () {}),
      ));

      // Wait for rendering but skip infinite animation settlement
      await tester.pump(const Duration(seconds: 1));

      await expectLater(
        find.byType(GovernmentErrorView),
        matchesGoldenFile('goldens/government_error_view.png'),
      );
    });

    testWidgets('InvoiceHistoryPage matches golden file',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget(
        const InvoiceHistoryPage(),
      ));

      await tester.pump(const Duration(seconds: 1));

      await expectLater(
        find.byType(InvoiceHistoryPage),
        matchesGoldenFile('goldens/invoice_history_page.png'),
      );
    });

    testWidgets('NfseFormPage matches golden file',
        (WidgetTester tester) async {
      // Set to an iPhone/Android logical size for consistency
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;

      await tester.pumpWidget(buildTestableWidget(
        const NfseFormPage(),
      ));

      await tester.pump(const Duration(seconds: 1));

      await expectLater(
        find.byType(NfseFormPage),
        matchesGoldenFile('goldens/nfse_form_page.png'),
      );

      // Reset
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    });
  });
}
