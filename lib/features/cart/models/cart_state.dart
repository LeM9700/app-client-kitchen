import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:app_client/features/cart/models/cart_item.dart';

part 'cart_state.freezed.dart';

/// État du panier — 100% local, aucun appel API tant que le checkout n'est
/// pas lancé (voir décision d'architecture Plan 09).
@freezed
class CartState with _$CartState {
  const factory CartState({
    @Default({}) Map<String, CartItem> items, // key → CartItem
    String? promoCode,
    double? promoDiscount, // Montant de remise (null si pas de promo validée)
    String? promoError,
    @Default(false) bool isValidatingPromo,
  }) = _CartState;

  const CartState._();

  List<CartItem> get itemList => items.values.toList();
  int get totalQuantity => items.values.fold(0, (sum, i) => sum + i.quantity);

  double get subtotal => items.values.fold(0, (sum, i) => sum + i.totalPrice);

  double get total => subtotal - (promoDiscount ?? 0);

  bool get isEmpty => items.isEmpty;
}
