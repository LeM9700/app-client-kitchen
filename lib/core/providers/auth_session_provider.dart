import 'package:flutter_riverpod/flutter_riverpod.dart';

/// ID de la session courante (`AuthTokens.sessionId`), en mémoire uniquement.
///
/// Utilisé par `GET /auth/sessions?current_session_id=` (Plan 18) pour que
/// l'écran "Sessions actives" sache quelle entrée est la session en cours et
/// empêche son auto-révocation.
final currentSessionIdProvider = StateProvider<int?>((ref) => null);
