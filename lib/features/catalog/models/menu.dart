import 'package:app_client/features/catalog/models/product.dart';

class CatalogMenu {
  const CatalogMenu({
    required this.id,
    required this.name,
    required this.fixedPrice,
    required this.displayOrder,
    required this.groups,
    required this.isAvailable,
    required this.unavailableReasons,
    this.description,
    this.imageUrl,
    this.availableFrom,
    this.availableUntil,
  });

  final int id;
  final String name;
  final String? description;
  final double fixedPrice;
  final String? imageUrl;
  final int displayOrder;
  final DateTime? availableFrom;
  final DateTime? availableUntil;
  final List<CatalogMenuGroup> groups;
  final bool isAvailable;
  final List<String> unavailableReasons;

  factory CatalogMenu.fromJson(Map<String, dynamic> json) {
    return CatalogMenu(
      id: _int(json['id']),
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      fixedPrice: _double(json['fixed_price']),
      imageUrl: json['image_url']?.toString(),
      displayOrder: _int(json['display_order']),
      availableFrom: _date(json['available_from']),
      availableUntil: _date(json['available_until']),
      groups: (json['groups'] as List? ?? const [])
          .whereType<Map>()
          .map(
            (value) => CatalogMenuGroup.fromJson(
              Map<String, dynamic>.from(value),
            ),
          )
          .toList(),
      isAvailable: json['is_available'] == true,
      unavailableReasons: (json['unavailable_reasons'] as List? ?? const [])
          .map((value) => value.toString())
          .toList(),
    );
  }
}

class CatalogMenuGroup {
  const CatalogMenuGroup({
    required this.id,
    required this.name,
    required this.minChoices,
    required this.maxChoices,
    required this.displayOrder,
    required this.products,
    required this.isAvailable,
    this.unavailableReason,
  });

  final int id;
  final String name;
  final int minChoices;
  final int maxChoices;
  final int displayOrder;
  final List<CatalogMenuProduct> products;
  final bool isAvailable;
  final String? unavailableReason;

  factory CatalogMenuGroup.fromJson(Map<String, dynamic> json) {
    return CatalogMenuGroup(
      id: _int(json['id']),
      name: json['name']?.toString() ?? '',
      minChoices: _int(json['min_choices'], fallback: 1),
      maxChoices: _int(json['max_choices'], fallback: 1),
      displayOrder: _int(json['display_order']),
      products: (json['products'] as List? ?? const [])
          .whereType<Map>()
          .map(
            (value) => CatalogMenuProduct.fromJson(
              Map<String, dynamic>.from(value),
            ),
          )
          .toList(),
      isAvailable: json['is_available'] == true,
      unavailableReason: json['unavailable_reason']?.toString(),
    );
  }
}

class CatalogMenuProduct {
  const CatalogMenuProduct({
    required this.menuGroupItemId,
    required this.displayOrder,
    required this.product,
    required this.isOperationallyAvailable,
    this.unavailableReason,
  });

  final int menuGroupItemId;
  final int displayOrder;
  final Product product;
  final bool isOperationallyAvailable;
  final String? unavailableReason;

  factory CatalogMenuProduct.fromJson(Map<String, dynamic> json) {
    final availability = json['availability'];
    final availabilityMap = availability is Map
        ? Map<String, dynamic>.from(availability)
        : const <String, dynamic>{};
    final operational =
        json['is_active'] != false && availabilityMap['available'] != false;
    final normalized = Map<String, dynamic>.from(json)
      ..['is_active'] = operational;
    return CatalogMenuProduct(
      menuGroupItemId: _int(json['menu_group_item_id']),
      displayOrder: _int(json['display_order']),
      product: Product.fromJson(normalized),
      isOperationallyAvailable: operational,
      unavailableReason: availabilityMap['reason']?.toString(),
    );
  }
}

int _int(Object? value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

double _double(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

DateTime? _date(Object? value) {
  final text = value?.toString();
  return text == null ? null : DateTime.tryParse(text);
}
