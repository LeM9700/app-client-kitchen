import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:app_client/core/analytics/analytics_reporter.dart';
import 'package:app_client/core/errors/app_exception.dart';
import 'package:app_client/core/providers/api_client_provider.dart';
import 'package:app_client/features/cart/providers/cart_provider.dart';
import 'package:app_client/features/catalog/providers/catalog_provider.dart';
import 'package:app_client/features/catalog/repositories/catalog_repository.dart';
import 'package:app_client/features/checkout/models/checkout_state.dart';
import 'package:app_client/features/checkout/providers/client_location_provider.dart';
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

  /// Verifie la zone du point [lat]/[lng] et calcule les frais pour le panier courant.
  ///
  /// [advance] = `true` (bouton « Continuer ») : en cas de succes, memorise l'adresse et passe
  /// au recapitulatif. `false` (apercu des que le client place son repere) : n'affiche que le
  /// resultat (zone, frais, delai) sans changer d'etape ni memoriser l'adresse.
  Future<void> checkDeliveryAddress({
    required String displayAddress,
    required double lat,
    required double lng,
    String? phone,
    String? instructions,
    bool advance = true,
  }) async {
    state = state.copyWith(isLoading: true, error: null, errorCode: null);
    try {
      final info = await _checkoutRepo.checkDeliveryZone(
        lat: lat,
        lng: lng,
        displayAddress: displayAddress,
        subtotal: _ref.read(cartProvider).subtotal,
      );
      _ref.read(analyticsReporterProvider).track(
        'checkout_delivery_zone_checked',
        {
          'deliverable': true,
          'zone_id': info.zoneId,
          'fee': info.fee,
        },
      );
      if (info.minOrderMet == false) {
        // Dans la zone mais panier trop petit : on garde le resultat (l'ecran affiche le
        // minimum a atteindre) sans avancer.
        state = state.copyWith(
          isLoading: false,
          lat: lat,
          lng: lng,
          deliveryInfo: info,
          error: 'Minimum de commande non atteint pour cette zone.',
          errorCode: 'DELIVERY_MIN_ORDER_NOT_MET',
        );
        return;
      }
      state = state.copyWith(
        isLoading: false,
        address: advance ? displayAddress : state.address,
        lat: lat,
        lng: lng,
        phone: phone ?? state.phone,
        instructions: instructions ?? state.instructions,
        deliveryInfo: info,
        currentStep: advance ? CheckoutStep.recap : state.currentStep,
      );
      if (advance) {
        _ref.read(clientLocationProvider.notifier).state = ClientLocation(
          address: displayAddress,
          lat: lat,
          lng: lng,
        );
      }
    } on DeliveryZoneUnreachableException {
      // [TECH DEBT corrigé] Pas de champ `deliverable` — l'API répond 422
      // DELIVERY_ZONE_UNREACHABLE quand aucune zone ne couvre le point. Traduit ici en état UX.
      _ref.read(analyticsReporterProvider).track(
        'checkout_delivery_zone_checked',
        {'deliverable': false},
      );
      state = state.copyWith(
        isLoading: false,
        deliveryInfo: null,
        error:
            'Adresse hors zone de livraison. Choisissez le retrait en boutique.',
        errorCode: 'DELIVERY_ZONE_UNREACHABLE',
      );
    } on AppException catch (e) {
      _ref.read(analyticsReporterProvider).track(
        'checkout_delivery_zone_failed',
        {'error_type': e.runtimeType.toString()},
      );
      state = state.copyWith(
        isLoading: false,
        deliveryInfo: null,
        error: e.message,
        errorCode: e is DeliveryException ? e.code : null,
      );
    }
  }

  // ── Étape 3 : Récapitulatif + création commande ───────────────────────────

  Future<int?> createOrder() async {
    if (state.isLoading) return null;

    // [TECH DEBT corrigé] La clé est générée une seule fois et réutilisée à chaque tentative —
    // voir la note sur CheckoutState.idempotencyKey.
    final idempotencyKey = state.idempotencyKey ?? const Uuid().v4();
    state = state.copyWith(
      isLoading: true,
      error: null,
      errorCode: null,
      idempotencyKey: idempotencyKey,
    );
    try {
      final cart = _ref.read(cartProvider);
      final isDelivery = state.deliveryMode == DeliveryMode.delivery;
      final orderId = await _checkoutRepo.createOrder(
        items: cart.itemList,
        orderType: isDelivery ? 'delivery' : 'pickup',
        deliveryAddress: state.address,
        deliveryZoneId: state.deliveryInfo?.zoneId,
        // L'etablissement dont la zone couvre l'adresse ; le serveur le recalcule.
        establishmentId: isDelivery ? state.deliveryInfo?.establishmentId : null,
        // Retrait : aucune donnee de livraison n'est envoyee.
        deliveryLat: isDelivery ? state.lat : null,
        deliveryLng: isDelivery ? state.lng : null,
        customerPhone: isDelivery ? state.phone : null,
        deliveryInstructions: isDelivery ? state.instructions : null,
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
      state = state.copyWith(
        isLoading: false,
        error: e.message,
        errorCode: e is DeliveryException ? e.code : null,
      );
      return null;
    }
  }
}
