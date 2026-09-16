import 'package:app_client/features/legal/screens/legal_document_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Widget wrap(Widget child, {double textScaleFactor = 1}) {
    return MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScaleFactor)),
        child: child,
      ),
    );
  }

  testWidgets('affiche le document confidentialité', (tester) async {
    await tester.pumpWidget(
      wrap(
        const LegalDocumentScreen(type: LegalDocumentType.privacy),
        textScaleFactor: 1.3,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Confidentialité'), findsWidgets);
    expect(find.text('1. Données traitées'), findsOneWidget);
    expect(
      find.text(
        'Contenu provisoire à valider juridiquement avant publication.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('affiche les CGU sans créer un second système légal',
      (tester) async {
    await tester.pumpWidget(
      wrap(const LegalDocumentScreen(type: LegalDocumentType.cgu)),
    );
    await tester.pumpAndSettle();

    expect(find.text('CGU'), findsWidgets);
    expect(find.text('1. Accès au service'), findsOneWidget);
    expect(find.text('Politique de confidentialité'), findsNothing);
  });
}
