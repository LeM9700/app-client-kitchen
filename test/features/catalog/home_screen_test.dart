import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:app_client/core/models/tenant_branding.dart';
import 'package:app_client/core/repositories/branding_repository.dart';
import 'package:app_client/core/router/app_routes.dart';
import 'package:app_client/core/theme/tenant_theme_provider.dart';
import 'package:app_client/l10n/app_localizations.dart';
import 'package:app_client/features/catalog/models/category.dart';
import 'package:app_client/features/catalog/models/product.dart';
import 'package:app_client/features/catalog/providers/catalog_provider.dart';
import 'package:app_client/features/catalog/screens/home_screen.dart';
import 'package:app_client/features/catalog/widgets/product_card.dart';
import 'package:app_client/features/checkout/providers/client_location_provider.dart';
import 'package:app_client/features/promotions/providers/promotions_provider.dart';

const _pizzaCategory = Category(id: 1, name: 'Pizzas');
const _dessertCategory = Category(id: 2, name: 'Desserts');

const _margherita =
    Product(id: 1, name: 'Margherita', price: 10, categoryId: 1);
const _tiramisu = Product(
  id: 2,
  name: 'Tiramisu',
  price: 6,
  categoryId: 2,
  isFeatured: true,
);

class _MockBrandingRepository extends Mock implements BrandingRepository {}

Future<ProviderContainer> _pumpHome(
  WidgetTester tester, {
  TenantBranding? branding,
}) async {
  final brandingRepository = _MockBrandingRepository();
  when(() => brandingRepository.fetchBranding(any())).thenAnswer(
    (_) async => branding ?? TenantBranding.demo(),
  );

  final container = ProviderContainer(
    overrides: [
      brandingRepositoryProvider.overrideWithValue(brandingRepository),
      categoriesProvider.overrideWith(
        (ref) async => [_pizzaCategory, _dessertCategory],
      ),
      featuredProductsProvider.overrideWith((ref) async => [_tiramisu]),
      productsByCategoryProvider(1).overrideWith((ref) async => [_margherita]),
      productsByCategoryProvider(2).overrideWith((ref) async => [_tiramisu]),
      allProductsProvider.overrideWith((ref) async => [_margherita, _tiramisu]),
      promotionsProvider.overrideWith((ref) async => []),
      clientLocationProvider.overrideWith(
        (ref) => const ClientLocation(
          address: '12 rue de la Paix',
          lat: 48.8566,
          lng: 2.3522,
        ),
      ),
    ],
  );
  addTearDown(container.dispose);

  await container.read(tenantBrandingProvider.notifier).load('kod-mome');

  final router = GoRouter(
    initialLocation: AppRoutes.home,
    routes: [
      GoRoute(path: AppRoutes.home, builder: (_, __) => const HomeScreen()),
      GoRoute(
        path: AppRoutes.search,
        builder: (_, __) => const Scaffold(body: Text('Search screen')),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (_, __) => const Scaffold(body: Text('Login screen')),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (_, __) => const Scaffold(body: Text('Notifications screen')),
      ),
      GoRoute(
        path: '/home/product/:id',
        builder: (_, __) => const Scaffold(body: Text('Product detail screen')),
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
  group('HomeScreen', () {
    testWidgets('affiche la row Incontournables avec les produits vedettes',
        (tester) async {
      await _pumpHome(tester);

      await tester.scrollUntilVisible(
        find.text('Incontournables'),
        400,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.text('Incontournables'), findsOneWidget);
      expect(find.text('Tiramisu'), findsWidgets);
    });

    testWidgets('affiche les categories comme raccourcis vers la recherche',
        (tester) async {
      final container = await _pumpHome(tester);

      expect(find.text('Pizzas'), findsOneWidget);
      expect(find.text('Desserts'), findsOneWidget);

      await tester.tap(find.text('Pizzas'));
      await tester.pumpAndSettle();

      expect(container.read(selectedCategoryProvider), _pizzaCategory.id);
      expect(find.text('Search screen'), findsOneWidget);
    });

    testWidgets('ne montre plus le vocabulaire marketplace multi-restaurants',
        (tester) async {
      await _pumpHome(tester);

      expect(find.text('Restaurant pres de vous'), findsNothing);
      expect(find.text('Nearest'), findsNothing);
      expect(find.text('Best Rating'), findsNothing);
    });

    testWidgets(
        'la cloche notifications redirige vers login quand non connecte',
        (tester) async {
      await _pumpHome(tester);

      expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.notifications_none_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Connectez-vous'), findsOneWidget);
      expect(find.text('Login screen'), findsOneWidget);
    });

    testWidgets("affiche la position exacte du client", (tester) async {
      await _pumpHome(tester);

      expect(find.text('Position client'), findsOneWidget);
      expect(find.text('12 rue de la Paix'), findsOneWidget);
      expect(find.text('48.85660, 2.35220'), findsOneWidget);
    });

    testWidgets("le chevron d'adresse reste decoratif et non tapable",
        (tester) async {
      await _pumpHome(tester);

      final chevronFinder = find.byIcon(Icons.keyboard_arrow_down);
      expect(chevronFinder, findsOneWidget);
      expect(
        find.ancestor(of: chevronFinder, matching: find.byType(IconButton)),
        findsNothing,
      );
    });

    testWidgets('affiche les actions contact configurees', (tester) async {
      await _pumpHome(
        tester,
        branding: const TenantBranding(
          slug: 'kod-mome',
          contactPhone: '+381 61 7035525',
          contactEmail: 'kod.mome@test.sb',
          instagramUrl: 'https://www.instagram.com/pizzeria_kod_mome',
          googleBusinessUrl: 'https://share.google/hzya4LW6sxGcX0HyX',
        ),
      );

      await tester.scrollUntilVisible(
        find.text('Nous joindre'),
        400,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.text('Appeler'), findsOneWidget);
      expect(find.byIcon(Icons.phone_outlined), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.byIcon(Icons.mail_outline), findsOneWidget);
      expect(find.text('Instagram'), findsOneWidget);
      expect(find.text('IG'), findsOneWidget);
      expect(find.text('GMB'), findsOneWidget);
      expect(find.text('Fiche Google'), findsOneWidget);
    });

    testWidgets(
        'un produit a la fois vedette et categorise ne casse pas la '
        'navigation (pas de collision de tag Hero)', (tester) async {
      await _pumpHome(tester);

      await tester.scrollUntilVisible(
        find.text('Incontournables'),
        400,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.byType(ProductCard), findsWidgets);

      await tester.tap(find.byType(ProductCard).first);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  group('HomeScreen - reset de selectedCategoryProvider', () {
    testWidgets(
        '"Voir tout" sur Incontournables reinitialise la categorie '
        'selectionnee avant de naviguer', (tester) async {
      final container = await _pumpHome(tester);
      container.read(selectedCategoryProvider.notifier).state =
          _dessertCategory.id;

      await tester.scrollUntilVisible(
        find.text('Incontournables'),
        400,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, 'Voir tout').first);
      await tester.pumpAndSettle();

      expect(container.read(selectedCategoryProvider), isNull);
      expect(find.text('Search screen'), findsOneWidget);
    });

    testWidgets(
        'la barre de recherche reinitialise la categorie selectionnee '
        'avant de naviguer', (tester) async {
      final container = await _pumpHome(tester);
      container.read(selectedCategoryProvider.notifier).state =
          _dessertCategory.id;

      await tester.enterText(find.byType(TextField), 'mar');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      expect(container.read(selectedCategoryProvider), isNull);
      expect(find.text('Search screen'), findsOneWidget);
    });
  });
}
