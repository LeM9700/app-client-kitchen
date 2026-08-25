import 'package:flutter_test/flutter_test.dart';

import 'package:app_client/features/cart/providers/cart_provider.dart';
import 'package:app_client/features/catalog/models/product.dart';

// ──────────────────────────────────────────────────────────────────────────────
// Fixtures
// ──────────────────────────────────────────────────────────────────────────────
//
// `Product.id`/`ProductVariant.id`/`ProductExtra.id` sont des `int` dans le
// modèle réel, alignés sur l'API api-pizza — voir
// `lib/features/catalog/models/product.dart`.

const _variantS = ProductVariant(id: 10, name: 'S');
const _variantL = ProductVariant(id: 11, name: 'L', priceDelta: 3);

const _extraCheese = ProductExtra(id: 100, name: 'Fromage', price: 1.5);
const _extraOlives = ProductExtra(id: 101, name: 'Olives', price: 1);

const _mockProduct = Product(
  id: 1,
  name: 'Margherita',
  price: 10,
  categoryId: 1,
  variants: [_variantS, _variantL],
  extras: [_extraCheese, _extraOlives],
);

void main() {
  group('CartNotifier', () {
    test('addItem ajoute un produit avec quantité 1', () {
      final notifier = CartNotifier();
      notifier.addItem(_mockProduct);
      expect(notifier.state.totalQuantity, 1);
    });

    test('addItem incrémente si même clé (même variante + extras)', () {
      final notifier = CartNotifier();
      notifier.addItem(_mockProduct, variant: _variantS);
      notifier.addItem(_mockProduct, variant: _variantS);
      expect(notifier.state.totalQuantity, 2);
      expect(notifier.state.items.length, 1); // 1 seule ligne
    });

    test('deux variantes différentes du même produit = deux lignes distinctes',
        () {
      final notifier = CartNotifier();
      notifier.addItem(_mockProduct, variant: _variantS);
      notifier.addItem(_mockProduct, variant: _variantL);
      expect(notifier.state.items.length, 2);
    });

    test(
        'deux configurations d\'extras différentes du même produit = deux lignes distinctes',
        () {
      final notifier = CartNotifier();
      notifier.addItem(_mockProduct, extraIds: {_extraCheese.id});
      notifier.addItem(_mockProduct, extraIds: {_extraOlives.id});
      expect(notifier.state.items.length, 2);
    });

    test('updateQuantity(key, 0) supprime l\'item', () {
      final notifier = CartNotifier();
      notifier.addItem(_mockProduct);
      notifier.updateQuantity(notifier.state.items.keys.first, 0);
      expect(notifier.state.isEmpty, true);
    });

    test(
        'removeItem supprime une ligne individuellement, clear() vide tout le panier',
        () {
      final notifier = CartNotifier();
      notifier.addItem(_mockProduct, variant: _variantS);
      notifier.addItem(_mockProduct, variant: _variantL);
      expect(notifier.state.items.length, 2);

      final firstKey = notifier.state.items.keys.first;
      notifier.removeItem(firstKey);
      expect(notifier.state.items.length, 1);
      expect(notifier.state.items.containsKey(firstKey), false);

      notifier.clear();
      expect(notifier.state.isEmpty, true);
    });

    test('total = subtotal - promoDiscount', () {
      final notifier = CartNotifier();
      notifier.addItem(_mockProduct); // prix unitaire 10€ (pas de variante)
      expect(notifier.state.subtotal, 10.0);

      notifier.setPromoResult(discount: 2.0, code: 'TEST10');
      expect(notifier.state.total, 8.0);

      // setPromoError efface la remise appliquée et pose le message d'erreur.
      notifier.setPromoError('Code promo invalide.');
      expect(notifier.state.promoDiscount, isNull);
      expect(notifier.state.promoError, 'Code promo invalide.');
      expect(notifier.state.total, 10.0);
    });
  });
}
