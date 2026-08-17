import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_client/features/catalog/models/category.dart';
import 'package:app_client/features/catalog/models/product.dart';
import 'package:app_client/features/catalog/providers/catalog_provider.dart';
import 'package:app_client/features/catalog/screens/search_screen.dart';

const _pizzaCategory = Category(id: 1, name: 'Pizzas');
const _dessertCategory = Category(id: 2, name: 'Desserts');
const _margherita =
    Product(id: 1, name: 'Margherita', price: 10, categoryId: 1);

Future<ProviderContainer> _pumpSearch(
  WidgetTester tester, {
  int? selectedCategoryId,
}) async {
  final container = ProviderContainer(
    overrides: [
      categoriesProvider.overrideWith(
        (ref) async => [_pizzaCategory, _dessertCategory],
      ),
      featuredProductsProvider.overrideWith((ref) async => [_margherita]),
      productsByCategoryProvider(1)
          .overrideWith((ref) async => [_margherita]),
    ],
  );
  addTearDown(container.dispose);

  if (selectedCategoryId != null) {
    container.read(selectedCategoryProvider.notifier).state =
        selectedCategoryId;
  }

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: SearchScreen()),
    ),
  );
  await tester.pumpAndSettle();

  return container;
}

void main() {
  group('SearchScreen', () {
    testWidgets(
        'titre générique "Explorer le menu" sans catégorie sélectionnée',
        (tester) async {
      await _pumpSearch(tester);

      expect(find.text('Explorer le menu'), findsOneWidget);
      expect(find.text('Recommendations'), findsNothing);
    });

    testWidgets('titre = nom de la catégorie sélectionnée', (tester) async {
      await _pumpSearch(tester, selectedCategoryId: 1);

      expect(find.text('Pizzas'), findsWidgets);
      expect(find.text('Explorer le menu'), findsNothing);
    });

    testWidgets('affiche toutes les catégories, sans filtres factices',
        (tester) async {
      await _pumpSearch(tester);

      expect(find.text('Tout'), findsOneWidget);
      expect(find.text('Pizzas'), findsOneWidget);
      expect(find.text('Desserts'), findsOneWidget);
      expect(find.text('Nearest'), findsNothing);
      expect(find.text('Best Rating'), findsNothing);
    });
  });
}
