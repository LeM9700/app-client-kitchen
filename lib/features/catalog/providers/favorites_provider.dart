import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_client/core/errors/app_exception.dart';
import 'package:app_client/core/providers/api_client_provider.dart';
import 'package:app_client/core/providers/auth_token_provider.dart';
import 'package:app_client/features/catalog/models/product.dart';
import 'package:app_client/features/catalog/providers/catalog_provider.dart';
import 'package:app_client/features/catalog/repositories/favorites_repository.dart';

final favoritesRepositoryProvider = Provider<FavoritesRepository>((ref) {
  return FavoritesRepository(ref.read(apiClientProvider));
});

final favoritesProvider = StateNotifierProvider<FavoritesNotifier, Set<int>>(
  (ref) => FavoritesNotifier(ref),
);

final favoriteProductsProvider =
    Provider.autoDispose<AsyncValue<List<Product>>>((ref) {
  final favoriteIds = ref.watch(favoritesProvider);
  final productsAsync = ref.watch(allProductsProvider);

  if (favoriteIds.isEmpty) {
    return const AsyncValue.data([]);
  }

  return productsAsync.whenData(
    (products) => products
        .where((product) => favoriteIds.contains(product.id))
        .toList(growable: false),
  );
});

class FavoritesNotifier extends StateNotifier<Set<int>> {
  FavoritesNotifier(this._ref) : super(const {}) {
    if (_ref.read(accessTokenProvider) != null) {
      _loadFromBackend();
    }
    _ref.listen<String?>(accessTokenProvider, (previous, next) {
      if (previous == null && next != null) {
        _loadFromBackend();
      } else if (previous != null && next == null) {
        state = const {};
      }
    });
  }

  final Ref _ref;

  bool get canMutate => _ref.read(accessTokenProvider) != null;

  bool isFavorite(int productId) => state.contains(productId);

  Future<void> _loadFromBackend() async {
    try {
      final serverIds = await _ref.read(favoritesRepositoryProvider).list();
      state = {...state, ...serverIds};
    } on AppException {
      // The catalog remains usable even if favorites fail to load.
    }
  }

  void toggle(int productId) {
    if (!canMutate) return;

    final adding = !state.contains(productId);
    final updated = Set<int>.from(state);
    adding ? updated.add(productId) : updated.remove(productId);
    state = updated;

    final repo = _ref.read(favoritesRepositoryProvider);
    final syncFuture = adding ? repo.add(productId) : repo.remove(productId);
    syncFuture.catchError((Object _) {
      final reverted = Set<int>.from(state);
      adding ? reverted.remove(productId) : reverted.add(productId);
      state = reverted;
    });
  }
}
