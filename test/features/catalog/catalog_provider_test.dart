import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:app_client/core/errors/app_exception.dart';
import 'package:app_client/features/catalog/models/product.dart';
import 'package:app_client/features/catalog/models/search_result.dart';
import 'package:app_client/features/catalog/providers/catalog_provider.dart';
import 'package:app_client/features/catalog/repositories/catalog_repository.dart';

// ──────────────────────────────────────────────────────────────────────────────
// Mocks (mocktail — cohérent avec test/features/checkout/checkout_provider_test.dart)
// ──────────────────────────────────────────────────────────────────────────────

class MockCatalogRepository extends Mock implements CatalogRepository {}

// ──────────────────────────────────────────────────────────────────────────────
// Fixtures
// ──────────────────────────────────────────────────────────────────────────────

const _product1 = Product(
  id: 1,
  name: 'Margherita',
  price: 10,
  categoryId: 1,
  allergens: ['gluten'],
);

const _product2 = Product(
  id: 2,
  name: 'Regina',
  price: 12,
  categoryId: 1,
  allergens: ['milk'],
);

void main() {
  setUpAll(() {
    // Requis par mocktail pour `any(named: 'allergens')` : `List<String>`
    // n'est pas un type "primitif" reconnu automatiquement — même exigence
    // que `List<CartItem>` dans checkout_provider_test.dart.
    registerFallbackValue(<String>[]);
  });

  late MockCatalogRepository mockRepo;
  late ProviderContainer container;

  setUp(() {
    mockRepo = MockCatalogRepository();
    container = ProviderContainer(
      overrides: [catalogRepositoryProvider.overrideWithValue(mockRepo)],
    );
    addTearDown(container.dispose);
  });

  // ──────────────────────────────────────────────────────────────────────────
  // categoriesProvider
  // ──────────────────────────────────────────────────────────────────────────

  group('categoriesProvider', () {
    test('délègue à CatalogRepository.getCategories()', () async {
      when(() => mockRepo.getCategories()).thenAnswer((_) async => []);

      final result = await container.read(categoriesProvider.future);

      expect(result, isEmpty);
      verify(() => mockRepo.getCategories()).called(1);
    });

    test('expose une AsyncError si le repository échoue', () async {
      when(() => mockRepo.getCategories()).thenThrow(const NetworkException());

      await expectLater(
        container.read(categoriesProvider.future),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // productsByCategoryProvider
  // ──────────────────────────────────────────────────────────────────────────

  group('productsByCategoryProvider', () {
    test('délègue au repository avec le categoryId demandé (.family)',
        () async {
      when(() => mockRepo.getProductsByCategory(1))
          .thenAnswer((_) async => [_product1]);

      final result = await container.read(productsByCategoryProvider(1).future);

      expect(result, [_product1]);
      verify(() => mockRepo.getProductsByCategory(1)).called(1);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // productDetailProvider
  // ──────────────────────────────────────────────────────────────────────────

  group('productDetailProvider', () {
    test('délègue au repository avec le productId demandé (.family)', () async {
      when(() => mockRepo.getProduct(1)).thenAnswer((_) async => _product1);

      final result = await container.read(productDetailProvider(1).future);

      expect(result, _product1);
      verify(() => mockRepo.getProduct(1)).called(1);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // featuredProductsProvider
  // ──────────────────────────────────────────────────────────────────────────

  group('featuredProductsProvider', () {
    test('délègue à CatalogRepository.getFeaturedProducts()', () async {
      when(() => mockRepo.getFeaturedProducts())
          .thenAnswer((_) async => [_product1]);

      final result = await container.read(featuredProductsProvider.future);

      expect(result, [_product1]);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // selectedCategoryProvider / activeAllergenFiltersProvider
  // ──────────────────────────────────────────────────────────────────────────

  group('selectedCategoryProvider', () {
    test('null par défaut ("Tout"), modifiable', () {
      expect(container.read(selectedCategoryProvider), isNull);

      container.read(selectedCategoryProvider.notifier).state = 3;

      expect(container.read(selectedCategoryProvider), 3);
    });
  });

  group('activeAllergenFiltersProvider', () {
    test('Set vide par défaut', () {
      expect(container.read(activeAllergenFiltersProvider), isEmpty);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // filteredProductsProvider
  // ──────────────────────────────────────────────────────────────────────────

  group('filteredProductsProvider', () {
    test('sans filtre allergène actif, retourne tous les produits', () async {
      when(() => mockRepo.getProductsByCategory(1))
          .thenAnswer((_) async => [_product1, _product2]);
      // Laisse le FutureProvider sous-jacent se résoudre avant de lire le
      // Provider dérivé (synchrone).
      await container.read(productsByCategoryProvider(1).future);

      final result = container.read(filteredProductsProvider(1));

      expect(result.value, [_product1, _product2]);
    });

    test('exclut les produits contenant un allergène actif', () async {
      when(() => mockRepo.getProductsByCategory(1))
          .thenAnswer((_) async => [_product1, _product2]);
      await container.read(productsByCategoryProvider(1).future);

      container.read(activeAllergenFiltersProvider.notifier).state = {
        'gluten',
      };

      final result = container.read(filteredProductsProvider(1));

      // _product1 contient 'gluten' → exclu ; _product2 ('milk') → conservé.
      expect(result.value, [_product2]);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // filteredFeaturedProductsProvider
  // ──────────────────────────────────────────────────────────────────────────

  group('filteredFeaturedProductsProvider', () {
    test('sans filtre allergène actif, retourne tous les produits vedettes',
        () async {
      when(() => mockRepo.getFeaturedProducts())
          .thenAnswer((_) async => [_product1, _product2]);
      await container.read(featuredProductsProvider.future);

      final result = container.read(filteredFeaturedProductsProvider);

      expect(result.value, [_product1, _product2]);
    });

    test('exclut les produits vedettes contenant un allergène actif',
        () async {
      when(() => mockRepo.getFeaturedProducts())
          .thenAnswer((_) async => [_product1, _product2]);
      await container.read(featuredProductsProvider.future);

      container.read(activeAllergenFiltersProvider.notifier).state = {
        'gluten',
      };

      final result = container.read(filteredFeaturedProductsProvider);

      // _product1 contient 'gluten' → exclu ; _product2 ('milk') → conservé.
      expect(result.value, [_product2]);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // searchResultProvider / SearchNotifier — debounce 300ms + retry() (ajouté
  // cette session, voir search_screen.dart et plan-19-ux-polish.md).
  // ──────────────────────────────────────────────────────────────────────────

  group('SearchNotifier', () {
    test(
        'état initial AsyncValue.data(null) — pas de recherche tant que rien '
        'n\'est saisi', () {
      final state = container.read(searchResultProvider);
      expect(state, isA<AsyncData<SearchResult?>>());
      expect(state.value, isNull);
    });

    test(
      'retry() relance la recherche pour le terme courant SANS attendre le '
      'debounce',
      () async {
        when(() => mockRepo.search('pizza', allergens: [])).thenAnswer(
          (_) async => const SearchResult(
            products: [_product1],
            total: 1,
            query: 'pizza',
          ),
        );

        // Le query est posé AVANT la création du SearchNotifier : son
        // listener interne sur `searchQueryProvider` (voir
        // `catalog_provider.dart`) ne s'abonne qu'à la création du notifier,
        // donc ce changement ne déclenche PAS le debounce automatique — seul
        // `retry()` doit appeler le repository ci-dessous, ce qui isole le
        // test de la mécanique de debounce (déjà couverte par le test
        // suivant).
        container.read(searchQueryProvider.notifier).state = 'pizza';

        final notifier = container.read(searchResultProvider.notifier);
        await notifier.retry();

        final state = container.read(searchResultProvider);
        expect(state.value?.total, 1);
        expect(state.value?.products, [_product1]);
        verify(() => mockRepo.search('pizza', allergens: [])).called(1);
      },
    );

    test('retry() ne fait rien si le terme courant fait moins de 2 caractères',
        () async {
      final notifier = container.read(searchResultProvider.notifier);
      container.read(searchQueryProvider.notifier).state = 'p';

      await notifier.retry();

      verifyNever(
        () => mockRepo.search(any(), allergens: any(named: 'allergens')),
      );
    });

    test(
      'la saisie déclenche automatiquement une recherche après ~300ms de '
      'debounce',
      () async {
        when(() => mockRepo.search('marg', allergens: [])).thenAnswer(
          (_) async => const SearchResult(
            products: <Product>[],
            total: 0,
            query: 'marg',
          ),
        );

        // Crée le notifier (et son listener sur searchQueryProvider) AVANT
        // de modifier le query, pour que le debounce automatique se
        // déclenche.
        container.listen(searchResultProvider, (_, __) {});
        container.read(searchQueryProvider.notifier).state = 'marg';

        await Future<void>.delayed(const Duration(milliseconds: 400));

        verify(() => mockRepo.search('marg', allergens: [])).called(1);
      },
    );

    test('utilise les allergens actifs comme filtre de recherche', () async {
      when(() => mockRepo.search('pizza', allergens: ['gluten'])).thenAnswer(
        (_) async => const SearchResult(
          products: <Product>[],
          total: 0,
          query: 'pizza',
        ),
      );

      container.read(activeAllergenFiltersProvider.notifier).state = {
        'gluten',
      };
      container.read(searchQueryProvider.notifier).state = 'pizza';

      final notifier = container.read(searchResultProvider.notifier);
      await notifier.retry();

      verify(() => mockRepo.search('pizza', allergens: ['gluten'])).called(1);
    });
  });
}
