import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:app_client/features/tracking/models/order_status.dart';

part 'order.freezed.dart';
part 'order.g.dart';

// ─────────────────────────────────────────────────────────────────────────
// Conversions manuelles (voir `product.dart::_allergensFromJson` pour le
// même pattern déjà établi dans ce module) — le paramètre est nullable pour
// les champs `@Default(...)`, json_serializable appelle le convertisseur
// même quand la clé est absente du JSON.
// ─────────────────────────────────────────────────────────────────────────

/// Type de commande (`OrderCreate.order_type`, ajouté backend Plan 10, voir
/// consigne de session). Défaut `delivery` si absent (rétrocompatibilité
/// avec des commandes créées avant l'ajout de ce champ).
enum OrderType { delivery, pickup }

OrderType _orderTypeFromApi(String? value) => switch (value) {
      'pickup' => OrderType.pickup,
      _ => OrderType.delivery,
    };

String _orderTypeToApi(OrderType type) => switch (type) {
      OrderType.pickup => 'pickup',
      OrderType.delivery => 'delivery',
    };

/// [🔒 Consolidation Plan 14→15] `status` réutilise [OrderStatusCode] (8
/// valeurs réelles, voir `features/tracking/models/order_status.dart`) —
/// PAS de second enum de statut dupliqué pour l'historique/le reçu.
OrderStatusCode _statusFromApi(String value) => orderStatusFromApi(value);
String _statusToApi(OrderStatusCode status) => status.apiValue;

// ─────────────────────────────────────────────────────────────────────────
// Modèles
// ─────────────────────────────────────────────────────────────────────────

/// Extra appliqué à un article de commande (`OrderItemExtraOut` —
/// api-pizza/app/modules/orders/schemas.py). Prix figé au moment de la
/// commande, pas une référence live à `ProductExtra` du catalogue.
@freezed
class OrderItemExtra with _$OrderItemExtra {
  const factory OrderItemExtra({
    @JsonKey(name: 'extra_id') required int extraId,
    required String name,
    required int quantity,
    @JsonKey(name: 'unit_price') required double unitPrice,
    required double total,
  }) = _OrderItemExtra;

  factory OrderItemExtra.fromJson(Map<String, dynamic> json) =>
      _$OrderItemExtraFromJson(json);
}

/// Article d'une commande (`OrderItemOut`) — `productName`/`variantName`
/// sont des libellés figés au moment de la commande (le produit source du
/// catalogue a pu changer de nom ou disparaître depuis), à ne pas confondre
/// avec un `Product` du catalogue.
@freezed
class OrderItem with _$OrderItem {
  const factory OrderItem({
    required int id,
    @JsonKey(name: 'product_id') required int productId,
    @JsonKey(name: 'variant_id') int? variantId,
    @JsonKey(name: 'product_name') String? productName,
    @JsonKey(name: 'variant_name') String? variantName,
    required int quantity,
    @JsonKey(name: 'unit_price') required double unitPrice,
    @JsonKey(name: 'extras_total') @Default(0) double extrasTotal,
    required double total,
    @Default([]) List<OrderItemExtra> extras,
  }) = _OrderItem;

  factory OrderItem.fromJson(Map<String, dynamic> json) =>
      _$OrderItemFromJson(json);
}

/// Entrée d'historique de statut (`OrderStatusHistoryOut`) — affichée sur
/// l'écran reçu (Plan 15), distincte du suivi temps réel (Plan 14) qui
/// n'affiche que le statut courant.
@freezed
class OrderStatusHistoryEntry with _$OrderStatusHistoryEntry {
  const factory OrderStatusHistoryEntry({
    @JsonKey(fromJson: _statusFromApi, toJson: _statusToApi)
    required OrderStatusCode status,
    String? note,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _OrderStatusHistoryEntry;

  factory OrderStatusHistoryEntry.fromJson(Map<String, dynamic> json) =>
      _$OrderStatusHistoryEntryFromJson(json);
}

/// Commande — modélise `OrderDetailOut` (`OrderListOut` + `items` +
/// `status_history` + `user_id` + `promo_code`, voir
/// `api-pizza/app/modules/orders/schemas.py`).
///
/// [Consolidation Plan 14→15, voir api-corrections-phase-d.md §5] Un seul
/// modèle `Order`, réutilisé pour TROIS usages plutôt qu'un modèle par
/// écran :
/// - `GET /orders/me` (liste paginée) — chaque item du JSON n'a QUE les
///   champs `OrderListOut` : `items`/`statusHistory` restent `[]`,
///   `userId`/`promoCode` restent `null` (absents du payload liste, jamais
///   volontairement omis par ce modèle).
/// - `GET /orders/{id}` (détail complet, écran reçu).
/// - Refetch de suivi temps réel (remplace l'ex-`TrackedOrder` du Plan 14) —
///   seuls `id`, `status`, `estimatedDeliveryAt`, `createdAt` sont lus par
///   ce flow, le reste de la réponse est ignoré par l'UI de suivi.
@freezed
class Order with _$Order {
  const factory Order({
    required int id,
    @JsonKey(name: 'customer_email') String? customerEmail,
    @JsonKey(
      name: 'order_type',
      fromJson: _orderTypeFromApi,
      toJson: _orderTypeToApi,
    )
    @Default(OrderType.delivery)
    OrderType orderType,
    @JsonKey(fromJson: _statusFromApi, toJson: _statusToApi)
    required OrderStatusCode status,
    @JsonKey(name: 'payment_status') @Default('pending') String paymentStatus,
    required double subtotal,
    @JsonKey(name: 'discount_total') required double discountTotal,
    @JsonKey(name: 'delivery_fee') required double deliveryFee,
    required double total,
    @JsonKey(name: 'delivery_address') String? deliveryAddress,
    @JsonKey(name: 'delivery_zone_id') int? deliveryZoneId,
    @JsonKey(name: 'estimated_delivery_at') DateTime? estimatedDeliveryAt,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'user_id') int? userId,
    @JsonKey(name: 'promo_code') String? promoCode,
    @Default([]) List<OrderItem> items,
    @JsonKey(name: 'status_history')
    @Default([])
    List<OrderStatusHistoryEntry> statusHistory,
  }) = _Order;

  const Order._();

  factory Order.fromJson(Map<String, dynamic> json) => _$OrderFromJson(json);

  /// Raccourci vers [OrderStatusCodeX.isTerminal] — utilisé par le suivi
  /// temps réel (reconnexion WS/polling) et par l'historique (afficher ou
  /// non le lien "Suivi live").
  bool get isTerminal => status.isTerminal;
}
