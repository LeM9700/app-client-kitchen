import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:app_client/core/analytics/analytics_reporter.dart';
import 'package:app_client/core/errors/app_exception.dart';
import 'package:app_client/core/providers/api_client_provider.dart';
import 'package:app_client/features/cart/providers/cart_provider.dart';
import 'package:app_client/features/catalog/providers/catalog_provider.dart';
import 'package:app_client/features/catalog/repositories/catalog_repository.dart';
import 'package:app_client/features/checkout/models/checkout_state.dart';
import 'package:app_client/features/checkout/repositories/checkout_repository.dart';

// ──────────────────────────────────────────────────────────────────────────────
// Repository provider
// ──────────────────────────────────────────────────────────────────────────────

/// Repository checkout — singleton, dépend de [ApiClient].
final checkoutRepositoryProvider = Provider<CheckoutRepository>((ref) {
  return CheckoutRepository(ref.read(apiClientProvider));
});

// ──────────────────────────────────────────────────────────────────────────────
// Notifier
// ──────────────────────────────────────────────────────────────────────────────

final checkoutProvider =
    StateNotifierProvider.autoDispose<CheckoutNotifier, CheckoutState>(
  (ref) => CheckoutNotifier(
    ref.read(checkoutRepositoryProvider),
    ref.read(catalogRepositoryProvider),
    ref,
  ),
);

class CheckoutNotifier extends StateNotifier<CheckoutState> {
  CheckoutNotifier(this._checkoutRepo, this._catalogRepo, this._ref)
      : super(const CheckoutState());

  final CheckoutRepository _checkoutRepo;
  final CatalogRepository _catalogRepo;
  final Ref _ref;

  // ── Étape 0 : Revalidation ────────────────────────────────────────────────

  Future<void> revalidateCart() async {
    state = state.copyWith(isRevalidating: true, error: null);

    final cartItems = _ref.read(cartProvider).itemList;
    final alerts = <PriceAlert>[];

    for (final item in cartItems) {
      try {
        // [🔒 CORRECTIF] Le nom réel de la méthode de repository est
        // `getProduct` (pas `getProductById` comme le plan initial le
        // supposait) — voir `catalog_repository.dart`.
        final fresh = await _catalogRepo.getProduct(item.product.id);
        final oldPrice = item.unitPrice;
        final newItem = item.copyWith(product: fresh);
        final newPrice = newItem.unitPrice;

        // [TECH DEBT corrigé] product.available n'existe plus — c'est product.isAvailable
        // (champ direct dérivé de `is_active`, voir `Product`).
        if (oldPrice != newPrice ||
            item.product.isAvailable != fresh.isAvailable) {
          alerts.add(
            PriceAlert(
              item: item,
              oldPrice: oldPrice,
              newPrice: newPrice,
              wasAvailable: item.product.isAvailable,
              isAvailable: fresh.isAvailable,
            ),
          );

          // [🔒 CORRECTIF] Le plan suggérait `addItem(fresh, quantity: 0, ...)` pour
          // "remplacer sans ajouter" — mais `CartNotifier.addItem` fusionne sur un item
          // existant via `existing.copyWith(quantity: existing.quantity + quantity)`,
          // qui préserve `existing.product` (l'ANCIEN produit) et ignore le `product`
          // passé en paramètre. Avec quantity: 0 la quantité ne change pas non plus, donc
          // l'appel ne mettait à jour ni le prix ni la disponibilité affichés dans le
          // panier — l'alerte aurait été affichée mais jamais reflétée dans l'état réel.
          // `CartItem.key` ne dépend que de `product.id`/variante/extras (pas du prix),
          // donc retirer puis rajouter avec la même quantité reconstruit la ligne à la
          // même clé, avec les données produit à jour.
          _ref.read(cartProvider.notifier).removeItem(item.key);
          _ref.read(cartProvider.notifier).addItem(
                fresh,
                quantity: item.quantity,
                variant: item.selectedVariant,
                extraIds: item.selectedExtraIds,
              );
        }
      } catch (_) {
        // Si le produit est introuvable, on laisse la commande continuer
        // Le serveur rejettera l'item invalide au POST /orders
      }
    }

    state = state.copyWith(
      isRevalidating: false,
      priceAlerts: alerts,
      // On passe à l'étape suivante dans l'UI si pas d'alertes
      currentStep: alerts.isEmpty
          ? CheckoutStep.deliveryMode
          : CheckoutStep.revalidation,
    );
  }

