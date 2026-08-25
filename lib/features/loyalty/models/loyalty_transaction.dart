import 'package:freezed_annotation/freezed_annotation.dart';

part 'loyalty_transaction.freezed.dart';
part 'loyalty_transaction.g.dart';

/// Ligne d'historique de fidélité — miroir de `LoyaltyTransactionOut`
/// (`api-pizza/app/modules/loyalty/account/schemas.py`).
///
/// `transactionType`/`source`/`reason` restent des `String` brutes : le
/// backend ne contraint pas ces champs par un enum Pydantic, donc pas de
/// mapping fermé côté client — affichés tels quels ou via un `switch`
/// non-exhaustif dans l'UI plutôt qu'un enum Dart qui casserait sur une
/// valeur serveur inconnue.
@freezed
class LoyaltyTransaction with _$LoyaltyTransaction {
  const factory LoyaltyTransaction({
    required int id,
    @JsonKey(name: 'account_id') required int accountId,
    @JsonKey(name: 'points_delta') required int pointsDelta,
    required String reason,
    @JsonKey(name: 'transaction_type') required String transactionType,
    required String source,
    @JsonKey(name: 'changed_by_user_id') int? changedByUserId,
    @JsonKey(name: 'order_id') int? orderId,
    @JsonKey(name: 'reward_id') int? rewardId,
    @JsonKey(name: 'reservation_id') int? reservationId,
    @JsonKey(name: 'metadata_json') Map<String, dynamic>? metadataJson,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _LoyaltyTransaction;

  factory LoyaltyTransaction.fromJson(Map<String, dynamic> json) =>
      _$LoyaltyTransactionFromJson(json);
}
