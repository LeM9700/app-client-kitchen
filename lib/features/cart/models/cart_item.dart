import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:app_client/features/catalog/models/product.dart';

part 'cart_item.freezed.dart';

/// Article du panier : produit + quantité + variante/extras sélectionnés.
///
/// [🔒 CORRECTIF] Le modèle [Product] réel (`lib/features/catalog/models/product.dart`)
/// utilise des `id` en `int` (alignés sur l'API api-pizza) et un prix de base
/// `product.price` (mappé depuis `base_price`, pas de champ `basePrice`).
@freezed
class CartItem with _$CartItem {
  const factory CartItem({
    required Product product,
    required int quantity,
    ProductVariant? selectedVariant,
    @Default({}) Set<int> selectedExtraIds,
  }) = _CartItem;

  const CartItem._();

  /// Clé d'unicité : produit + variante + extras (triés pour déterminisme).
  ///
  /// Deux configurations différentes du même produit (variante et/ou extras
  /// distincts) doivent produire deux clés distinctes, donc deux lignes
  /// panier séparées.
  String get key {
    final variantPart = selectedVariant?.id.toString() ?? 'default';
    final extrasPart = ([...selectedExtraIds]..sort()).join(',');
    return '${product.id}:$variantPart:$extrasPart';
  }

  /// Prix unitaire = prix de base du produit + delta variante + extras sélectionnés.
  double get unitPrice {
    double price = product.price;
    if (selectedVariant != null) price += selectedVariant!.priceDelta;
    for (final extra in product.extras) {
      if (selectedExtraIds.contains(extra.id)) price += extra.price;
    }
    return price;
  }

  double get totalPrice => unitPrice * quantity;
}
