import 'package:freezed_annotation/freezed_annotation.dart';

part 'session.freezed.dart';
part 'session.g.dart';

/// Session active — miroir de `SessionOut`
/// (`api-pizza/app/modules/auth/schemas.py`), retournée par
/// `GET /auth/sessions?current_session_id=`.
///
/// [🔒 api-corrections-phase-d.md §8] Le plan d'origine supposait des champs
/// `device_type`/`ip` qui n'existent PAS côté serveur. Champs réels :
/// `id, created_at, expires_at, user_agent, ip_address, is_current`. Pas de
/// type d'appareil structuré — [isMobileDevice] dérive une heuristique
/// grossière depuis [userAgent] pour choisir une icône.
@freezed
class Session with _$Session {
  const factory Session({
    required int id,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'expires_at') required DateTime expiresAt,
    @JsonKey(name: 'user_agent') String? userAgent,
    @JsonKey(name: 'ip_address') String? ipAddress,
    @JsonKey(name: 'is_current') @Default(false) bool isCurrent,
  }) = _Session;

  factory Session.fromJson(Map<String, dynamic> json) =>
      _$SessionFromJson(json);
}

/// Heuristique d'icône mobile/desktop à partir de [Session.userAgent].
///
/// [🔒 api-corrections-phase-d.md §8] Aucun champ `device_type` structuré
/// n'existe côté serveur — `user_agent` est une chaîne brute. On ne tente pas
/// un parsing exhaustif, seulement une détection grossière suffisante pour
/// choisir entre une icône téléphone et une icône ordinateur.
extension SessionDeviceIcon on Session {
  bool get isMobileDevice {
    final ua = userAgent?.toLowerCase() ?? '';
    return ua.contains('mobile') ||
        ua.contains('android') ||
        ua.contains('iphone') ||
        ua.contains('ipad');
  }
}
