import 'package:freezed_annotation/freezed_annotation.dart';

part 'loyalty_reward.freezed.dart';
part 'loyalty_reward.g.dart';

/// Type de récompense (`LoyaltyReward.reward_type`, contrainte serveur
/// `^(discount_euros|free_product)$`). Défaut `discountEuros` si une valeur
/// inconnue apparaît — même pattern que `_orderTypeFromApi` dans
/// `features/orders/models/order.dart`.
enum LoyaltyRewardType { discountEuros, freeProduct }

LoyaltyRewardType _rewardTypeFromApi(String value) => switch (value) {
      'free_product' => LoyaltyRewardType.freeProduct,
      _ => LoyaltyRewardType.discountEuros,
    };

String _rewardTypeToApi(LoyaltyRewardType type) => switch (type) {
      LoyaltyRewardType.freeProduct => 'free_product',
      LoyaltyRewardType.discountEuros => 'discount_euros',
    };

/// Récompense du catalogue avec éligibilité — miroir de
/// `LoyaltyRewardEligibilityResponse`
/// (`api-pizza/app/modules/loyalty/config/schemas.py`).
///
/// [🔒 api-corrections-phase-d.md §6] `canRedeem`/`missingPoints` sont
/// fournis par le serveur — l'UI doit les utiliser directement pour l'état
/// grisé plutôt que de recalculer `pointsRequired > currentPoints` côté
/// client (le serveur peut appliquer une règle plus fine, ex. récompense
/// inactive).
@freezed
class LoyaltyReward with _$LoyaltyReward {
  const factory LoyaltyReward({
    required int id,
    required String name,
    @JsonKey(
      name: 'reward_type',
      fromJson: _rewardTypeFromApi,
      toJson: _rewardTypeToApi,
    )
    required LoyaltyRewardType rewardType,
    @JsonKey(name: 'points_required') required int pointsRequired,
    @JsonKey(name: 'discount_amount') double? discountAmount,
    @JsonKey(name: 'product_id') int? productId,
    @JsonKey(name: 'is_active') @Default(true) bool isActive,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'can_redeem') required bool canRedeem,
    @JsonKey(name: 'missing_points') required int missingPoints,
  }) = _LoyaltyReward;

  factory LoyaltyReward.fromJson(Map<String, dynamic> json) =>
      _$LoyaltyRewardFromJson(json);
}
