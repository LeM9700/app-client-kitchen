import 'package:freezed_annotation/freezed_annotation.dart';

part 'loyalty_account.freezed.dart';
part 'loyalty_account.g.dart';

/// Solde de fidélité — miroir de `LoyaltyAccountOut`
/// (`api-pizza/app/modules/loyalty/account/schemas.py`).
///
/// [🔒 api-corrections-phase-d.md §6] Vient de `GET /loyalty/me`, PAS
/// `GET /loyalty/account` (hypothèse erronée du plan d'origine).
/// [Décision d'architecture n°1, plan-16] Les points sont calculés côté
/// serveur uniquement — ce modèle ne fait qu'afficher ce que le serveur
/// renvoie, jamais de recalcul côté client.
@freezed
class LoyaltyAccount with _$LoyaltyAccount {
  const factory LoyaltyAccount({
    required int id,
    @JsonKey(name: 'user_id') required int userId,
    required int points,
    @JsonKey(name: 'point_value_euros') @Default(0) double pointValueEuros,
    @JsonKey(name: 'expiring_soon_points') @Default(0) int expiringSoonPoints,
  }) = _LoyaltyAccount;

  factory LoyaltyAccount.fromJson(Map<String, dynamic> json) =>
      _$LoyaltyAccountFromJson(json);
}
