import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_client/core/widgets/error_view.dart';

void main() {
  testWidgets('ErrorView affiche le message et le bouton retry',
      (tester) async {
    var retried = false;
    await tester.pumpWidget(
      MaterialApp(
        home: ErrorView(
          message: 'Erreur test',
          onRetry: () => retried = true,
        ),
      ),
    );

    expect(find.text('Erreur test'), findsOneWidget);
    expect(find.text('Réessayer'), findsOneWidget);

    await tester.tap(find.text('Réessayer'));
    await tester.pump();

    expect(retried, true);
  });

  testWidgets("ErrorView sans onRetry n'affiche pas le bouton", (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ErrorView(message: 'Erreur'),
      ),
    );

    expect(find.text('Erreur'), findsOneWidget);
    expect(find.text('Réessayer'), findsNothing);
  });

  testWidgets('ErrorView affiche une icône personnalisée', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ErrorView(message: 'Hors ligne', icon: Icons.wifi_off_outlined),
      ),
    );

    expect(find.byIcon(Icons.wifi_off_outlined), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsNothing);
  });
}
