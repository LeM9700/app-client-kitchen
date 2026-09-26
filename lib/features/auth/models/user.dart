import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';
part 'user.g.dart';

/// Représentation d'un utilisateur authentifié.
///
/// Miroir commun de `UserOut` (`/auth/me`) et `CustomerOut` (`/customer/me`)
/// — les deux exposent `id` (int), `email`, `full_name`, `phone`,
/// `email_verified`. L'id est un `int` (PK SERIAL côté PostgreSQL), pas un
/// UUID.
@freezed
class User with _$User {
  const factory User({
    required int id,
    String? email,
    @JsonKey(name: 'full_name') String? fullName,
    String? phone,
    @JsonKey(name: 'phone_e164') String? phoneE164,
    @JsonKey(name: 'email_verified') @Default(false) bool emailVerified,
    @JsonKey(name: 'phone_verified') @Default(false) bool phoneVerified,
    @JsonKey(name: 'pending_profile_completion')
    @Default(false)
    bool pendingProfileCompletion,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}
