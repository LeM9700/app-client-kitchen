import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_client/core/providers/api_client_provider.dart';
import 'package:app_client/features/cart/models/cart_item.dart';
import 'package:app_client/features/cart/models/cart_state.dart';
import 'package:app_client/features/cart/repositories/promo_repository.dart';
import 'package:app_client/features/catalog/models/product.dart';

// ──────────────────────────────────────────────────────────────────────────────
// Repository provider
// ──────────────────────────────────────────────────────────────────────────────

/// Repository promo/fidélité — singleton, dépend de [ApiClient].
final promoRepositoryProvider = Provider<PromoRepository>((ref) {
  return PromoRepository(ref.read(apiClientProvider));
});

// ──────────────────────────────────────────────────────────────────────────────
// Aperçu fidélité
// ──────────────────────────────────────────────────────────────────────────────

/// Aperçu des points fidélité gagnés pour un montant de commande donné
/// (`GET /loyalty/preview?order_total=`). `.family` par montant + `autoDispose`
/// : pas de cache persistant, revalidé à chaque changement du sous-total
/// (voir [CartScreen], appelé uniquement si l'utilisateur est connecté).
final loyaltyPreviewProvider =
    FutureProvider.family.autoDispose<LoyaltyPointsPreview, double>(
  (ref, orderTotal) {
    return ref.read(promoRepositoryProvider).previewLoyaltyPoints(orderTotal);
  },
);

// ──────────────────────────────────────────────────────────────────────────────
// Panier
// ──────────────────────────────────────────────────────────────────────────────

final cartProvider = StateNotifierProvider<CartNotifier, CartState>(
  (ref) => CartNotifier(),
);

/// Panier 100% local (voir décision d'architecture Plan 09) : items,
/// quantités, variantes et extras vivent en mémoire, aucun appel API avant
/// le checkout. Le serveur recalcule tout au moment du `POST /orders`.
class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(const CartState());

  /// Ajoute [product] au panier. Si un item avec la même [CartItem.key]
  /// (produit + variante + extras) existe déjà, incrémente sa quantité au
  /// lieu de créer une nouvelle ligne.
  void addItem(
    Product product, {
    int quantity = 1,
    ProductVariant? variant,
    Set<int> extraIds = const {},
  }) {
    final item = CartItem(
      product: product,
      quantity: quantity,
      selectedVariant: variant,
      selectedExtraIds: extraIds,
    );
    final key = item.key;
    final existing = state.items[key];

    state = state.copyWith(
      items: {
        ...state.items,
        key: existing != null
            ? existing.copyWith(quantity: existing.quantity + quantity)
            : item,
      },
    );
  }

  void removeItem(String key) {
    final updated = Map<String, CartItem>.from(state.items)..remove(key);
    state = state.copyWith(items: updated);
  }

  /// Met à jour la quantité de l'item de clé [key]. Supprime l'item si
  /// [quantity] <= 0.
  void updateQuantity(String key, int quantity) {
    if (quantity <= 0) {
      removeItem(key);
      return;
    }
    final item = state.items[key];
    if (item == null) return;
    state = state.copyWith(
      items: {...state.items, key: item.copyWith(quantity: quantity)},
    );
  }

  void clear() => state = const CartState();

  void setPromoResult({required double discount, required String code}) {
    state = state.copyWith(
      promoCode: code,
      promoDiscount: discount,
      promoError: null,
    );
  }

  void setPromoError(String error) {
    state = state.copyWith(
      promoCode: null,
      promoDiscount: null,
      promoError: error,
    );
  }

  void setValidatingPromo(bool value) {
    state = state.copyWith(isValidatingPromo: value);
  }
}
