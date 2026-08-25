import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_client/core/errors/app_exception.dart';
import 'package:app_client/core/providers/api_client_provider.dart';
import 'package:app_client/core/providers/auth_token_provider.dart';
import 'package:app_client/features/catalog/repositories/favorites_repository.dart';

/// Repository favoris — singleton, dépend de [ApiClient] (même convention
/// que `loyaltyRepositoryProvider`).
final favoritesRepositoryProvider = Provider<FavoritesRepository>((ref) {
  return FavoritesRepository(ref.read(apiClientProvider));
});

/// Favoris produits — état local synchrone (`Set<int>`, [toggle] optimiste)
/// synchronisé en tâche de fond avec `GET`/`POST`/`DELETE /favorites` quand
/// l'utilisateur est authentifié.
///
/// Anonyme (pas de token) : reste 100% en mémoire pour la session, comme
/// avant — aucune régression du parcours non connecté. Connexion en cours de
/// session : les favoris déjà tapés localement sont conservés et fusionnés
/// avec ceux renvoyés par le serveur (aucune perte silencieuse).
final favoritesProvider = StateNotifierProvider<FavoritesNotifier, Set<int>>(
  (ref) => FavoritesNotifier(ref),
);

class FavoritesNotifier extends StateNotifier<Set<int>> {
  FavoritesNotifier(this._ref) : super(const {}) {
    if (_ref.read(accessTokenProvider) != null) {
      _loadFromBackend();
    }
    _ref.listen<String?>(accessTokenProvider, (previous, next) {
      if (previous == null && next != null) {
        _loadFromBackend();
      }
    });
  }

  final Ref _ref;

  bool isFavorite(int productId) => state.contains(productId);

  /// `GET /favorites` — fusionne avec l'état local courant (union) plutôt que
  /// de l'écraser, pour ne jamais perdre un favori taggué localement avant le
  /// login (anonyme) ou avant la fin du chargement initial.
  Future<void> _loadFromBackend() async {
    try {
      final serverIds = await _ref.read(favoritesRepositoryProvider).list();
      state = {...state, ...serverIds};
    } on AppException {
      // Pas de retry automatique ni d'UI d'erreur ici (pas d'écran dédié) —
      // un prochain login ou toggle manuel resynchronisera.
    }
  }

  /// Bascule l'état local immédiatement (optimiste, synchrone — préserve
  /// l'API existante consommée par [ProductCard]), puis synchronise en tâche
  /// de fond si authentifié. En cas d'échec réseau, revient explicitement à
  /// l'état cohérent avec le serveur (pas de simple "re-toggle", pour rester
  /// correct même si l'utilisateur a retapé entre-temps).
  void toggle(int productId) {
    final adding = !state.contains(productId);
    final updated = Set<int>.from(state);
    adding ? updated.add(productId) : updated.remove(productId);
    state = updated;

    if (_ref.read(accessTokenProvider) == null) return;

    final repo = _ref.read(favoritesRepositoryProvider);
    final syncFuture = adding ? repo.add(productId) : repo.remove(productId);
    syncFuture.catchError((Object _) {
      final reverted = Set<int>.from(state);
      adding ? reverted.remove(productId) : reverted.add(productId);
      state = reverted;
    });
  }
}
