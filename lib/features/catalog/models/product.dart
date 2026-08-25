import 'package:freezed_annotation/freezed_annotation.dart';

part 'product.freezed.dart';
part 'product.g.dart';

/// Extrait les codes (`slug`) des objets allergènes renvoyés par l'API
/// (`ProductAllergenPublicOut`) pour les exposer côté client en `List<String>`.
List<String> _allergensFromJson(List<dynamic>? json) => (json ?? [])
    .map((e) => (e as Map<String, dynamic>)['slug'] as String)
    .toList();

List<dynamic> _allergensToJson(List<String> allergens) => allergens;

/// Variante d'un produit (ex: taille S/M/L pour une pizza).
///
/// [priceDelta] : surcoût par rapport au prix de base du produit.
/// Peut être négatif (rarement) ou nul (variante sans surcoût).
@freezed
class ProductVariant with _$ProductVariant {
  const factory ProductVariant({
    required int id,
    required String name,
    @JsonKey(name: 'price_delta') @Default(0) double priceDelta,
  }) = _ProductVariant;

  factory ProductVariant.fromJson(Map<String, dynamic> json) =>
      _$ProductVariantFromJson(json);
}

/// Extra/supplément optionnel (ex: double fromage, sauce supplémentaire).
@freezed
class ProductExtra with _$ProductExtra {
  const factory ProductExtra({
    required int id,
    required String name,
    required double price,
    @JsonKey(name: 'is_active') @Default(true) bool available,
  }) = _ProductExtra;

  factory ProductExtra.fromJson(Map<String, dynamic> json) =>
      _$ProductExtraFromJson(json);
}

/// Produit du catalogue.
///
/// [allergens] : codes EU (ex: 'gluten', 'milk') — voir UE 1169/2011.
/// Extraits côté client depuis les objets `ProductAllergenPublicOut` de l'API
/// (`{allergen_id, name, slug, ...}`) via leur champ `slug`.
/// [variants] : liste vide si produit sans variation.
/// [extras] : liste vide si pas de suppléments disponibles.
/// [isAvailable] : contrôlé par le tenant admin en temps réel.
@freezed
class Product with _$Product {
  const Product._();

  const factory Product({
    required int id,
    required String name,
    @JsonKey(name: 'base_price') required double price,
    @JsonKey(name: 'category_id') int? categoryId,
    String? description,
    @JsonKey(name: 'image_url') String? imageUrl,
    @JsonKey(
      name: 'allergens',
      fromJson: _allergensFromJson,
      toJson: _allergensToJson,
    )
    @Default([])
    List<String> allergens,
    @Default([]) List<ProductVariant> variants,
    @Default([]) List<ProductExtra> extras,
    @JsonKey(name: 'is_active') @Default(true) bool isAvailable,
    @JsonKey(name: 'is_featured') @Default(false) bool isFeatured,
    @JsonKey(name: 'sort_order') @Default(0) int sortOrder,
  }) = _Product;

  factory Product.fromJson(Map<String, dynamic> json) =>
      _$ProductFromJson(json);

  /// Prix affiché — prix de base (la sélection de variante ajuste via [ProductVariant.priceDelta]).
  String get displayPrice => '${price.toStringAsFixed(2)} €';

  /// True si au moins une variante est disponible.
  bool get hasVariants => variants.isNotEmpty;

  /// True si au moins un extra est disponible.
  bool get hasExtras => extras.any((e) => e.available);
}
