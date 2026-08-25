/// Hiérarchie d'exceptions de l'application.
///
/// Les repositories convertissent [DioException] → [AppException] avant
/// de propager l'erreur. Les screens et providers ne manipulent jamais
/// Dio directement — couplage zéro avec la lib HTTP.
sealed class AppException implements Exception {
  const AppException(this.message);
  final String message;

  @override
  String toString() => 'AppException: $message';
}

/// Problème réseau (pas de connexion, timeout, DNS).
final class NetworkException extends AppException {
  const NetworkException([
    super.message = 'Connexion impossible. Vérifiez votre réseau.',
  ]);
}

/// Erreur serveur (5xx).
final class ServerException extends AppException {
  const ServerException([
    super.message = 'Erreur serveur. Réessayez dans quelques instants.',
  ]);
}

/// Session expirée ou accès refusé (401/403).
final class AuthException extends AppException {
  const AuthException([super.message = 'Session expirée. Reconnectez-vous.']);
}

/// Erreur de validation côté serveur (422).
/// [fieldErrors] contient les messages par champ (clé = nom du champ).
final class ValidationException extends AppException {
  // [🔧] `AppException(this.message)` est un paramètre positionnel — le
  // raccourci `super.message` ne fonctionne que dans une liste de paramètres
  // positionnels ([super.x]/super.x), pas au milieu de paramètres nommés
  // ({...}) comme ici (`fieldErrors` est nommé requis). D'où l'appel
  // explicite `: super(message)`.
  const ValidationException({
    required this.fieldErrors,
    String message = 'Données invalides.',
  }) : super(message);

  final Map<String, String> fieldErrors;
}

/// Ressource introuvable (404).
final class NotFoundException extends AppException {
  const NotFoundException([super.message = 'Ressource introuvable.']);
}
