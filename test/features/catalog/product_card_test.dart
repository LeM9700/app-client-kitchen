import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_client/features/catalog/models/product.dart';
import 'package:app_client/features/catalog/providers/favorites_provider.dart';
import 'package:app_client/features/catalog/widgets/product_card.dart';

const _product = Product(id: 1, name: 'Margherita', price: 10);

Future<ProviderContainer> _pumpCard(WidgetTester tester) async {
  final container = ProviderContainer();
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        home: Scaffold(
          body: SizedBox(height: 240, child: ProductCard(product: _product)),
        ),
      ),
    ),
  );

  return container;
}

void main() {
  group('ProductCard favorite toggle', () {
    testWidgets('affiche un coeur vide par défaut', (tester) async {
      await _pumpCard(tester);

      expect(find.byIcon(Icons.favorite_border), findsOneWidget);
      expect(find.byIcon(Icons.favorite), findsNothing);
    });

    testWidgets('tap sur le coeur bascule le favori sans naviguer',
        (tester) async {
      final container = await _pumpCard(tester);

      await tester.tap(find.byIcon(Icons.favorite_border));
      await tester.pump();

      expect(container.read(favoritesProvider), {1});
      expect(find.byIcon(Icons.favorite), findsOneWidget);
    });

    testWidgets('un second tap retire le favori', (tester) async {
      final container = await _pumpCard(tester);

      await tester.tap(find.byIcon(Icons.favorite_border));
      await tester.pump();
      await tester.tap(find.byIcon(Icons.favorite));
      await tester.pump();

      expect(container.read(favoritesProvider), isEmpty);
    });
  });
}
