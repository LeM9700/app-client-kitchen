import 'package:freezed_annotation/freezed_annotation.dart';

part 'promotion.freezed.dart';
part 'promotion.g.dart';

/// Type de réduction (`Promotion.discount_type` côté serveur, `Literal["fixed",
/// "percent"]` dans `api-pizza/app/modules/promotions/schemas.py::PromotionPublicOut`).
///
/// [🔒 api-corrections-phase-d.md §7] Valeurs réelles `"fixed"`/`"percent"` —
/// PAS `"percentage"`/`"fixed"` comme le plan d'origine le supposait. Même
/// convention de mapping manuel (switch) que `LoyaltyRewardType` dans
/// `features/loyalty/models/loyalty_reward.dart` plutôt qu'un `@JsonValue` par
/// valeur, pour rester cohérent avec le reste du code base.
enum DiscountType { percent, fixed }

DiscountType _discountTypeFromApi(String value) => switch (value) {
      'fixed' => DiscountType.fixed,
      _ => DiscountType.percent,
    };

String _discountTypeToApi(DiscountType type) => switch (type) {
      DiscountType.fixed => 'fixed',
      DiscountType.percent => 'percent',
    };

/// Promotion publique — miroir de `PromotionPublicOut`
/// (`api-pizza/app/modules/promotions/schemas.py`), retournée par
/// `GET /promotions` (public, pas d'auth requise, scope tenant via le header
/// `X-Tenant-Slug` déjà géré par `ApiClient`).
///
/// [🔒 api-corrections-phase-d.md §7] **Pas de champ `title`** dans la réponse
/// réelle — utiliser `description` (repli sur `code` si absente/vide) comme
/// titre affiché (voir [PromotionX.displayTitle]). **Pas de champ `isActive`**
/// non plus : la liste renvoyée par `GET /promotions` est déjà filtrée côté
/// serveur (`service.list_active`) aux promotions actives — ce champ a donc
/// été retiré du modèle plutôt que d'être simulé avec une valeur par défaut
/// `true` qui ne refléterait aucune donnée serveur réelle.
@freezed
class Promotion with _$Promotion {
  const factory Promotion({
    required int id,
    required String code,
    String? description,
    @JsonKey(
      name: 'discount_type',
      fromJson: _discountTypeFromApi,
      toJson: _discountTypeToApi,
    )
    required DiscountType discountType,
    @JsonKey(name: 'discount_value') required double discountValue,
    @JsonKey(name: 'min_order_amount') @Default(0) double minimumOrderAmount,
    // Pas de besoin UI dans le DoD du plan — conservé pour fidélité au schéma
    // réel (`PromotionPublicOut.starts_at`), champ bon marché à modéliser.
    @JsonKey(name: 'starts_at') DateTime? startsAt,
    @JsonKey(name: 'ends_at') DateTime? expiresAt,
  }) = _Promotion;

  factory Promotion.fromJson(Map<String, dynamic> json) =>
      _$PromotionFromJson(json);
}

extension PromotionX on Promotion {
  /// Titre affiché sur la card — `description` si renseignée et non vide,
  /// sinon repli sur `code` (voir doc de classe, pas de champ `title` réel).
  String get displayTitle {
    final desc = description;
    if (desc != null && desc.trim().isNotEmpty) return desc;
    return code;
  }

  String get displayDiscount => discountType == DiscountType.percent
      ? '-${discountValue.toInt()}%'
      : '-${discountValue.toStringAsFixed(2)} €';

  bool get isExpiringSoon {
    final expires = expiresAt;
    if (expires == null) return false;
    final remaining = expires.difference(DateTime.now());
    return !remaining.isNegative && remaining.inHours <= 24;
  }
}
