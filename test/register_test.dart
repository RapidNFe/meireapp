import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meire/main.dart';

void main() {
  testWidgets('Full flow to register test', (WidgetTester tester) async {
    // Definir tamanho inicial para testar renderização web desktop
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    
    await tester.pumpWidget(const ProviderScope(child: MeireApp()));
    await tester.pumpAndSettle();

    final finder = find.text('Criar conta MEI');
    expect(finder, findsWidgets);
    
    // Tap the 'Criar conta MEI' TextButton
    await tester.tap(finder.last);
    await tester.pumpAndSettle();
    
    // Check if Stepper exists
    expect(find.byType(Stepper), findsOneWidget);
    
    // Reset view
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });
}
