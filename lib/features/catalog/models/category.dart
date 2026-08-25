import 'package:freezed_annotation/freezed_annotation.dart';

part 'category.freezed.dart';
part 'category.g.dart';

/// Catégorie de produits du catalogue.
///
/// [sortOrder] : ordre d'affichage dans les chips de filtrage.
/// [isActive] : false → catégorie masquée côté client.
@freezed
class Category with _$Category {
  const factory Category({
    required int id,
    required String name,
    String? description,
    @JsonKey(name: 'image_url') String? imageUrl,
    @JsonKey(name: 'sort_order') @Default(0) int sortOrder,
    @JsonKey(name: 'is_active') @Default(true) bool isActive,
  }) = _Category;

  factory Category.fromJson(Map<String, dynamic> json) =>
      _$CategoryFromJson(json);
}
