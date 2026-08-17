import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Favoris produits — 100% en mémoire pour cette v1 (même convention que
/// [CartState] pour le panier, voir `features/cart/providers/cart_provider.dart`).
/// Non persisté entre sessions : aucun backend favoris n'existe aujourd'hui
/// (vérifié, aucun module `favorites`/`wishlist` côté `api-pizza`) — la
/// persistance cross-session est un chantier séparé.
final favoritesProvider = StateNotifierProvider<FavoritesNotifier, Set<int>>(
  (ref) => FavoritesNotifier(),
);

class FavoritesNotifier extends StateNotifier<Set<int>> {
  FavoritesNotifier() : super(const {});

  bool isFavorite(int productId) => state.contains(productId);

  void toggle(int productId) {
    final updated = Set<int>.from(state);
    if (!updated.remove(productId)) {
      updated.add(productId);
    }
    state = updated;
  }
}
