import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_client/features/catalog/models/product.dart';
import 'package:app_client/features/catalog/providers/catalog_provider.dart';

class CatalogSearchFilters {
  const CatalogSearchFilters({
    this.minPrice,
    this.maxPrice,
    this.vegetarianOnly = false,
    this.spicyOnly = false,
    this.popularOnly = false,
    this.newsOnly = false,
  });

  final double? minPrice;
  final double? maxPrice;
  final bool vegetarianOnly;
  final bool spicyOnly;
  final bool popularOnly;
  final bool newsOnly;

  bool get hasPriceFilter => minPrice != null || maxPrice != null;

  bool get hasActive =>
      hasPriceFilter || vegetarianOnly || spicyOnly || popularOnly || newsOnly;

  int get activeCount =>
      (hasPriceFilter ? 1 : 0) +
      (vegetarianOnly ? 1 : 0) +
      (spicyOnly ? 1 : 0) +
      (popularOnly ? 1 : 0) +
      (newsOnly ? 1 : 0);

  CatalogSearchFilters copyWith({
    Object? minPrice = _unset,
    Object? maxPrice = _unset,
    bool? vegetarianOnly,
    bool? spicyOnly,
    bool? popularOnly,
    bool? newsOnly,
  }) {
    return CatalogSearchFilters(
      minPrice: minPrice == _unset ? this.minPrice : minPrice as double?,
      maxPrice: maxPrice == _unset ? this.maxPrice : maxPrice as double?,
      vegetarianOnly: vegetarianOnly ?? this.vegetarianOnly,
      spicyOnly: spicyOnly ?? this.spicyOnly,
      popularOnly: popularOnly ?? this.popularOnly,
      newsOnly: newsOnly ?? this.newsOnly,
    );
  }

  static const empty = CatalogSearchFilters();
}

const Object _unset = Object();

final catalogSearchFiltersProvider =
    StateNotifierProvider<CatalogSearchFiltersNotifier, CatalogSearchFilters>(
  (ref) => CatalogSearchFiltersNotifier(),
);

class CatalogSearchFiltersNotifier extends StateNotifier<CatalogSearchFilters> {
  CatalogSearchFiltersNotifier() : super(CatalogSearchFilters.empty);

  void setPriceRange(double? min, double? max) {
    state = state.copyWith(minPrice: min, maxPrice: max);
  }

  void setVegetarianOnly(bool value) {
    state = state.copyWith(vegetarianOnly: value);
  }

  void setSpicyOnly(bool value) {
    state = state.copyWith(spicyOnly: value);
  }

  void setPopularOnly(bool value) {
    state = state.copyWith(popularOnly: value);
  }

  void setNewsOnly(bool value) {
    state = state.copyWith(newsOnly: value);
  }

  void reset() => state = CatalogSearchFilters.empty;
}

final catalogActiveFilterCountProvider = Provider<int>((ref) {
  final filters = ref.watch(catalogSearchFiltersProvider);
  final selectedCategoryId = ref.watch(selectedCategoryProvider);
  final allergens = ref.watch(activeAllergenFiltersProvider);
  return filters.activeCount +
      (selectedCategoryId == null ? 0 : 1) +
      allergens.length;
});

final catalogSearchResultsProvider =
    Provider.autoDispose<AsyncValue<List<Product>>>((ref) {
  final productsAsync = ref.watch(allProductsProvider);
  final query = ref.watch(searchQueryProvider);
  final selectedCategoryId = ref.watch(selectedCategoryProvider);
  final allergenFilters = ref.watch(activeAllergenFiltersProvider);
  final filters = ref.watch(catalogSearchFiltersProvider);

  return productsAsync.whenData(
    (products) => filterCatalogProducts(
      products,
      query: query,
      categoryId: selectedCategoryId,
      excludedAllergens: allergenFilters,
      filters: filters,
    ),
  );
});

final catalogSuggestionsProvider =
    Provider.autoDispose<AsyncValue<List<Product>>>((ref) {
  final query = ref.watch(searchQueryProvider);
  if (query.trim().length < 2) {
    return const AsyncValue.data([]);
  }

  final resultsAsync = ref.watch(catalogSearchResultsProvider);
  return resultsAsync.whenData((products) => products.take(6).toList());
});

