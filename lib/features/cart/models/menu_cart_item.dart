import 'package:app_client/features/catalog/models/menu.dart';
import 'package:app_client/features/catalog/models/product.dart';

class MenuCartSelection {
  const MenuCartSelection({
    required this.groupId,
    required this.groupName,
    required this.product,
    this.selectedVariant,
    this.selectedExtraIds = const {},
    this.quantity = 1,
  });

  final int groupId;
  final String groupName;
  final Product product;
  final ProductVariant? selectedVariant;
  final Set<int> selectedExtraIds;
  final int quantity;

  String get key {
    final extras = ([...selectedExtraIds]..sort()).join(',');
    return '$groupId:${product.id}:${selectedVariant?.id ?? 0}:$extras:$quantity';
  }

  List<String> get optionLabels => [
        if (selectedVariant != null) selectedVariant!.name,
        ...product.extras
            .where((extra) => selectedExtraIds.contains(extra.id))
            .map((extra) => extra.name),
      ];

  Map<String, dynamic> toOrderJson() => {
        'group_id': groupId,
        'product_id': product.id,
        'quantity': quantity,
        if (selectedVariant != null) 'variant_id': selectedVariant!.id,
        if (selectedExtraIds.isNotEmpty)
          'extras': selectedExtraIds
              .map((id) => {'extra_id': id, 'quantity': 1})
              .toList(),
      };
}

class MenuCartItem {
  const MenuCartItem({
    required this.menu,
    required this.selections,
    this.quantity = 1,
  });

  final CatalogMenu menu;
  final List<MenuCartSelection> selections;
  final int quantity;

  String get key {
    final selectionKeys = selections.map((selection) => selection.key).toList()
      ..sort();
    return 'menu:${menu.id}:${selectionKeys.join('|')}';
  }

  double get unitPrice => menu.fixedPrice;
  double get totalPrice => unitPrice * quantity;

  MenuCartItem copyWith({
    CatalogMenu? menu,
    List<MenuCartSelection>? selections,
    int? quantity,
  }) {
    return MenuCartItem(
      menu: menu ?? this.menu,
      selections: selections ?? this.selections,
      quantity: quantity ?? this.quantity,
    );
  }

  Map<String, dynamic> toOrderJson() => {
        'menu_id': menu.id,
        'quantity': quantity,
        'selections':
            selections.map((selection) => selection.toOrderJson()).toList(),
      };
}
