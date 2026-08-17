import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_client/core/providers/api_client_provider.dart';
import 'package:app_client/features/catalog/models/category.dart';
import 'package:app_client/features/catalog/models/product.dart';
import 'package:app_client/features/catalog/models/search_result.dart';
import 'package:app_client/features/catalog/repositories/catalog_repository.dart';

// ──────────────────────────────────────────────────────────────────────────────
// Repository provider
// ──────────────────────────────────────────────────────────────────────────────

/// Repository catalogue — singleton, pas d'auth requise.
final catalogRepositoryProvider = Provider<CatalogRepository>((ref) {
  return CatalogRepository(ref.read(apiClientProvider));
});

// ──────────────────────────────────────────────────────────────────────────────
// Données
// ──────────────────────────────────────────────────────────────────────────────

/// Toutes les catégories actives.
///
/// [keepAlive] implicite via [autoDispose] absent — données gardées tant que
/// l'application est ouverte (catalogue rarement modifié en temps réel).
final categoriesProvider = FutureProvider<List<Category>>((ref) {
  return ref.read(catalogRepositoryProvider).getCategories();
});

/// Produits d'une catégorie.
///
/// [.family] permet d'avoir un cache distinct par [categoryId].
/// [autoDispose] : libéré quand la catégorie n'est plus visible, rechargé
/// à la navigation suivante. Trade-off réseau / mémoire acceptable ici.
final productsByCategoryProvider =
    FutureProvider.family.autoDispose<List<Product>, int>(
  (ref, categoryId) {
    return ref
        .read(catalogRepositoryProvider)
        .getProductsByCategory(categoryId);
  },
);

/// Produits mis en avant (section hero homepage).
///
/// Chargé au boot via [SplashScreen] si on veut anticiper.
final featuredProductsProvider = FutureProvider<List<Product>>((ref) {
  return ref.read(catalogRepositoryProvider).getFeaturedProducts();
});

/// Détail d'un produit par son id.
///
/// [autoDispose] : libéré quand la fiche produit est fermée.
/// Évite d'avoir des centaines de produits en mémoire sur un catalogue large.
final productDetailProvider = FutureProvider.family.autoDispose<Product, int>(
  (ref, productId) {
    return ref.read(catalogRepositoryProvider).getProduct(productId);
  },
);

// ──────────────────────────────────────────────────────────────────────────────
// Filtres allergens
// ──────────────────────────────────────────────────────────────────────────────

/// Filtres allergens actifs — Set vide = aucun filtre.
///
/// Persisté dans la session (pas en DB : préférence légère, pas critique).
/// [⚠️ PROD] Penser à persister en SharedPreferences pour retrouver le filtre
/// à la réouverture de l'app (Plan ultérieur).
final activeAllergenFiltersProvider =
    StateProvider<Set<String>>((ref) => const {});

/// Catégorie sélectionnée dans les chips (null = "Tout").
final selectedCategoryProvider = StateProvider<int?>((ref) => null);

/// Produits filtrés côté client selon les allergens actifs.
///
/// Combine [productsByCategoryProvider] + [activeAllergenFiltersProvider].
/// Filtre exécuté en mémoire — acceptable pour catalogues <500 produits.
final filteredProductsProvider =
    Provider.family.autoDispose<AsyncValue<List<Product>>, int>(
  (ref, categoryId) {
    final productsAsync = ref.watch(productsByCategoryProvider(categoryId));
    final allergenFilters = ref.watch(activeAllergenFiltersProvider);

    if (allergenFilters.isEmpty) return productsAsync;

    return productsAsync.whenData(
      (products) => products
          .where(
            (p) => !allergenFilters.any((a) => p.allergens.contains(a)),
          )
          .toList(),
    );
  },
);

/// Produits vedettes filtrés côté client selon les allergens actifs.
///
/// Même logique que [filteredProductsProvider] mais appliquée à
/// [featuredProductsProvider] (pas de [.family] : ce dernier ne prend pas
/// d'id de catégorie). Utilisé par la row "Incontournables" de la home pour
/// que le filtre allergène affiché juste au-dessus s'applique bien partout,
/// pas seulement aux rows par catégorie.
final filteredFeaturedProductsProvider =
    Provider.autoDispose<AsyncValue<List<Product>>>((ref) {
  final productsAsync = ref.watch(featuredProductsProvider);
  final allergenFilters = ref.watch(activeAllergenFiltersProvider);

  if (allergenFilters.isEmpty) return productsAsync;

  return productsAsync.whenData(
    (products) => products
        .where(
          (p) => !allergenFilters.any((a) => p.allergens.contains(a)),
        )
        .toList(),
  );
});

// ──────────────────────────────────────────────────────────────────────────────
// Recherche avec debounce
// ──────────────────────────────────────────────────────────────────────────────

/// Terme de recherche courant (brut, saisi par l'utilisateur).
final searchQueryProvider = StateProvider<String>((ref) => '');

/// Résultats de recherche avec debounce 300 ms.
///
/// Architecture du debounce : on écoute [searchQueryProvider] et on utilise
/// [ref.debounce] (Riverpod 2.x n'a pas de debounce natif donc on passe
/// par un [StreamProvider] qui consomme le StateProvider).
///
/// Alternative rejetée : Timer dans le widget → couplage fort UI/logique.
/// Alternative retenue : StateNotifier dédié avec Timer annulable.
final searchResultProvider = StateNotifierProvider.autoDispose<SearchNotifier,
    AsyncValue<SearchResult?>>(
  (ref) => SearchNotifier(ref),
);

/// Notifier qui gère le debounce de recherche.
class SearchNotifier extends StateNotifier<AsyncValue<SearchResult?>> {
  SearchNotifier(this._ref) : super(const AsyncValue.data(null)) {
    // Écoute le query et déclenche la recherche après 300 ms d'inactivité.
    _ref.listen<String>(searchQueryProvider, (_, query) {
      _onQueryChanged(query);
    });
  }

  final Ref _ref;
  DateTime? _lastChange;

  Future<void> _onQueryChanged(String query) async {
    final now = DateTime.now();
    _lastChange = now;

    if (query.length < 2) {
      state = const AsyncValue.data(null);
      return;
    }

    // Debounce 300 ms
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (_lastChange != now) return; // une frappe plus récente annule

    await _runSearch(query);
  }

  /// Relance la recherche pour le terme courant, sans debounce — utilisé par
  /// le bouton "Réessayer" de [ErrorView] sur [SearchScreen] (voir
  /// plan-19-ux-polish.md, retry pattern uniforme).
  Future<void> retry() async {
    final query = _ref.read(searchQueryProvider);
    if (query.length < 2) return;
    _lastChange = DateTime.now();
    await _runSearch(query);
  }

  Future<void> _runSearch(String query) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final allergens = _ref.read(activeAllergenFiltersProvider).toList();
      return _ref
          .read(catalogRepositoryProvider)
          .search(query, allergens: allergens);
    });
  }
}
