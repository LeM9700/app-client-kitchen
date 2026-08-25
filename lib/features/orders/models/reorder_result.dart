import 'package:freezed_annotation/freezed_annotation.dart';

part 'reorder_result.freezed.dart';
part 'reorder_result.g.dart';

/// Extra à réappliquer sur un article de reorder (`OrderItemExtraCreate`
/// côté backend — même forme que celle envoyée à `POST /orders`, PAS
/// `OrderItemExtraOut` : seulement `extra_id`/`quantity`, pas de
/// `name`/`unit_price`/`total`, voir `orders/schemas.py`).
@freezed
class ReorderItemExtra with _$ReorderItemExtra {
  const factory ReorderItemExtra({
    @JsonKey(name: 'extra_id') required int extraId,
    @Default(1) int quantity,
  }) = _ReorderItemExtra;

  factory ReorderItemExtra.fromJson(Map<String, dynamic> json) =>
      _$ReorderItemExtraFromJson(json);
}

/// Un article de la commande source à reproduire (`ReorderItemOut`).
///
/// [🔒 api-corrections-phase-d.md §5] `available`/`warning` sont calculés
/// côté serveur (stock, produit désactivé/supprimé, etc.) — ne JAMAIS
/// recalculer la disponibilité côté client, toujours utiliser ces champs
/// tels quels.
@freezed
class ReorderItem with _$ReorderItem {
  const factory ReorderItem({
    @JsonKey(name: 'product_id') required int productId,
    @JsonKey(name: 'variant_id') int? variantId,
    required int quantity,
    @Default([]) List<ReorderItemExtra> extras,
    @Default(true) bool available,
    String? warning,
  }) = _ReorderItem;

  factory ReorderItem.fromJson(Map<String, dynamic> json) =>
      _$ReorderItemFromJson(json);
}

/// Réponse de `POST /orders/{id}/reorder` (`ReorderOut`).
///
/// [🔒 api-corrections-phase-d.md §5] Cet appel NE CRÉE PAS de commande —
/// il retourne un payload de préremplissage panier avec les prix/la
/// disponibilité actuels du catalogue. L'orchestration (fetch produit +
/// ajout panier) vit dans `OrderProvider`/`ReorderNotifier`, pas ici.
@freezed
class ReorderResult with _$ReorderResult {
  const factory ReorderResult({
    @JsonKey(name: 'source_order_id') required int sourceOrderId,
    required List<ReorderItem> items,
    @JsonKey(name: 'unavailable_items')
    @Default([])
    List<ReorderItem> unavailableItems,
  }) = _ReorderResult;

  factory ReorderResult.fromJson(Map<String, dynamic> json) =>
      _$ReorderResultFromJson(json);
}
