import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_client/core/errors/app_exception.dart';
import 'package:app_client/core/providers/api_client_provider.dart';
import 'package:app_client/features/loyalty/models/loyalty_account.dart';
import 'package:app_client/features/loyalty/models/loyalty_reward.dart';
import 'package:app_client/features/loyalty/models/loyalty_transaction.dart';
import 'package:app_client/features/loyalty/repositories/loyalty_repository.dart';

// ─────────────────────────────────────────────────────────────────────────
// Repository provider
// ─────────────────────────────────────────────────────────────────────────

/// Repository fidélité — singleton, dépend de [ApiClient].
final loyaltyRepositoryProvider = Provider<LoyaltyRepository>((ref) {
  return LoyaltyRepository(ref.read(apiClientProvider));
});

// ─────────────────────────────────────────────────────────────────────────
// Solde — `GET /loyalty/me`. `autoDispose` : pas de cache persistant entre
// deux visites de l'écran, le solde a pu changer (commande passée ailleurs,
// points expirés) — toujours refetch à l'entrée sur l'écran.
// ─────────────────────────────────────────────────────────────────────────

final loyaltyAccountProvider =
    FutureProvider.autoDispose<LoyaltyAccount>((ref) {
  return ref.read(loyaltyRepositoryProvider).getAccount();
});

// ─────────────────────────────────────────────────────────────────────────
// Catalogue de récompenses — `GET /loyalty/rewards`. Réinvalidé avec le
// solde après un échange réussi (voir [LoyaltyRedeemNotifier]) : `canRedeem`/
// `missingPoints` dépendent du solde courant et doivent rester cohérents
// avec [loyaltyAccountProvider] après un redeem.
// ─────────────────────────────────────────────────────────────────────────

final loyaltyRewardsProvider =
    FutureProvider.autoDispose<List<LoyaltyReward>>((ref) {
  return ref.read(loyaltyRepositoryProvider).getRewards();
});

// ─────────────────────────────────────────────────────────────────────────
// Historique des transactions — `GET /loyalty/transactions`, pagination
// OFFSET par `page`/`limit` (PAS `page_size`, pas de champ `pages` — voir
// `LoyaltyTransactionPage.hasMore`, calculé côté client). Même structure
// que `OrderHistoryNotifier` (`features/orders/providers/order_provider.dart`)
// à la forme de pagination près.
// ─────────────────────────────────────────────────────────────────────────

const int _defaultTransactionsLimit = 20;

class LoyaltyTransactionsState {
  const LoyaltyTransactionsState({
    this.transactions = const [],
    this.page = 1,
    this.limit = _defaultTransactionsLimit,
    this.total = 0,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
  });

  final List<LoyaltyTransaction> transactions;
  final int page;
  final int limit;
  final int total;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;

  /// True si une page supplémentaire existe côté serveur — calculé
  /// (`page * limit < total`) car l'API ne renvoie pas de champ `pages`
  /// pour cette pagination.
  bool get hasMore => page * limit < total;
}

final loyaltyTransactionsProvider = StateNotifierProvider.autoDispose<
    LoyaltyTransactionsNotifier, LoyaltyTransactionsState>(
  (ref) => LoyaltyTransactionsNotifier(ref.read(loyaltyRepositoryProvider))
    ..refresh(),
);

class LoyaltyTransactionsNotifier
    extends StateNotifier<LoyaltyTransactionsState> {
  LoyaltyTransactionsNotifier(this._repo)
      : super(const LoyaltyTransactionsState());

  final LoyaltyRepository _repo;

  /// (Re)charge depuis la page 1 — appel initial et pull-to-refresh.
  Future<void> refresh() async {
    state = const LoyaltyTransactionsState(isLoading: true);
    try {
      final result = await _repo.getTransactions(
        page: 1,
        limit: _defaultTransactionsLimit,
      );
      state = LoyaltyTransactionsState(
        transactions: result.items,
        page: result.page,
        limit: result.limit,
        total: result.total,
      );
    } on AppException catch (e) {
      state = LoyaltyTransactionsState(error: e.message);
    }
  }

  /// Charge la page suivante et l'ajoute à la liste déjà accumulée. No-op si
  /// un chargement est déjà en cours ou si la dernière page est atteinte.
  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;

    state = LoyaltyTransactionsState(
      transactions: state.transactions,
      page: state.page,
      limit: state.limit,
      total: state.total,
      isLoadingMore: true,
    );
    try {
      final result = await _repo.getTransactions(
        page: state.page + 1,
        limit: state.limit,
      );
      state = LoyaltyTransactionsState(
        transactions: [...state.transactions, ...result.items],
        page: result.page,
        limit: result.limit,
        total: result.total,
      );
    } on AppException catch (e) {
      state = LoyaltyTransactionsState(
        transactions: state.transactions,
        page: state.page,
        limit: state.limit,
        total: state.total,
        error: e.message,
      );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Échange de récompense — `POST /loyalty/rewards/{reward_id}/redeem`.
// [Décision d'architecture n°1, plan-16] L'échange est déclenché et validé
// côté serveur — ce notifier ne fait qu'appeler le repository et refetch le
// solde/catalogue, jamais de validation de points côté client.
// ─────────────────────────────────────────────────────────────────────────

final loyaltyRedeemProvider =
    Provider<LoyaltyRedeemNotifier>((ref) => LoyaltyRedeemNotifier(ref));

/// Orchestration du flow "Échanger une récompense" :
/// 1. `POST /loyalty/rewards/{reward_id}/redeem`.
/// 2. Sur succès : réinvalide [loyaltyAccountProvider] ET
///    [loyaltyRewardsProvider] pour que le solde affiché ET l'état
///    grisé/disponible des autres récompenses reflètent immédiatement le
///    nouveau solde (DoD plan-16 : "Échange réussi → solde mis à jour
///    immédiatement").
/// 3. Sur erreur (ex. `ValidationException` 422 `INSUFFICIENT_POINTS`) :
///    propage l'[AppException] telle quelle, laissée à l'écran appelant
///    (BottomSheet de confirmation) pour affichage — pas de solde ré-fetché
///    puisque rien n'a changé côté serveur.
class LoyaltyRedeemNotifier {
  LoyaltyRedeemNotifier(this._ref);
  final Ref _ref;

  Future<RedeemResult> redeem(int rewardId) async {
    final repo = _ref.read(loyaltyRepositoryProvider);
    final result = await repo.redeemReward(rewardId);
    _ref.invalidate(loyaltyAccountProvider);
    _ref.invalidate(loyaltyRewardsProvider);
    return result;
  }
}
