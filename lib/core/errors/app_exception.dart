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

/// Erreur metier de la livraison, identifiee par le `code` renvoye par l'API (par exemple
/// `DELIVERY_DISABLED`, `DELIVERY_MIN_ORDER_NOT_MET`). L'ecran choisit le message traduit
/// d'apres le code ; [message] n'est que le texte technique du serveur.
final class DeliveryException extends AppException {
  const DeliveryException(this.code, super.message);

  final String code;
}

/// Ressource introuvable (404).
final class NotFoundException extends AppException {
  const NotFoundException([super.message = 'Ressource introuvable.']);
}

/// Refus métier du parcours de commande par le contrôle HACCP strict.
///
/// Le panier reste intact afin que le client puisse le régulariser ou réessayer
/// après résolution par l'établissement. Le serveur reste l'autorité finale.
final class HaccpOrderBlockedException extends AppException {
  const HaccpOrderBlockedException(this.code, [
    super.message =
        'La commande est temporairement indisponible : le contrôle sanitaire '
        "de l'établissement n'est pas conforme.",
  ]);

  final String code;
}
