// test/features/catalog/horizontal_product_row_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_client/core/widgets/shimmer_skeleton.dart';
import 'package:app_client/features/catalog/models/product.dart';
import 'package:app_client/features/catalog/widgets/horizontal_product_row.dart';

const _products = [
  Product(id: 1, name: 'Margherita', price: 10),
  Product(id: 2, name: 'Regina', price: 12),
];

Future<void> _pump(
  WidgetTester tester,
  AsyncValue<List<Product>> productsAsync, {
  VoidCallback? onSeeAll,
}) {
  return tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: HorizontalProductRow(
            title: 'Pizzas',
            productsAsync: productsAsync,
            onSeeAll: onSeeAll,
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('HorizontalProductRow', () {
    testWidgets('affiche un skeleton pendant le chargement', (tester) async {
      await _pump(tester, const AsyncValue.loading());

      expect(find.byType(ShimmerBlock), findsWidgets);
      expect(find.text('Pizzas'), findsOneWidget);
    });

    testWidgets('affiche les produits en scroll horizontal', (tester) async {
      await _pump(tester, const AsyncValue.data(_products));

      expect(find.text('Margherita'), findsOneWidget);
      expect(find.text('Regina'), findsOneWidget);
      final listView = tester.widget<ListView>(find.byType(ListView));
      expect(listView.scrollDirection, Axis.horizontal);
    });

    testWidgets('se masque silencieusement si la liste est vide',
        (tester) async {
      await _pump(tester, const AsyncValue.data([]));

      expect(find.text('Pizzas'), findsNothing);
    });

    testWidgets("se masque silencieusement en cas d'erreur", (tester) async {
      await _pump(tester, AsyncValue.error('boom', StackTrace.empty));

      expect(find.text('Pizzas'), findsNothing);
    });

    testWidgets('"Voir tout" déclenche le callback', (tester) async {
      var tapped = false;
      await _pump(
        tester,
        const AsyncValue.data(_products),
        onSeeAll: () => tapped = true,
      );

      await tester.tap(find.text('Voir tout'));

      expect(tapped, true);
    });
  });
}
