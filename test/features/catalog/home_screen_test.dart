import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:app_client/core/router/app_routes.dart';
import 'package:app_client/features/catalog/models/category.dart';
import 'package:app_client/features/catalog/models/product.dart';
import 'package:app_client/features/catalog/providers/catalog_provider.dart';
import 'package:app_client/features/catalog/screens/home_screen.dart';
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

Future<void> _pumpHome(WidgetTester tester) async {
  final router = GoRouter(
    initialLocation: AppRoutes.home,
    routes: [
      GoRoute(path: AppRoutes.home, builder: (_, __) => const HomeScreen()),
      GoRoute(
        path: AppRoutes.search,
        builder: (_, __) => const Scaffold(body: Text('Search screen')),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        categoriesProvider.overrideWith(
          (ref) async => [_pizzaCategory, _dessertCategory],
        ),
        featuredProductsProvider.overrideWith((ref) async => [_tiramisu]),
        productsByCategoryProvider(1)
            .overrideWith((ref) async => [_margherita]),
        productsByCategoryProvider(2).overrideWith((ref) async => [_tiramisu]),
        promotionsProvider.overrideWith((ref) async => []),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('HomeScreen', () {
    testWidgets('affiche la row Incontournables avec les produits vedettes',
        (tester) async {
      await _pumpHome(tester);

      expect(find.text('Incontournables'), findsOneWidget);
      expect(find.text('Tiramisu'), findsWidgets);
    });

    testWidgets('affiche une row par catégorie, nommée dynamiquement',
        (tester) async {
      await _pumpHome(tester);

      expect(find.text('Pizzas'), findsWidgets);
      expect(find.text('Desserts'), findsWidgets);
      expect(find.text('Margherita'), findsWidgets);
    });

    testWidgets('ne montre plus le vocabulaire marketplace multi-restaurants',
        (tester) async {
      await _pumpHome(tester);

      expect(find.text('Restaurant pres de vous'), findsNothing);
      expect(find.text('Nearest'), findsNothing);
      expect(find.text('Best Rating'), findsNothing);
    });

    testWidgets("la cloche notifications n'est plus un bouton tapable",
        (tester) async {
      await _pumpHome(tester);

      expect(find.byIcon(Icons.notifications_none), findsOneWidget);
      expect(find.byType(IconButton), findsNothing);
    });
  });
}
