import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:app_client/core/errors/app_exception.dart';
import 'package:app_client/core/providers/auth_token_provider.dart';
import 'package:app_client/features/catalog/models/product.dart';
import 'package:app_client/features/catalog/providers/catalog_provider.dart';
import 'package:app_client/features/catalog/providers/favorites_provider.dart';
import 'package:app_client/features/catalog/repositories/favorites_repository.dart';

class MockFavoritesRepository extends Mock implements FavoritesRepository {}

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
    addTearDown(container.dispose);
  });

  group('favoritesProvider - anonyme', () {
    test('reste vide par defaut', () {
      expect(container.read(favoritesProvider), isEmpty);
    });

    test('toggle() est ignore sans token', () {
      final notifier = container.read(favoritesProvider.notifier);

      notifier.toggle(1);

      expect(container.read(favoritesProvider), isEmpty);
      expect(notifier.isFavorite(1), false);
    });
  });

  group('favoritesProvider - authentifie', () {
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

    test('charge les favoris serveur au demarrage', () async {
      when(() => mockRepo.list()).thenAnswer((_) async => {5, 6});

      container.read(favoritesProvider);
      await Future<void>.delayed(Duration.zero);

      expect(container.read(favoritesProvider), {5, 6});
    });

    test('toggle() appelle add() puis remove()', () async {
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

    test('rollback si la synchronisation serveur echoue', () async {
      when(() => mockRepo.list()).thenAnswer((_) async => {});
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

  group('favoritesProvider - changements de session', () {
    test('login charge le serveur et logout vide la liste', () async {
      final mockRepo = MockFavoritesRepository();
      when(() => mockRepo.list()).thenAnswer((_) async => {7});

      container = ProviderContainer(
        overrides: [favoritesRepositoryProvider.overrideWithValue(mockRepo)],
      );
      addTearDown(container.dispose);

      final notifier = container.read(favoritesProvider.notifier);
      notifier.toggle(1);
      expect(container.read(favoritesProvider), isEmpty);
      verifyNever(() => mockRepo.list());

      container.read(accessTokenProvider.notifier).state = 'fake-token';
      await Future<void>.delayed(Duration.zero);

      expect(container.read(favoritesProvider), {7});
      verify(() => mockRepo.list()).called(1);

      container.read(accessTokenProvider.notifier).state = null;
      await Future<void>.delayed(Duration.zero);

      expect(container.read(favoritesProvider), isEmpty);
    });
  });

  group('favoriteProductsProvider', () {
    test('filtre les produits selon les ids favoris', () async {
      final mockRepo = MockFavoritesRepository();
      when(() => mockRepo.list()).thenAnswer((_) async => {2});

      container = ProviderContainer(
        overrides: [
          favoritesRepositoryProvider.overrideWithValue(mockRepo),
          accessTokenProvider.overrideWith((ref) => 'fake-token'),
          allProductsProvider.overrideWith(
            (ref) async => const [
              Product(id: 1, name: 'Margherita', price: 10),
              Product(id: 2, name: 'Regina', price: 12),
            ],
          ),
        ],
      );
      addTearDown(container.dispose);

      container.read(favoritesProvider);
      await Future<void>.delayed(Duration.zero);
      container.read(favoriteProductsProvider);
      await container.read(allProductsProvider.future);

      final result = container.read(favoriteProductsProvider);

      expect(result.valueOrNull?.map((product) => product.id), [2]);
    });
  });
}
