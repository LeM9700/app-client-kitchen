import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_client/core/analytics/analytics_reporter.dart';
import 'package:app_client/features/cart/providers/cart_provider.dart';
import 'package:app_client/features/catalog/models/product.dart';
import 'package:app_client/features/catalog/providers/catalog_provider.dart';
import 'package:app_client/features/catalog/screens/product_detail_screen.dart';

const _mediumVariant = ProductVariant(id: 10, name: 'Moyenne');
const _largeVariant = ProductVariant(
  id: 11,
  name: 'Grande',
  priceDelta: 3,
);
const _olivesExtra = ProductExtra(id: 100, name: 'Olives', price: 1.5);

const _availableProduct = Product(
  id: 1,
  name: 'Margherita',
  price: 10,
  description: 'Tomate, mozzarella, basilic',
  variants: [_mediumVariant, _largeVariant],
  extras: [_olivesExtra],
);

const _unavailableProduct = Product(
  id: 2,
  name: 'Regina',
  price: 12,
  isAvailable: false,
);

class _RecordedAnalyticsEvent {
  const _RecordedAnalyticsEvent(this.name, this.properties);

  final String name;
  final Map<String, Object?> properties;
}

class _RecordingAnalyticsReporter implements AnalyticsReporter {
  final events = <_RecordedAnalyticsEvent>[];

  @override
  void track(String eventName, Map<String, Object?> properties) {
    events.add(_RecordedAnalyticsEvent(eventName, properties));
  }
}

Future<ProviderContainer> _pumpProductDetail(
  WidgetTester tester,
  Product product, {
  AnalyticsReporter? analyticsReporter,
}) async {
  final container = ProviderContainer(
    overrides: [
      productDetailProvider(product.id).overrideWith((ref) async => product),
      if (analyticsReporter != null)
        analyticsReporterProvider.overrideWithValue(analyticsReporter),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: ProductDetailScreen(productId: product.id.toString()),
      ),
    ),
  );
  await tester.pumpAndSettle();

  return container;
}

void main() {
  group('ProductDetailScreen', () {
    testWidgets(
      'adds selected variant, extras and quantity through the UI',
      (tester) async {
        final analytics = _RecordingAnalyticsReporter();
        final container = await _pumpProductDetail(
          tester,
          _availableProduct,
          analyticsReporter: analytics,
        );

        await tester.scrollUntilVisible(
          find.text('Grande'),
          250,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(find.text('Grande'));
        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(
          find.text('Olives'),
          250,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(find.text('Olives'));
        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(
          find.byIcon(Icons.add_circle_outline),
          250,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(find.byIcon(Icons.add_circle_outline));
        await tester.pumpAndSettle();

        await tester
            .tap(find.widgetWithText(ElevatedButton, 'Ajouter au panier'));
        await tester.pumpAndSettle();

        final cart = container.read(cartProvider);
        expect(cart.totalQuantity, 2);
        expect(cart.items, hasLength(1));

        final item = cart.itemList.single;
        expect(item.product.id, _availableProduct.id);
        expect(item.quantity, 2);
        expect(item.selectedVariant?.id, _largeVariant.id);
        expect(item.selectedExtraIds, {_olivesExtra.id});
        expect(item.unitPrice, 14.5);
        expect(item.totalPrice, 29);

        expect(analytics.events, hasLength(1));
        expect(analytics.events.single.name, 'cart_item_added');
        expect(
          analytics.events.single.properties,
          containsPair('source', 'product_detail'),
        );
        expect(
          analytics.events.single.properties,
          containsPair('product_id', _availableProduct.id),
        );
      },
    );

    testWidgets('does not add an unavailable product', (tester) async {
      final container = await _pumpProductDetail(tester, _unavailableProduct);

      final button = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Produit indisponible'),
      );

      expect(button.onPressed, isNull);
      expect(container.read(cartProvider).isEmpty, true);
    });
  });
}
