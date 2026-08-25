import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:app_client/core/errors/app_exception.dart';
import 'package:app_client/features/loyalty/models/loyalty_account.dart';
import 'package:app_client/features/loyalty/providers/loyalty_provider.dart';
import 'package:app_client/features/loyalty/repositories/loyalty_repository.dart';

// ──────────────────────────────────────────────────────────────────────────────
// Mocks (mocktail — cohérent avec test/features/checkout/checkout_provider_test.dart
// et test/features/orders/order_provider_test.dart)
// ──────────────────────────────────────────────────────────────────────────────

class MockLoyaltyRepository extends Mock implements LoyaltyRepository {}

void main() {
  late MockLoyaltyRepository mockRepo;
  late ProviderContainer container;

  setUp(() {
    mockRepo = MockLoyaltyRepository();
    container = ProviderContainer(
      overrides: [
        loyaltyRepositoryProvider.overrideWithValue(mockRepo),
      ],
    );
    addTearDown(container.dispose);
  });

  group('LoyaltyRedeemNotifier', () {
    test(
        'redeem met à jour le solde après échange réussi (refetch immédiat '
        'de /loyalty/me)', () async {
      when(() => mockRepo.getAccount()).thenAnswer(
        (_) async => const LoyaltyAccount(
          id: 1,
          userId: 42,
          points: 500,
          pointValueEuros: 5,
        ),
      );

      // loyaltyAccountProvider est `autoDispose` — un listener actif
      // maintient l'état vivant entre la lecture initiale et le refetch
      // déclenché par `LoyaltyRedeemNotifier.redeem` (même précaution que
      // test/features/orders/order_provider_test.dart).
      container.listen(loyaltyAccountProvider, (_, __) {});
      final initial = await container.read(loyaltyAccountProvider.future);
      expect(initial.points, 500);

      // Après l'échange, le serveur renvoie un solde amputé des points
      // dépensés — le refetch doit le refléter immédiatement (DoD plan-16).
      when(() => mockRepo.getAccount()).thenAnswer(
        (_) async => const LoyaltyAccount(
          id: 1,
          userId: 42,
          points: 300,
          pointValueEuros: 3,
        ),
      );
      when(() => mockRepo.getRewards()).thenAnswer((_) async => const []);
      container.listen(loyaltyRewardsProvider, (_, __) {});

      when(() => mockRepo.redeemReward(7)).thenAnswer(
        (_) async => const RedeemResult(
          remainingPoints: 300,
          discountEuros: 5,
          promoCode: 'LOYAL-ABC123',
        ),
      );

      final result = await container.read(loyaltyRedeemProvider).redeem(7);

      expect(result.remainingPoints, 300);
      expect(result.promoCode, 'LOYAL-ABC123');

      final updated = await container.read(loyaltyAccountProvider.future);
      expect(updated.points, 300);
    });

    test(
        'redeem lève une AppException si points insuffisants '
        '(422 INSUFFICIENT_POINTS)', () async {
      when(() => mockRepo.redeemReward(9)).thenThrow(
        const ValidationException(
          fieldErrors: {},
          message: 'Points insuffisants pour cette récompense.',
        ),
      );

      await expectLater(
        container.read(loyaltyRedeemProvider).redeem(9),
        throwsA(isA<AppException>()),
      );
    });
  });
}
