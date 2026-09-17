import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:app_client/core/providers/auth_token_provider.dart';
import 'package:app_client/core/router/app_routes.dart';
import 'package:app_client/features/cart/providers/cart_provider.dart';
import 'package:app_client/features/catalog/models/product.dart';
import 'package:app_client/features/catalog/providers/favorites_provider.dart';
import 'package:app_client/features/catalog/repositories/favorites_repository.dart';
import 'package:app_client/features/catalog/widgets/product_card.dart';
import 'package:app_client/l10n/app_localizations.dart';

class MockFavoritesRepository extends Mock implements FavoritesRepository {}

const _product = Product(id: 1, name: 'Margherita', price: 10);
const _simpleProduct = Product(id: 1, name: 'Margherita', price: 10);
const _productWithVariant = Product(
  id: 2,
  name: 'Regina',
  price: 12,
  variants: [ProductVariant(id: 1, name: 'Grande', priceDelta: 3)],
);
const _productWithIndicativePrice = Product(
  id: 3,
  name: 'Regina',
  price: 12,
  indicativePrice: 13.2,
  indicativeCurrency: 'USD',
);

Future<ProviderContainer> _pumpCard(
  WidgetTester tester, {
  Product product = _product,
  bool authenticated = false,
  MockFavoritesRepository? favoritesRepository,
}) async {
  final overrides = <Override>[];
  if (authenticated) {
    final repo = favoritesRepository ?? MockFavoritesRepository();
    when(() => repo.list()).thenAnswer((_) async => {});
    when(() => repo.add(any())).thenAnswer((_) async {});
    when(() => repo.remove(any())).thenAnswer((_) async {});
    overrides.addAll([
      accessTokenProvider.overrideWith((ref) => 'fake-token'),
      favoritesRepositoryProvider.overrideWithValue(repo),
    ]);
  }

  final container = ProviderContainer(overrides: overrides);
  addTearDown(container.dispose);

  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => Scaffold(
          body: SizedBox(height: 240, child: ProductCard(product: product)),
        ),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (_, __) => const Scaffold(body: Text('LOGIN_ROUTE')),
      ),
      GoRoute(
        path: '/home/product/:id',
        builder: (_, __) => const Scaffold(body: Text('PRODUCT_ROUTE')),
      ),
    ],
  );
  addTearDown(router.dispose);

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
  group('ProductCard favorite toggle', () {
    testWidgets('affiche un coeur vide par defaut', (tester) async {
      await _pumpCard(tester);

      expect(find.byIcon(Icons.favorite_border), findsOneWidget);
      expect(find.byIcon(Icons.favorite), findsNothing);
    });

    testWidgets('anonyme: tap sur le coeur ouvre la connexion', (tester) async {
      final container = await _pumpCard(tester);

      await tester.tap(find.byIcon(Icons.favorite_border));
      await tester.pumpAndSettle();

      expect(container.read(favoritesProvider), isEmpty);
      expect(find.text('LOGIN_ROUTE'), findsOneWidget);
    });

    testWidgets('connecte: tap sur le coeur bascule le favori', (tester) async {
      final repo = MockFavoritesRepository();
      final container = await _pumpCard(
        tester,
        authenticated: true,
        favoritesRepository: repo,
      );

      await tester.tap(find.byIcon(Icons.favorite_border));
      await tester.pump();

      expect(container.read(favoritesProvider), {1});
      expect(find.byIcon(Icons.favorite), findsOneWidget);
      verify(() => repo.add(1)).called(1);
    });

    testWidgets('connecte: un second tap retire le favori', (tester) async {
      final repo = MockFavoritesRepository();
      final container = await _pumpCard(
        tester,
        authenticated: true,
        favoritesRepository: repo,
      );

      await tester.tap(find.byIcon(Icons.favorite_border));
      await tester.pump();
      await tester.tap(find.byIcon(Icons.favorite));
      await tester.pump();

      expect(container.read(favoritesProvider), isEmpty);
      verify(() => repo.remove(1)).called(1);
    });
  });

  group('ProductCard quick-add', () {
    testWidgets(
        'affiche le bouton quick-add pour un produit sans variante/extra',
        (tester) async {
      await _pumpCard(tester, product: _simpleProduct);

      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('masque le bouton quick-add si le produit a des variantes',
        (tester) async {
      await _pumpCard(tester, product: _productWithVariant);

      expect(find.byIcon(Icons.add), findsNothing);
    });

    testWidgets('tap sur quick-add ajoute le produit au panier sans naviguer',
        (tester) async {
      final container = await _pumpCard(tester, product: _simpleProduct);

      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();

      final cart = container.read(cartProvider);
      expect(cart.totalQuantity, 1);
      expect(cart.itemList.single.product.id, _simpleProduct.id);
    });
  });

  group('ProductCard prix indicatif', () {
    testWidgets('n\'affiche rien quand aucune devise d\'affichage n\'est choisie',
        (tester) async {
      await _pumpCard(tester, product: _simpleProduct);

      expect(find.textContaining('~'), findsNothing);
    });

    testWidgets('affiche le prix indicatif quand fourni par l\'API',
        (tester) async {
      await _pumpCard(tester, product: _productWithIndicativePrice);

      expect(find.text('~13.20 USD'), findsOneWidget);
    });
  });
}
