import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:app_client/features/cart/models/cart_item.dart';
import 'package:app_client/features/checkout/models/delivery_info.dart';

part 'checkout_state.freezed.dart';

enum CheckoutStep { revalidation, deliveryMode, address, recap }

enum DeliveryMode { delivery, pickup }

/// Alerte affichée à l'étape 0 (revalidation) quand un produit du panier a
/// changé de prix ou de disponibilité entre l'ajout au panier et l'entrée
/// dans le checkout.
@freezed
class PriceAlert with _$PriceAlert {
  const factory PriceAlert({
    required CartItem item,
    required double oldPrice,
    required double newPrice,
    required bool wasAvailable,
    required bool isAvailable,
  }) = _PriceAlert;
}

@freezed
class CheckoutState with _$CheckoutState {
  const factory CheckoutState({
    @Default(CheckoutStep.revalidation) CheckoutStep currentStep,
    @Default(DeliveryMode.delivery) DeliveryMode deliveryMode,
    @Default([]) List<PriceAlert> priceAlerts,
    @Default(false) bool isRevalidating,
    String?
        address, // texte affiché à l'utilisateur — informatif uniquement côté API
    double?
        lat, // [TECH DEBT corrigé] requis par /delivery/check, pas dans le plan initial
    double? lng,
    DeliveryInfo?
        deliveryInfo, // Résultat /delivery/check (null tant que non vérifié)
    double? serverTotal, // Total officiel du serveur
    int? createdOrderId, // [TECH DEBT corrigé] int côté API, pas String
    // [TECH DEBT corrigé] Généré une seule fois (première tentative), pas à chaque appel
    // réseau — sinon un retry après timeout regénère une clé différente et l'API ne peut plus
    // dédupliquer, ce qui ANNULE l'intérêt même de l'Idempotency-Key (double commande possible).
    String? idempotencyKey,
    String? error,
    @Default(false) bool isLoading,
  }) = _CheckoutState;
}
