import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:app_client/core/errors/app_exception.dart';
import 'package:app_client/core/providers/auth_session_provider.dart';
import 'package:app_client/features/account/models/session.dart';
import 'package:app_client/features/account/providers/account_provider.dart';
import 'package:app_client/features/auth/models/user.dart';
import 'package:app_client/features/auth/providers/auth_provider.dart';
import 'package:app_client/features/auth/repositories/auth_repository.dart';

// ──────────────────────────────────────────────────────────────────────────────
// Mocks (mocktail — cohérent avec test/features/loyalty/loyalty_provider_test.dart)
// ──────────────────────────────────────────────────────────────────────────────

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockRepo;
  late ProviderContainer container;

  setUp(() {
    mockRepo = MockAuthRepository();
    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(mockRepo),
      ],
    );
    addTearDown(container.dispose);
  });

  // ──────────────────────────────────────────────────────────────────────────
  // sessionsProvider
  // ──────────────────────────────────────────────────────────────────────────

  group('sessionsProvider', () {
    test(
        'transmet currentSessionIdProvider au repository pour que '
        'is_current soit correct (api-corrections-phase-d.md §8 : sans ce '
        'paramètre, aucune session n\'est marquée courante)', () async {
      container.read(currentSessionIdProvider.notifier).state = 42;

      when(() => mockRepo.getSessions(currentSessionId: 42)).thenAnswer(
        (_) async => [
          Session(
            id: 42,
            createdAt: DateTime.utc(2026, 7, 1),
            expiresAt: DateTime.utc(2026, 8, 1),
            userAgent: 'Mozilla/5.0 (iPhone)',
            ipAddress: '10.0.0.1',
            isCurrent: true,
          ),
          Session(
            id: 7,
            createdAt: DateTime.utc(2026, 6, 1),
            expiresAt: DateTime.utc(2026, 7, 15),
            userAgent: 'Mozilla/5.0 (Windows)',
            ipAddress: '10.0.0.2',
            isCurrent: false,
          ),
        ],
      );

      container.listen(sessionsProvider, (_, __) {});
      final sessions = await container.read(sessionsProvider.future);

      expect(sessions, hasLength(2));
      expect(sessions.firstWhere((s) => s.id == 42).isCurrent, isTrue);
      expect(sessions.firstWhere((s) => s.id == 7).isCurrent, isFalse);
      verify(() => mockRepo.getSessions(currentSessionId: 42)).called(1);
    });

    test(
        'SessionDeviceIcon.isMobileDevice — heuristique user_agent '
        '(pas de champ device_type structuré côté serveur)', () {
      final mobile = Session(
        id: 1,
        createdAt: DateTime.utc(2026, 1, 1),
        expiresAt: DateTime.utc(2026, 1, 2),
        userAgent: 'Mozilla/5.0 (Linux; Android 14)',
      );
      final desktop = Session(
        id: 2,
        createdAt: DateTime.utc(2026, 1, 1),
        expiresAt: DateTime.utc(2026, 1, 2),
        userAgent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
      );
      final unknown = Session(
        id: 3,
        createdAt: DateTime.utc(2026, 1, 1),
        expiresAt: DateTime.utc(2026, 1, 2),
        userAgent: null,
      );

      expect(mobile.isMobileDevice, isTrue);
      expect(desktop.isMobileDevice, isFalse);
      expect(unknown.isMobileDevice, isFalse);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // SessionActions.revoke
  // ──────────────────────────────────────────────────────────────────────────

  group('SessionActions.revoke', () {
    test(
        'révoque la session puis réinvalide sessionsProvider (la liste '
        'affichée reflète immédiatement la révocation)', () async {
      when(() => mockRepo.getSessions(currentSessionId: null)).thenAnswer(
        (_) async => [
          Session(
            id: 1,
            createdAt: DateTime.utc(2026, 1, 1),
            expiresAt: DateTime.utc(2026, 2, 1),
            isCurrent: true,
          ),
          Session(
            id: 2,
            createdAt: DateTime.utc(2026, 1, 1),
            expiresAt: DateTime.utc(2026, 2, 1),
            isCurrent: false,
          ),
        ],
      );

      // autoDispose : un listener actif maintient l'état vivant entre la
      // lecture initiale et le refetch déclenché par `revoke` (même
      // précaution que test/features/loyalty/loyalty_provider_test.dart).
      container.listen(sessionsProvider, (_, __) {});
      final initial = await container.read(sessionsProvider.future);
      expect(initial, hasLength(2));

      when(() => mockRepo.revokeSession(2)).thenAnswer((_) async {});
      when(() => mockRepo.getSessions(currentSessionId: null)).thenAnswer(
        (_) async => [
          Session(
            id: 1,
            createdAt: DateTime.utc(2026, 1, 1),
            expiresAt: DateTime.utc(2026, 2, 1),
            isCurrent: true,
          ),
        ],
      );

      await container.read(sessionActionsProvider).revoke(2);

      verify(() => mockRepo.revokeSession(2)).called(1);
      final updated = await container.read(sessionsProvider.future);
      expect(updated, hasLength(1));
      expect(updated.single.id, 1);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // ChangePasswordNotifier
  // ──────────────────────────────────────────────────────────────────────────

  group('ChangePasswordNotifier', () {
    test('succès → state data(null)', () async {
      when(
        () => mockRepo.changePassword(
          currentPassword: 'OldPass1!',
          newPassword: 'NewPass1!',
        ),
      ).thenAnswer((_) async {});

      // autoDispose : un listener actif évite que le provider (et le
      // StateNotifier sous-jacent) soit disposé pendant le `await` — même
      // précaution que sessionsProvider ci-dessus.
      container.listen(changePasswordNotifierProvider, (_, __) {});
      final notifier = container.read(changePasswordNotifierProvider.notifier);
      await notifier.changePassword(
        currentPassword: 'OldPass1!',
        newPassword: 'NewPass1!',
      );

      final state = container.read(changePasswordNotifierProvider);
      expect(state.hasError, isFalse);
      expect(state.isLoading, isFalse);
      verify(
        () => mockRepo.changePassword(
          currentPassword: 'OldPass1!',
          newPassword: 'NewPass1!',
        ),
      ).called(1);
    });

    test(
        'mot de passe actuel incorrect (401 INVALID_CREDENTIALS) → state '
        'error contient une AuthException exploitable par le formulaire pour '
        'l\'afficher sur le champ "mot de passe actuel" '
        '(ChangePasswordScreen._submit mappe AuthException → '
        'fieldErrors[\'current_password\'], voir api-corrections-phase-d.md '
        '§8 : ce n\'est PAS une ValidationException 422)', () async {
      when(
        () => mockRepo.changePassword(
          currentPassword: 'WrongPass1!',
          newPassword: 'NewPass1!',
        ),
      ).thenThrow(const AuthException('Current password is incorrect'));

      container.listen(changePasswordNotifierProvider, (_, __) {});
      final notifier = container.read(changePasswordNotifierProvider.notifier);
      await notifier.changePassword(
        currentPassword: 'WrongPass1!',
        newPassword: 'NewPass1!',
      );

      final state = container.read(changePasswordNotifierProvider);
      expect(state.hasError, isTrue);
      expect(state.error, isA<AuthException>());
      expect(
        (state.error as AuthException).message,
        'Current password is incorrect',
      );
    });

    test(
        'politique de mot de passe violée (422) → ValidationException avec '
        'fieldErrors[\'new_password\'] exploitable directement par le '
        'formulaire', () async {
      when(
        () => mockRepo.changePassword(
          currentPassword: 'OldPass1!',
          newPassword: 'weak',
        ),
      ).thenThrow(
        const ValidationException(
          fieldErrors: {'new_password': 'Mot de passe insuffisant'},
        ),
      );

      container.listen(changePasswordNotifierProvider, (_, __) {});
      final notifier = container.read(changePasswordNotifierProvider.notifier);
      await notifier.changePassword(
        currentPassword: 'OldPass1!',
        newPassword: 'weak',
      );

      final state = container.read(changePasswordNotifierProvider);
      expect(state.hasError, isTrue);
      final error = state.error as ValidationException;
      expect(error.fieldErrors['new_password'], 'Mot de passe insuffisant');
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // ProfileEditNotifier
  // ──────────────────────────────────────────────────────────────────────────

  group('ProfileEditNotifier', () {
    test('succès → met à jour currentUserProvider avec le profil renvoyé',
        () async {
      const updated = User(
        id: 1,
        email: 'test@example.com',
        fullName: 'Nouveau Nom',
        phone: '0600000000',
        emailVerified: true,
      );
      when(
        () => mockRepo.updateProfile(
          fullName: 'Nouveau Nom',
          phone: '0600000000',
        ),
      ).thenAnswer((_) async => updated);

      container.listen(profileEditNotifierProvider, (_, __) {});
      final notifier = container.read(profileEditNotifierProvider.notifier);
      await notifier.updateProfile(
        fullName: 'Nouveau Nom',
        phone: '0600000000',
      );

      final state = container.read(profileEditNotifierProvider);
      expect(state.hasError, isFalse);
      expect(container.read(currentUserProvider), updated);
    });
  });
}
