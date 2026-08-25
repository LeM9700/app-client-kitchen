import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:app_client/features/catalog/models/product.dart';

part 'search_result.freezed.dart';
part 'search_result.g.dart';

/// Résultat de recherche paginé retourné par `GET /catalog/search`.
///
/// [total] : nombre total de résultats (pour pagination future).
/// [query] : requête de recherche d'origine (utile pour affichage "X résultats pour Y").
@freezed
class SearchResult with _$SearchResult {
  const factory SearchResult({
    required List<Product> products,
    required int total,
    @Default('') String query,
  }) = _SearchResult;

  factory SearchResult.fromJson(Map<String, dynamic> json) =>
      _$SearchResultFromJson(json);
}
