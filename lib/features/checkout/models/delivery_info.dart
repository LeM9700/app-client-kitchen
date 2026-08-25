import 'package:freezed_annotation/freezed_annotation.dart';

part 'delivery_info.freezed.dart';
part 'delivery_info.g.dart';

/// Miroir de la réponse réelle de `POST /delivery/check`
/// (`{zone_id, name, fee, estimated_minutes}`).
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
  }) = _DeliveryInfo;

  factory DeliveryInfo.fromJson(Map<String, dynamic> json) =>
      _$DeliveryInfoFromJson(json);
}
