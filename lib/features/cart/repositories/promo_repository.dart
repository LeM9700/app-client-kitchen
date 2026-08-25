import 'package:dio/dio.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:app_client/core/api/api_client.dart';
import 'package:app_client/core/api/api_endpoints.dart';

part 'promo_repository.freezed.dart';
part 'promo_repository.g.dart';

/// Miroir de `PromotionValidateOut` (app/modules/promotions/schemas.py).
@freezed
class PromoPreview with _$PromoPreview {
  const factory PromoPreview({
    required bool valid,
    required double discount,
    @JsonKey(name: 'promo_id') int? promoId,
  }) = _PromoPreview;

  factory PromoPreview.fromJson(Map<String, dynamic> json) =>
      _$PromoPreviewFromJson(json);
}

/// Miroir de `LoyaltyPointsPreview` (app/modules/loyalty/config/schemas.py).
/// [🔒 CORRECTIF] Ce n'est PAS un catalogue de récompenses malgré le nom
/// "preview" — c'est un aperçu des points qui seraient gagnés par CETTE
/// commande.
@freezed
class LoyaltyPointsPreview with _$LoyaltyPointsPreview {
  const factory LoyaltyPointsPreview({
    @JsonKey(name: 'base_points') required int basePoints,
    @JsonKey(name: 'bonus_points') required int bonusPoints,
    @JsonKey(name: 'total_points') required int totalPoints,
    @JsonKey(name: 'applied_rules') @Default([]) List<String> appliedRules,
  }) = _LoyaltyPointsPreview;

  factory LoyaltyPointsPreview.fromJson(Map<String, dynamic> json) =>
      _$LoyaltyPointsPreviewFromJson(json);
}

/// Repository code promo & aperçu fidélité — appels préview lecture seule,
/// aucune application définitive avant `POST /orders` (checkout, Plan 11).
class PromoRepository {
  const PromoRepository(this._client);
  final ApiClient _client;

  /// `POST /promotions/validate` — body réel : `{code, order_total}` (pas
  /// `{promo_code, cart}`).
  /// Authentifié — appelant doit vérifier `accessTokenProvider != null`
  /// avant d'appeler (voir [CartScreen], champ code promo masqué sinon).
  Future<PromoPreview> validatePromo({
    required String code,
    required double orderTotal,
  }) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        ApiEndpoints.promotionsValidate,
        data: {'code': code, 'order_total': orderTotal},
      );
      return PromoPreview.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiClient.handleDioError(e);
    }
  }

  /// `GET /loyalty/preview?order_total=` — query param, pas de body.
  Future<LoyaltyPointsPreview> previewLoyaltyPoints(double orderTotal) async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        ApiEndpoints.loyaltyPreview,
        queryParameters: {'order_total': orderTotal},
      );
      return LoyaltyPointsPreview.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiClient.handleDioError(e);
    }
  }
}