List<Product> filterCatalogProducts(
  List<Product> products, {
  required String query,
  required int? categoryId,
  required Set<String> excludedAllergens,
  required CatalogSearchFilters filters,
}) {
  final normalizedQuery = _normalize(query);

  return products.where((product) {
    if (!product.isAvailable) return false;
    if (categoryId != null && product.categoryId != categoryId) return false;
    if (excludedAllergens.any(product.allergens.contains)) return false;
    if (filters.minPrice != null && product.price < filters.minPrice!) {
      return false;
    }
    if (filters.maxPrice != null && product.price > filters.maxPrice!) {
      return false;
    }
    if (filters.popularOnly && !product.isFeatured) return false;
    if (filters.vegetarianOnly && !_looksVegetarian(product)) return false;
    if (filters.spicyOnly && !_looksSpicy(product)) return false;
    if (filters.newsOnly && !_looksNew(product)) return false;
    if (normalizedQuery.isNotEmpty &&
        !_matchesQuery(product, normalizedQuery)) {
      return false;
    }
    return true;
  }).toList()
    ..sort((a, b) {
      final featuredSort = (b.isFeatured ? 1 : 0) - (a.isFeatured ? 1 : 0);
      if (featuredSort != 0) return featuredSort;
      final orderSort = a.sortOrder.compareTo(b.sortOrder);
      if (orderSort != 0) return orderSort;
      return a.name.compareTo(b.name);
    });
}

bool productLooksLikeKind(Product product, CatalogSectionKind kind) {
  final haystack = _productText(product);
  return switch (kind) {
    CatalogSectionKind.drinks => _containsAny(haystack, const [
        'boisson',
        'drink',
        'soda',
        'coca',
        'cola',
        'fanta',
        'sprite',
        'eau',
        'jus',
      ]),
    CatalogSectionKind.desserts => _containsAny(haystack, const [
        'dessert',
        'tiramisu',
        'cookie',
        'brownie',
        'glace',
        'sucre',
        'chocolat',
      ]),
    CatalogSectionKind.news => _looksNew(product),
  };
}

enum CatalogSectionKind { drinks, desserts, news }

bool _matchesQuery(Product product, String normalizedQuery) {
  return _productText(product).contains(normalizedQuery);
}

bool _looksVegetarian(Product product) {
  final text = _productText(product);
  return _containsAny(text, const [
    'vegetar',
    'veggie',
    'legume',
    'margherita',
    'margarita',
    'fromage',
  ]);
}

bool _looksSpicy(Product product) {
  final text = _productText(product);
  return _containsAny(text, const [
    'piment',
    'piquant',
    'spicy',
    'harissa',
    'nduja',
    'jalapeno',
  ]);
}

bool _looksNew(Product product) {
  final text = _productText(product);
  return _containsAny(text, const [
    'nouveau',
    'nouveaute',
    'new',
    'edition limitee',
  ]);
}

bool _containsAny(String text, List<String> needles) {
  for (final needle in needles) {
    if (text.contains(needle)) return true;
  }
  return false;
}

String _productText(Product product) {
  return _normalize(
    [
      product.name,
      product.description,
      ...product.allergens,
    ].whereType<String>().join(' '),
  );
}

String _normalize(String value) {
  return value
      .toLowerCase()
      .replaceAll('é', 'e')
      .replaceAll('è', 'e')
      .replaceAll('ê', 'e')
      .replaceAll('ë', 'e')
      .replaceAll('à', 'a')
      .replaceAll('â', 'a')
      .replaceAll('ä', 'a')
      .replaceAll('î', 'i')
      .replaceAll('ï', 'i')
      .replaceAll('ô', 'o')
      .replaceAll('ö', 'o')
      .replaceAll('ù', 'u')
      .replaceAll('û', 'u')
      .replaceAll('ü', 'u')
      .replaceAll('ç', 'c')
      .trim();
}
