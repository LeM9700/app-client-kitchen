import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Access token JWT en mémoire uniquement.
///
/// - Mis à jour par [AuthNotifier] après login/register.
/// - Mis à jour par l'intercepteur Dio après un refresh réussi.
/// - Remis à null à la déconnexion.
///
/// Le refresh token, lui, est persisté en flutter_secure_storage (Plan 03).
final accessTokenProvider = StateProvider<String?>((ref) => null);
