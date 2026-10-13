import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:app_client/features/cart/models/cart_item.dart';
import 'package:app_client/features/cart/models/menu_cart_item.dart';

part 'cart_state.freezed.dart';

/// État du panier — 100% local, aucun appel API tant que le checkout n'est
/// pas lancé (voir décision d'architecture Plan 09).
@freezed
class CartState with _$CartState {
  const factory CartState({
    @Default({}) Map<String, CartItem> items, // key → CartItem
    @Default({}) Map<String, MenuCartItem> menuItems,
    String? promoCode,
    double? promoDiscount, // Montant de remise (null si pas de promo validée)
    String? promoError,
    @Default(false)
    bool promoFreeDelivery, // Le code promo valide offre la livraison
    @Default(false) bool isValidatingPromo,
  }) = _CartState;

  const CartState._();

  List<CartItem> get itemList => items.values.toList();
  List<MenuCartItem> get menuItemList => menuItems.values.toList();
  int get totalQuantity =>
      items.values.fold(0, (sum, item) => sum + item.quantity) +
      menuItems.values.fold(0, (sum, item) => sum + item.quantity);

  double get subtotal =>
      items.values.fold(0.0, (sum, item) => sum + item.totalPrice) +
      menuItems.values.fold(0.0, (sum, item) => sum + item.totalPrice);

  double get total => subtotal - (promoDiscount ?? 0);

  bool get isEmpty => items.isEmpty && menuItems.isEmpty;
}
