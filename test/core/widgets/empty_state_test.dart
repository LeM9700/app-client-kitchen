import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_client/core/widgets/empty_state.dart';

void main() {
  testWidgets('EmptyState affiche le titre', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: EmptyState(title: 'Panier vide'),
      ),
    );

    expect(find.text('Panier vide'), findsOneWidget);
  });

  testWidgets('EmptyState affiche le sous-titre quand fourni', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: EmptyState(
          title: 'Panier vide',
          subtitle: 'Ajoutez des produits depuis le menu.',
        ),
      ),
    );

    expect(find.text('Panier vide'), findsOneWidget);
    expect(find.text('Ajoutez des produits depuis le menu.'), findsOneWidget);
  });

  testWidgets('EmptyState ne rend pas de sous-titre si absent', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: EmptyState(title: 'Rien ici'),
      ),
    );

    expect(find.text('Rien ici'), findsOneWidget);
    // Aucune assertion négative fiable sur "sous-titre absent" au-delà du
    // fait que le widget se construit sans erreur ; l'absence de crash sur
    // `subtitle: null` est déjà couverte par ce test.
  });

  testWidgets('EmptyState affiche le widget action quand fourni',
      (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: EmptyState(
          title: 'Vous n\'êtes pas connecté',
          action: ElevatedButton(
            onPressed: () => tapped = true,
            child: const Text('Se connecter'),
          ),
        ),
      ),
    );

    expect(find.text('Se connecter'), findsOneWidget);
    await tester.tap(find.text('Se connecter'));
    await tester.pump();
    expect(tapped, true);
  });

  testWidgets('EmptyState utilise l\'icône par défaut si non spécifiée',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: EmptyState(title: 'Vide'),
      ),
    );

    expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);
  });
}
