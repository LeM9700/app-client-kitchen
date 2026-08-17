import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_client/features/catalog/models/product.dart';
import 'package:app_client/features/catalog/providers/favorites_provider.dart';
import 'package:app_client/features/catalog/widgets/product_card.dart';
import 'package:app_client/features/cart/providers/cart_provider.dart';

const _product = Product(id: 1, name: 'Margherita', price: 10);
const _simpleProduct = Product(id: 1, name: 'Margherita', price: 10);
const _productWithVariant = Product(
  id: 2,
  name: 'Regina',
  price: 12,
  variants: [ProductVariant(id: 1, name: 'Grande', priceDelta: 3)],
);

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

Future<ProviderContainer> _pumpCardFor(
  WidgetTester tester,
  Product product,
) async {
  final container = ProviderContainer();
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: Scaffold(
          body: SizedBox(height: 240, child: ProductCard(product: product)),
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

  group('ProductCard quick-add', () {
    testWidgets('affiche le bouton quick-add pour un produit sans variante/extra',
        (tester) async {
      await _pumpCardFor(tester, _simpleProduct);

      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('masque le bouton quick-add si le produit a des variantes',
        (tester) async {
      await _pumpCardFor(tester, _productWithVariant);

      expect(find.byIcon(Icons.add), findsNothing);
    });

    testWidgets('tap sur quick-add ajoute le produit au panier sans naviguer',
        (tester) async {
      final container = await _pumpCardFor(tester, _simpleProduct);

      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();

      final cart = container.read(cartProvider);
      expect(cart.totalQuantity, 1);
      expect(cart.itemList.single.product.id, _simpleProduct.id);
    });
  });
}
