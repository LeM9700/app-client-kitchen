import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:app_client/core/router/app_routes.dart';
import 'package:app_client/features/catalog/widgets/promo_hero_carousel.dart';
import 'package:app_client/features/promotions/models/promotion.dart';
import 'package:app_client/features/promotions/providers/promotions_provider.dart';

const _promo1 = Promotion(
  id: 1,
  code: 'PIZZA20',
  description: '-20% sur les pizzas',
  discountType: DiscountType.percent,
  discountValue: 20,
);
const _promo2 = Promotion(
  id: 2,
  code: 'BOISSON1',
  description: 'Boisson offerte',
  discountType: DiscountType.fixed,
  discountValue: 2.5,
);

Future<void> _pump(
  WidgetTester tester, {
  required List<Promotion> promotions,
}) async {
  final router = GoRouter(
    initialLocation: AppRoutes.home,
    routes: [
      GoRoute(
        path: AppRoutes.home,
        builder: (_, __) => const Scaffold(body: PromoHeroCarousel()),
      ),
      GoRoute(
        path: AppRoutes.promotions,
        builder: (_, __) => const Scaffold(body: Text('Promotions screen')),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        promotionsProvider.overrideWith((ref) async => promotions),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('PromoHeroCarousel', () {
    testWidgets('se masque silencieusement sans promotion active',
        (tester) async {
      await _pump(tester, promotions: []);

      expect(find.byType(PageView), findsNothing);
    });

    testWidgets('affiche la première promo et ses dots', (tester) async {
      await _pump(tester, promotions: [_promo1, _promo2]);

      expect(find.text('-20%'), findsOneWidget);
      expect(find.text('-20% sur les pizzas'), findsOneWidget);
      expect(find.byType(AnimatedContainer), findsNWidgets(2));
    });

    testWidgets('aucun dot si une seule promotion active', (tester) async {
      await _pump(tester, promotions: [_promo1]);

      expect(find.byType(AnimatedContainer), findsNothing);
    });

    testWidgets("tap sur le slide navigue vers l'écran promotions",
        (tester) async {
      await _pump(tester, promotions: [_promo1]);

      await tester.tap(find.text('-20% sur les pizzas'));
      await tester.pumpAndSettle();

      expect(find.text('Promotions screen'), findsOneWidget);
    });
  });
}
