import 'package:freezed_annotation/freezed_annotation.dart';

part 'delivery_info.freezed.dart';
part 'delivery_info.g.dart';

/// Miroir de la réponse réelle de `POST /delivery/check`
/// (`{zone_id, name, fee, estimated_minutes, ...}`). `fee` est le frais réellement appliqué
/// au sous-total envoyé (règles de zone, livraison offerte) ; les champs ajoutés ensuite sont
/// optionnels pour rester compatibles avec une API plus ancienne.
///
/// [🔒 CORRECTIF] Pas de champ `deliverable` — l'endpoint retourne soit `200`
/// avec ces champs (zone trouvée), soit lève un `422 DELIVERY_ZONE_UNREACHABLE`
/// si aucune zone ne couvre le point (voir `DeliveryZoneUnreachableException`
/// dans `checkout_repository.dart`). Ce modèle ne représente donc que le cas
/// succès — l'absence de couverture est gérée comme une erreur, pas comme un
/// état "non deliverable" de cette classe.
@freezed
class DeliveryInfo with _$DeliveryInfo {
  const factory DeliveryInfo({
    @JsonKey(name: 'zone_id') required int zoneId,
    required String name,
    required double fee,
    @JsonKey(name: 'estimated_minutes') required int estimatedMinutes,
    @JsonKey(name: 'establishment_id') int? establishmentId,
    @JsonKey(name: 'base_fee') double? baseFee,
    @JsonKey(name: 'free_delivery') @Default(false) bool freeDelivery,
    @JsonKey(name: 'applied_label') String? appliedLabel,
    @JsonKey(name: 'remaining_for_free') double? remainingForFree,
    @JsonKey(name: 'min_order_amount') @Default(0) double minOrderAmount,
    @JsonKey(name: 'min_order_met') bool? minOrderMet,
  }) = _DeliveryInfo;

  factory DeliveryInfo.fromJson(Map<String, dynamic> json) =>
      _$DeliveryInfoFromJson(json);
}
