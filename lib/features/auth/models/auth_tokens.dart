import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_tokens.freezed.dart';
part 'auth_tokens.g.dart';

/// Paire de tokens retournée par l'API après login / register / refresh.
///
/// [accessToken] → stocké en mémoire via [accessTokenProvider].
/// [refreshToken] → persisté en [TokenStorage] (secure storage).
@freezed
class AuthTokens with _$AuthTokens {
  const factory AuthTokens({
    @JsonKey(name: 'access_token') required String accessToken,
    @JsonKey(name: 'refresh_token') required String refreshToken,
    // ID de la ligne refresh_token — utilisé par GET /auth/sessions
    // (?current_session_id=) pour marquer la session courante.
    @JsonKey(name: 'session_id') required int sessionId,
  }) = _AuthTokens;

  factory AuthTokens.fromJson(Map<String, dynamic> json) =>
      _$AuthTokensFromJson(json);
}
