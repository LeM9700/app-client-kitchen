import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:app_client/core/errors/app_exception.dart';
import 'package:app_client/core/providers/auth_token_provider.dart';
import 'package:app_client/features/catalog/providers/favorites_provider.dart';
import 'package:app_client/features/catalog/repositories/favorites_repository.dart';

// ──────────────────────────────────────────────────────────────────────────────
// Mocks (mocktail — cohérent avec test/features/loyalty/loyalty_provider_test.dart)
// ──────────────────────────────────────────────────────────────────────────────

class MockFavoritesRepository extends Mock implements FavoritesRepository {}

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
    addTearDown(container.dispose);
  });

  group('favoritesProvider — anonyme (pas de token)', () {
    test('vide par défaut', () {
      expect(container.read(favoritesProvider), isEmpty);
    });

    test('toggle() ajoute un produit absent', () {
      container.read(favoritesProvider.notifier).toggle(1);

      expect(container.read(favoritesProvider), {1});
    });

    test('toggle() retire un produit déjà favori', () {
      final notifier = container.read(favoritesProvider.notifier);
      notifier.toggle(1);

      notifier.toggle(1);

      expect(container.read(favoritesProvider), isEmpty);
    });

    test('isFavorite() reflète le state courant', () {
      final notifier = container.read(favoritesProvider.notifier);

      expect(notifier.isFavorite(1), false);

      notifier.toggle(1);

      expect(notifier.isFavorite(1), true);
    });
  });

  group('favoritesProvider — authentifié dès la création', () {
    late MockFavoritesRepository mockRepo;

    setUp(() {
      mockRepo = MockFavoritesRepository();
      container = ProviderContainer(
        overrides: [
          favoritesRepositoryProvider.overrideWithValue(mockRepo),
          accessTokenProvider.overrideWith((ref) => 'fake-token'),
        ],
      );
      addTearDown(container.dispose);
    });

    test('charge et fusionne les favoris serveur au démarrage', () async {
      when(() => mockRepo.list()).thenAnswer((_) async => {5, 6});

      // Lit le provider pour déclencher la construction du notifier (et donc
      // l'appel _loadFromBackend), puis laisse le microtask du Future
      // s'exécuter.
      container.read(favoritesProvider);
      await Future<void>.delayed(Duration.zero);

      expect(container.read(favoritesProvider), {5, 6});
    });

    test('toggle() authentifié appelle add() puis remove()', () async {
      when(() => mockRepo.list()).thenAnswer((_) async => {});
      when(() => mockRepo.add(any())).thenAnswer((_) async {});
      when(() => mockRepo.remove(any())).thenAnswer((_) async {});

      final notifier = container.read(favoritesProvider.notifier);
      await Future<void>.delayed(Duration.zero);

      notifier.toggle(9);
      expect(container.read(favoritesProvider), {9});
      await Future<void>.delayed(Duration.zero);
      verify(() => mockRepo.add(9)).called(1);

      notifier.toggle(9);
      expect(container.read(favoritesProvider), isEmpty);
      await Future<void>.delayed(Duration.zero);
      verify(() => mockRepo.remove(9)).called(1);
    });

    test('rollback si la synchronisation serveur échoue', () async {
      when(() => mockRepo.list()).thenAnswer((_) async => {});
      // `thenAnswer(async => throw ...)`, PAS `thenThrow` : le repository
      // réel est une fonction `async` (l'erreur arrive toujours via le
      // Future, jamais en throw synchrone à l'appel) — `thenThrow` sur
      // mocktail lève, lui, de façon synchrone et ne reflèterait pas le
      // comportement réel de [FavoritesNotifier.toggle].
      when(() => mockRepo.add(any())).thenAnswer(
        (_) async => throw const NetworkException(),
      );

      final notifier = container.read(favoritesProvider.notifier);
      await Future<void>.delayed(Duration.zero);

      notifier.toggle(3);
      expect(container.read(favoritesProvider), {3});

      await Future<void>.delayed(Duration.zero);

      expect(container.read(favoritesProvider), isEmpty);
    });
  });

  group('favoritesProvider — login en cours de session', () {
    test('conserve les favoris tapés en anonyme et fusionne avec le serveur',
        () async {
      final mockRepo = MockFavoritesRepository();
      when(() => mockRepo.list()).thenAnswer((_) async => {7});

      // accessTokenProvider réel (pas overridé) : démarre à `null`, comme un
      // utilisateur anonyme.
      container = ProviderContainer(
        overrides: [favoritesRepositoryProvider.overrideWithValue(mockRepo)],
      );
      addTearDown(container.dispose);

      final notifier = container.read(favoritesProvider.notifier);
      notifier.toggle(1); // favori local, anonyme
      expect(container.read(favoritesProvider), {1});
      verifyNever(() => mockRepo.list());

      // Login en cours de session : accessTokenProvider passe de null à une
      // valeur — le notifier doit détecter la transition et charger/fusionner
      // les favoris serveur sans perdre le favori local déjà taggué.
      container.read(accessTokenProvider.notifier).state = 'fake-token';
      await Future<void>.delayed(Duration.zero);

      expect(container.read(favoritesProvider), {1, 7});
      verify(() => mockRepo.list()).called(1);
    });
  });
}
