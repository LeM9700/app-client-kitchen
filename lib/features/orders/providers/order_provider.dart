import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_client/core/errors/app_exception.dart';
import 'package:app_client/core/providers/api_client_provider.dart';
import 'package:app_client/features/cart/providers/cart_provider.dart';
import 'package:app_client/features/catalog/models/product.dart';
import 'package:app_client/features/catalog/providers/catalog_provider.dart';
import 'package:app_client/features/orders/models/order.dart';
import 'package:app_client/features/orders/models/reorder_result.dart';
import 'package:app_client/features/orders/repositories/order_repository.dart';

// ─────────────────────────────────────────────────────────────────────────
// Repository provider
// ─────────────────────────────────────────────────────────────────────────

/// Repository commandes — singleton, dépend de [ApiClient]. Réutilisé par le
/// suivi temps réel (`tracking_provider.dart`, ex-`trackingOrderRepositoryProvider`
/// consolidé ici, voir Plan 14→15).
final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepository(ref.read(apiClientProvider));
});

// ─────────────────────────────────────────────────────────────────────────
// Historique paginé — `GET /orders/me`, pagination OFFSET (page/page_size),
// PAS un curseur (voir api-corrections-phase-d.md §5).
// ─────────────────────────────────────────────────────────────────────────

const int _defaultPageSize = 20;

class OrderHistoryState {
  const OrderHistoryState({
    this.orders = const [],
    this.page = 1,
    this.pages = 1,
    this.total = 0,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
  });

  final List<Order> orders;
  final int page;
  final int pages;
  final int total;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;

  /// True si une page supplémentaire existe côté serveur (`page < pages`).
  bool get hasMore => page < pages;
}

final orderHistoryProvider =
    StateNotifierProvider.autoDispose<OrderHistoryNotifier, OrderHistoryState>(
  (ref) => OrderHistoryNotifier(ref.read(orderRepositoryProvider))..refresh(),
);

class OrderHistoryNotifier extends StateNotifier<OrderHistoryState> {
  OrderHistoryNotifier(this._repo) : super(const OrderHistoryState());

  final OrderRepository _repo;

  /// (Re)charge depuis la page 1 — appel initial et pull-to-refresh.
  Future<void> refresh() async {
    state = const OrderHistoryState(isLoading: true);
    try {
      final result =
          await _repo.getMyOrders(page: 1, pageSize: _defaultPageSize);
      state = OrderHistoryState(
        orders: result.items,
        page: result.page,
        pages: result.pages,
        total: result.total,
      );
    } on AppException catch (e) {
      state = OrderHistoryState(error: e.message);
    }
  }

  /// Charge la page suivante et l'ajoute à la liste déjà accumulée.
  /// No-op si un chargement est déjà en cours ou si la dernière page est
  /// déjà atteinte.
  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;

    state = OrderHistoryState(
      orders: state.orders,
      page: state.page,
      pages: state.pages,
      total: state.total,
      isLoadingMore: true,
    );
    try {
      final result = await _repo.getMyOrders(
        page: state.page + 1,
        pageSize: _defaultPageSize,
      );
      state = OrderHistoryState(
        orders: [...state.orders, ...result.items],
        page: result.page,
        pages: result.pages,
        total: result.total,
      );
    } on AppException catch (e) {
      state = OrderHistoryState(
        orders: state.orders,
        page: state.page,
        pages: state.pages,
        total: state.total,
        error: e.message,
      );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Détail commande — `GET /orders/{id}`, sert aussi d'écran reçu (Plan 15).
// ─────────────────────────────────────────────────────────────────────────

/// `.family` par id, `autoDispose` : pas de cache persistant entre deux
/// visites de l'écran (le statut/l'historique ont pu changer entre-temps).
final orderDetailProvider =
    FutureProvider.family.autoDispose<Order, int>((ref, orderId) {
  return ref.read(orderRepositoryProvider).getOrderById(orderId);
});

// ─────────────────────────────────────────────────────────────────────────
// Recommander — orchestration reorder + préremplissage panier (Plan 15,
// voir api-corrections-phase-d.md §5).
// ─────────────────────────────────────────────────────────────────────────

/// Résultat exposé à l'UI après un `reorder()` — [unavailableItems] combine
/// les indisponibilités renvoyées par le serveur ET les échecs de refetch
/// catalogue côté client (produit supprimé entre-temps) : JAMAIS de
/// suppression silencieuse d'un article, toujours remonté à l'utilisateur.
class ReorderOutcome {
  const ReorderOutcome({
    required this.addedCount,
    required this.unavailableItems,
  });

  final int addedCount;
  final List<ReorderItem> unavailableItems;
}

final reorderProvider =
    Provider<ReorderNotifier>((ref) => ReorderNotifier(ref));

/// Orchestration du flow "Recommander" :
/// 1. `POST /orders/{id}/reorder` → payload `items` (disponibles) /
///    `unavailable_items` (indisponibles, avec `warning`).
/// 2. Pour chaque item DISPONIBLE : refetch le [Product] complet via
///    `CatalogRepository.getProduct` (le reorder ne renvoie que des ids —
///    `CartItem` a besoin de l'objet produit complet) et l'ajoute au panier,
///    en faisant correspondre la variante par id.
/// 3. Retourne les items indisponibles (serveur + échecs de refetch) pour
///    affichage explicite par l'écran appelant.
class ReorderNotifier {
  ReorderNotifier(this._ref);
  final Ref _ref;

  Future<ReorderOutcome> reorder(int orderId) async {
    final orderRepo = _ref.read(orderRepositoryProvider);
    final catalogRepo = _ref.read(catalogRepositoryProvider);
    final cartNotifier = _ref.read(cartProvider.notifier);

    final result = await orderRepo.reorder(orderId);

    var addedCount = 0;
    final failedItems = <ReorderItem>[];

    for (final item in result.items) {
      if (!item.available) continue;
      try {
        final product = await catalogRepo.getProduct(item.productId);
        ProductVariant? variant;
        if (item.variantId != null) {
          for (final v in product.variants) {
            if (v.id == item.variantId) {
              variant = v;
              break;
            }
          }
        }
        cartNotifier.addItem(
          product,
          quantity: item.quantity,
          variant: variant,
          extraIds: item.extras.map((e) => e.extraId).toSet(),
        );
        addedCount++;
      } on AppException {
        // Produit introuvable/supprimé entre le moment de la commande
        // d'origine et aujourd'hui — traité comme indisponible plutôt que
        // de faire planter tout le reorder.
        failedItems.add(
          item.copyWith(
            available: false,
            warning: item.warning ?? 'Produit introuvable ou indisponible.',
          ),
        );
      }
    }

    return ReorderOutcome(
      addedCount: addedCount,
      unavailableItems: [...result.unavailableItems, ...failedItems],
    );
  }
}
