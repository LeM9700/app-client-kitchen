import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:app_client/core/router/app_routes.dart';
import 'package:app_client/features/cart/providers/cart_provider.dart';
import 'package:app_client/features/cart/screens/cart_screen.dart';
import 'package:app_client/features/catalog/models/product.dart';
import 'package:app_client/l10n/app_localizations.dart';

const _largeVariant = ProductVariant(
  id: 11,
  name: 'Grande',
  priceDelta: 3,
);

const _olivesExtra = ProductExtra(id: 100, name: 'Olives', price: 1.5);

const _product = Product(
  id: 1,
  name: 'Margherita',
  price: 10,
  variants: [_largeVariant],
  extras: [_olivesExtra],
);

Future<ProviderContainer> _pumpCart(WidgetTester tester) async {
  final container = ProviderContainer();
  container.read(cartProvider.notifier).addItem(
    _product,
    quantity: 2,
    variant: _largeVariant,
    extraIds: {_olivesExtra.id},
  );
  addTearDown(container.dispose);

  final router = GoRouter(
    initialLocation: AppRoutes.cart,
    routes: [
      GoRoute(path: AppRoutes.cart, builder: (_, __) => const CartScreen()),
      GoRoute(
        path: AppRoutes.checkout,
        builder: (_, __) => const Scaffold(body: Text('Checkout screen')),
      ),
    ],
  );

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('fr'),
      ),
    ),
  );
  await tester.pumpAndSettle();

  return container;
}

void main() {
  group('CartScreen', () {
    testWidgets('renders real cart lines, options and totals', (tester) async {
      await _pumpCart(tester);

      expect(find.text('Margherita'), findsOneWidget);
      expect(find.text('Grande'), findsOneWidget);
      expect(find.text('Olives'), findsOneWidget);
      expect(find.text('Sous-total'), findsOneWidget);
      expect(find.text('Total'), findsOneWidget);
      expect(find.textContaining('29.00'), findsWidgets);
      expect(
        find.text('Connectez-vous pour utiliser un code promo.'),
        findsOneWidget,
      );
    });

    testWidgets('updates quantity from the cart controls', (tester) async {
      final container = await _pumpCart(tester);

      await tester.tap(find.byIcon(Icons.add).first);
      await tester.pumpAndSettle();

      expect(container.read(cartProvider).totalQuantity, 3);

      await tester.tap(find.byIcon(Icons.remove).first);
      await tester.pumpAndSettle();

      expect(container.read(cartProvider).totalQuantity, 2);
    });

    testWidgets('keeps checkout navigation on the existing route',
        (tester) async {
      await _pumpCart(tester);

      await tester.tap(find.textContaining('Commander').first);
      await tester.pumpAndSettle();

      expect(find.text('Checkout screen'), findsOneWidget);
    });
  });
}