  void dismissAlertsAndContinue() {
    state = state.copyWith(
      priceAlerts: [],
      currentStep: CheckoutStep.deliveryMode,
    );
  }

  // ── Étape 1 : Mode de livraison ───────────────────────────────────────────

  void selectDeliveryMode(DeliveryMode mode) {
    state = state.copyWith(
      deliveryMode: mode,
      currentStep: mode == DeliveryMode.pickup
          ? CheckoutStep.recap // Pickup → pas d'étape adresse
          : CheckoutStep.address,
    );
    _ref.read(analyticsReporterProvider).track(
      'checkout_delivery_mode_selected',
      {'mode': mode.name},
    );
  }

  // ── Étape 2 : Adresse + vérification de zone ─────────────────────────────
  // [TECH DEBT corrigé] lat/lng (obtenus par sélection sur carte en amont dans
  // step_address.dart — voir la décision d'architecture révisée) au lieu d'une adresse texte
  // brute que l'API ne sait pas interpréter.

  Future<void> checkDeliveryAddress({
    required String displayAddress,
    required double lat,
    required double lng,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final info = await _checkoutRepo.checkDeliveryZone(
        lat: lat,
        lng: lng,
        displayAddress: displayAddress,
      );
      _ref.read(analyticsReporterProvider).track(
        'checkout_delivery_zone_checked',
        {
          'deliverable': true,
          'zone_id': info.zoneId,
          'fee': info.fee,
        },
      );
      state = state.copyWith(
        isLoading: false,
        address: displayAddress,
        lat: lat,
        lng: lng,
        deliveryInfo: info,
        currentStep: CheckoutStep.recap,
      );
    } on DeliveryZoneUnreachableException {
      // [TECH DEBT corrigé] Pas de champ `deliverable` — l'API répond 422
      // DELIVERY_ZONE_UNREACHABLE quand aucune zone ne couvre le point. Traduit ici en état UX.
      _ref.read(analyticsReporterProvider).track(
        'checkout_delivery_zone_checked',
        {'deliverable': false},
      );
      state = state.copyWith(
        isLoading: false,
        error:
            'Adresse hors zone de livraison. Choisissez le retrait en boutique.',
      );
    } on AppException catch (e) {
      _ref.read(analyticsReporterProvider).track(
        'checkout_delivery_zone_failed',
        {'error_type': e.runtimeType.toString()},
      );
      state = state.copyWith(isLoading: false, error: e.message);
    }
  }

  // ── Étape 3 : Récapitulatif + création commande ───────────────────────────

  Future<int?> createOrder() async {
    // [TECH DEBT corrigé] La clé est générée une seule fois et réutilisée à chaque tentative —
    // voir la note sur CheckoutState.idempotencyKey.
    final idempotencyKey = state.idempotencyKey ?? const Uuid().v4();
    state = state.copyWith(
      isLoading: true,
      error: null,
      idempotencyKey: idempotencyKey,
    );
    try {
      final cart = _ref.read(cartProvider);
      final orderId = await _checkoutRepo.createOrder(
        items: cart.itemList,
        orderType:
            state.deliveryMode == DeliveryMode.delivery ? 'delivery' : 'pickup',
        deliveryAddress: state.address,
        deliveryZoneId: state.deliveryInfo?.zoneId,
        promoCode: cart.promoCode,
        idempotencyKey: idempotencyKey,
      );
      _ref.read(analyticsReporterProvider).track(
        'checkout_order_created',
        {
          'order_id': orderId,
          'order_type': state.deliveryMode.name,
          'item_count': cart.totalQuantity,
          'estimated_total': cart.total,
        },
      );
      state = state.copyWith(isLoading: false, createdOrderId: orderId);
      return orderId;
    } on AppException catch (e) {
      _ref.read(analyticsReporterProvider).track(
        'checkout_order_failed',
        {'error_type': e.runtimeType.toString()},
      );
      state = state.copyWith(isLoading: false, error: e.message);
      return null;
    }
  }
}
