import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_client/core/providers/auth_session_provider.dart';
import 'package:app_client/features/account/models/session.dart';
import 'package:app_client/features/auth/providers/auth_provider.dart';

// ─────────────────────────────────────────────────────────────────────────
// Sessions actives — `GET /auth/sessions?current_session_id=`.
// ─────────────────────────────────────────────────────────────────────────

/// Liste des sessions actives de l'utilisateur, `is_current` correctement
/// flaggé grâce à [currentSessionIdProvider] (peuplé par `AuthNotifier` au
/// login/register — voir api-corrections-phase-d.md §8 : sans ce paramètre,
/// l'API ne marque AUCUNE session comme courante).
///
/// `autoDispose` + `ref.watch(currentSessionIdProvider)` : pas de cache
/// persistant entre deux visites de l'écran, et recalculé si la session
/// courante change en cours de vie de l'app.
final sessionsProvider = FutureProvider.autoDispose<List<Session>>((ref) {
  final currentSessionId = ref.watch(currentSessionIdProvider);
  return ref.read(authRepositoryProvider).getSessions(
        currentSessionId: currentSessionId,
      );
});

/// Actions sur les sessions actives — révocation individuelle.
final sessionActionsProvider =
    Provider<SessionActions>((ref) => SessionActions(ref));

/// [Décision d'architecture n°1, plan-18] La session courante ne peut pas
/// être révoquée depuis cet écran (protection contre l'auto-déconnexion
/// accidentelle) — cette contrainte est appliquée côté UI
/// (`sessions_screen.dart` ne propose pas de bouton de révocation sur
/// l'entrée `isCurrent`), pas ici : [revoke] révoque n'importe quel id fourni.
class SessionActions {
  SessionActions(this._ref);
  final Ref _ref;

  /// Révoque la session [sessionId] puis réinvalide [sessionsProvider] pour
  /// que la liste affichée reflète immédiatement la révocation.
  Future<void> revoke(int sessionId) async {
    await _ref.read(authRepositoryProvider).revokeSession(sessionId);
    _ref.invalidate(sessionsProvider);
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Changement de mot de passe — `POST /auth/change-password`.
// ─────────────────────────────────────────────────────────────────────────

/// État : [AsyncValue<void>], même convention que `AuthNotifier`
/// (`features/auth/providers/auth_provider.dart`).
/// - `data(null)` → état initial ou après succès
/// - `loading()` → requête en cours
/// - `error(e, s)` → échec, contient l'`AppException` : `ValidationException`
///   (422, politique de mot de passe sur `new_password`, ou `current_password`
///   manquant) ou `AuthException` (401, `current_password` incorrect — voir
///   api-corrections-phase-d.md §8).
class ChangePasswordNotifier extends StateNotifier<AsyncValue<void>> {
  ChangePasswordNotifier(this._ref) : super(const AsyncValue.data(null));

  final Ref _ref;

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() {
      return _ref.read(authRepositoryProvider).changePassword(
            currentPassword: currentPassword,
            newPassword: newPassword,
          );
    });
  }
}

final changePasswordNotifierProvider =
    StateNotifierProvider.autoDispose<ChangePasswordNotifier, AsyncValue<void>>(
  (ref) => ChangePasswordNotifier(ref),
);

// ─────────────────────────────────────────────────────────────────────────
// Édition du profil — `PATCH /customer/me`.
// ─────────────────────────────────────────────────────────────────────────

/// État : [AsyncValue<void>]. Sur succès, met à jour [currentUserProvider]
/// (`features/auth/providers/auth_provider.dart`) avec le profil renvoyé par
/// le serveur, pour que le reste de l'app (header compte, etc.) reflète
/// immédiatement la modification.
class ProfileEditNotifier extends StateNotifier<AsyncValue<void>> {
  ProfileEditNotifier(this._ref) : super(const AsyncValue.data(null));

  final Ref _ref;

  Future<void> updateProfile({String? fullName, String? phone}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final user = await _ref.read(authRepositoryProvider).updateProfile(
            fullName: fullName,
            phone: phone,
          );
      _ref.read(currentUserProvider.notifier).state = user;
    });
  }
}

final profileEditNotifierProvider =
    StateNotifierProvider.autoDispose<ProfileEditNotifier, AsyncValue<void>>(
  (ref) => ProfileEditNotifier(ref),
);
