import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'tenant_branding.freezed.dart';
part 'tenant_branding.g.dart';

/// Données de branding du tenant — miroir de [TenantBrandingResponse] côté API.
///
/// Les couleurs sont stockées sous forme de chaînes hex (#RRGGBB) et converties
/// en [Color] Flutter via l'extension [TenantBrandingX].
///
/// [slug] n'est pas retourné par l'API — il est injecté par [BrandingRepository]
/// depuis [Env.tenantSlug] après parsing.
///
/// Génération : `flutter pub run build_runner build --delete-conflicting-outputs`
@freezed
class TenantBranding with _$TenantBranding {
  const TenantBranding._();

  const factory TenantBranding({
    required String slug,
    // [🔧] `displayName`/`logoUrl`/`fontFamily` n'avaient aucun @JsonKey —
    // json_serializable cherchait donc les clés camelCase `displayName`/
    // `logoUrl`/`fontFamily` alors que l'API renvoie du snake_case
    // (`display_name`/`logo_url`/`font_family`, confirmé par
    // TenantBrandingResponse côté api-pizza). Ces trois champs restaient
    // silencieusement `null` en prod (String? optionnel, pas de crash) —
    // trouvé par `flutter test` (échec sur `fontFamily`, `displayName`/
    // `logoUrl` partageaient le même bug mais n'étaient jamais atteints par
    // le test, la première assertion en échec l'interrompant avant).
    @JsonKey(name: 'display_name') String? displayName,
    @JsonKey(name: 'logo_url') String? logoUrl,
    @JsonKey(name: 'primary_color') String? primaryColorHex,
    @JsonKey(name: 'secondary_color') String? secondaryColorHex,
    @JsonKey(name: 'font_family') String? fontFamily,
  }) = _TenantBranding;

  factory TenantBranding.fromJson(Map<String, dynamic> json) =>
      _$TenantBrandingFromJson(json);

  /// Thème de démo — rouge profond / noir — style pizzeria moderne.
  ///
  /// Utilisé comme valeur initiale de [TenantBrandingNotifier] et
  /// comme fallback si [GET /tenant/branding] échoue.
  factory TenantBranding.demo() => const TenantBranding(
        slug: 'demo',
        displayName: "O'Pizza",
        logoUrl: null,
        primaryColorHex: '#FF0045',
        secondaryColorHex: '#285A50',
        fontFamily: null,
      );
}

/// Extension exposant les champs hex sous forme de [Color] Flutter.
extension TenantBrandingX on TenantBranding {
  /// Couleur primaire du tenant. Fallback : rouge #C0392B.
  Color get primaryColor =>
      _parseHex(primaryColorHex) ?? const Color(0xFFFF0045);

  /// Couleur secondaire du tenant. Fallback : noir #1A1A1A.
  Color get secondaryColor =>
      _parseHex(secondaryColorHex) ?? const Color(0xFF285A50);

  Color? _parseHex(String? hex) {
    if (hex == null) return null;
    final cleaned = hex.replaceAll('#', '');
    if (cleaned.length != 6) return null;
    final value = int.tryParse('FF$cleaned', radix: 16);
    return value != null ? Color(value) : null;
  }
}
