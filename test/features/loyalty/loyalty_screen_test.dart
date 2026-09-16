import 'package:app_client/features/loyalty/models/loyalty_account.dart';
import 'package:app_client/features/loyalty/models/loyalty_reward.dart';
import 'package:app_client/features/loyalty/providers/loyalty_provider.dart';
import 'package:app_client/features/loyalty/repositories/loyalty_repository.dart';
import 'package:app_client/features/loyalty/screens/loyalty_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';

class _MockLoyaltyRepository extends Mock implements LoyaltyRepository {}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  late _MockLoyaltyRepository repo;

  setUp(() {
    repo = _MockLoyaltyRepository();
    when(() => repo.getAccount()).thenAnswer(
      (_) async => const LoyaltyAccount(
        id: 1,
        userId: 1,
        points: 120,
        pointValueEuros: 1.2,
      ),
    );
    when(() => repo.getRewards()).thenAnswer(
      (_) async => const [
        LoyaltyReward(
          id: 1,
          name: 'Réduction atelier',
          rewardType: LoyaltyRewardType.discountEuros,
          pointsRequired: 100,
          discountAmount: 5,
          canRedeem: true,
          missingPoints: 0,
        ),
        LoyaltyReward(
          id: 2,
          name: 'Pizza offerte',
          rewardType: LoyaltyRewardType.freeProduct,
          pointsRequired: 150,
          canRedeem: false,
          missingPoints: 30,
        ),
      ],
    );
    when(
      () => repo.getTransactions(
        page: any(named: 'page'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer(
      (_) async => const LoyaltyTransactionPage(
        items: [],
        page: 1,
        limit: 20,
        total: 0,
      ),
    );
  });

  Widget buildApp() {
    return ProviderScope(
      overrides: [loyaltyRepositoryProvider.overrideWithValue(repo)],
      child: const MaterialApp(home: LoyaltyScreen()),
    );
  }

  testWidgets('affiche balance et rewards réels', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('120 points'), findsOneWidget);
    expect(find.text('Réduction atelier'), findsOneWidget);
    expect(find.text('Pizza offerte'), findsOneWidget);
    expect(find.text('Disponible'), findsOneWidget);
    expect(find.text('Verrouillée'), findsOneWidget);
    expect(find.text('Encore 30'), findsOneWidget);
    expect(find.text('MEMBRE GOURMAND'), findsNothing);
  });
}
