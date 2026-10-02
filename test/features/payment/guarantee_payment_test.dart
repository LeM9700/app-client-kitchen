import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:app_client/core/analytics/analytics_reporter.dart';
import 'package:app_client/features/orders/models/order.dart';
import 'package:app_client/features/orders/providers/order_provider.dart';
import 'package:app_client/features/payment/providers/payment_provider.dart';
import 'package:app_client/features/payment/repositories/payment_repository.dart';
import 'package:app_client/features/payment/screens/payment_screen.dart';
import 'package:app_client/features/payment/services/stripe_payment_sheet_client.dart';
import 'package:app_client/features/tracking/models/order_status.dart';
import 'package:app_client/l10n/app_localizations.dart';

class _MockRepo extends Mock implements PaymentRepository {}

class _MockSheet extends Mock implements StripePaymentSheetClient {}

class _NoopAnalytics implements AnalyticsReporter {
  @override
  void track(String eventName, Map<String, Object?> properties) {}
}

const _orderId = 7;
const _terms = GuaranteeTerms(version: '2026-10-02', holdValidityDays: 7);
const _saleIntent = PaymentIntentResult(
  clientSecret: 'pi_sale_secret',
  providerPaymentId: 'pi_sale',
);
const _holdIntent = PaymentIntentResult(
  clientSecret: 'pi_hold_secret',
  providerPaymentId: 'pi_hold',
);

Order _order({
  OrderType type = OrderType.delivery,
  String paymentStatus = 'pending',
}) =>
    Order(
      id: _orderId,
      orderType: type,
      status: OrderStatusCode.pending,
      paymentStatus: paymentStatus,
      subtotal: 22,
      discountTotal: 0,
      deliveryFee: 3,
      total: 25,
    );

void main() {
  late _MockRepo repo;
  late _MockSheet sheet;

  setUp(() {
    repo = _MockRepo();
    sheet = _MockSheet();
    when(
      () => sheet.initPaymentSheet(
        clientSecret: any(named: 'clientSecret'),
        merchantDisplayName: any(named: 'merchantDisplayName'),
      ),
    ).thenAnswer((_) async {});
    when(() => sheet.presentPaymentSheet()).thenAnswer((_) async {});
    when(() => repo.confirmPayment(any())).thenAnswer((_) async {});
    when(() => repo.fetchGuaranteeTerms()).thenAnswer((_) async => _terms);
    when(() => repo.createPaymentIntent(_orderId))
        .thenAnswer((_) async => _saleIntent);
    when(() => repo.createGuaranteeIntent(_orderId, _terms.version))
        .thenAnswer((_) async => _holdIntent);
  });

  group('PaymentNotifier empreinte bancaire', () {
    ProviderContainer makeContainer() {
      final container = ProviderContainer(
        overrides: [
          paymentRepositoryProvider.overrideWithValue(repo),
          stripePaymentSheetClientProvider.overrideWithValue(sheet),
          analyticsReporterProvider.overrideWithValue(_NoopAnalytics()),
        ],
      );
      addTearDown(container.dispose);
      container.listen(paymentProvider, (_, __) {});
      return container;
    }

    test('uses the guarantee intent with the accepted terms version',
        () async {
      final container = makeContainer();

      final ok = await container
          .read(paymentProvider.notifier)
          .pay(_orderId, guarantee: _terms);

      expect(ok, true);
      expect(container.read(paymentProvider).status, PaymentStatus.success);
      verify(() => repo.createGuaranteeIntent(_orderId, '2026-10-02'))
          .called(1);
      verifyNever(() => repo.createPaymentIntent(any()));
      verify(
        () => sheet.initPaymentSheet(
          clientSecret: 'pi_hold_secret',
          merchantDisplayName: any(named: 'merchantDisplayName'),
        ),
      ).called(1);
      // La finalisation passe par le meme /payments/confirm (le serveur aiguille).
      verify(() => repo.confirmPayment('pi_hold')).called(1);
    });

    test('never reuses a guarantee intent for an immediate payment', () async {
      final container = makeContainer();
      when(() => sheet.presentPaymentSheet())
          .thenThrow(const PaymentSheetCancelledException());

      await container
          .read(paymentProvider.notifier)
          .pay(_orderId, guarantee: _terms);
      expect(container.read(paymentProvider).onDelivery, true);
      expect(container.read(paymentProvider).clientSecret, 'pi_hold_secret');

      // Le client change d'avis : paiement immediat. L'empreinte ne doit pas servir.
      when(() => sheet.presentPaymentSheet()).thenAnswer((_) async {});
      await container.read(paymentProvider.notifier).pay(_orderId);

      verify(() => repo.createPaymentIntent(_orderId)).called(1);
      verify(
        () => sheet.initPaymentSheet(
          clientSecret: 'pi_sale_secret',
          merchantDisplayName: any(named: 'merchantDisplayName'),
        ),
      ).called(1);
      verify(() => repo.confirmPayment('pi_sale')).called(1);
      verifyNever(() => repo.confirmPayment('pi_hold'));
    });

    test('a cancelled sheet keeps the guarantee intent for a retry', () async {
      final container = makeContainer();
      when(() => sheet.presentPaymentSheet())
          .thenThrow(const PaymentSheetCancelledException());

      await container
          .read(paymentProvider.notifier)
          .pay(_orderId, guarantee: _terms);
      await container
          .read(paymentProvider.notifier)
          .pay(_orderId, guarantee: _terms);

      verify(() => repo.createGuaranteeIntent(_orderId, any())).called(1);
      verifyNever(() => repo.confirmPayment(any()));
    });
  });

  group('PaymentScreen', () {
    Future<void> pumpScreen(WidgetTester tester, Order order) async {
      // Grande surface : la liste est paresseuse, les conditions sont sous le pli.
      tester.view.physicalSize = const Size(800, 2600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final router = GoRouter(
        initialLocation: '/pay',
        routes: [
          GoRoute(
            path: '/pay',
            builder: (_, __) => const PaymentScreen(orderId: _orderId),
          ),
          GoRoute(
            path: '/orders/:id/tracking',
            builder: (_, __) => const Scaffold(body: Text('tracking-screen')),
          ),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            paymentRepositoryProvider.overrideWithValue(repo),
            stripePaymentSheetClientProvider.overrideWithValue(sheet),
            analyticsReporterProvider.overrideWithValue(_NoopAnalytics()),
            orderDetailProvider(_orderId).overrideWith((ref) async => order),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            locale: const Locale('fr'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('pickup orders are not offered pay-on-delivery',
        (tester) async {
      await pumpScreen(tester, _order(type: OrderType.pickup));

      expect(find.text('Payer à la livraison'), findsNothing);
      expect(find.text('Payer 25.00 €'), findsWidgets);
    });

    testWidgets('an already guaranteed order is not offered a second hold',
        (tester) async {
      await pumpScreen(tester, _order(paymentStatus: 'guaranteed'));

      expect(find.text('Payer à la livraison'), findsNothing);
    });

    testWidgets('delivery: terms must be accepted before the hold is placed',
        (tester) async {
      await pumpScreen(tester, _order());
      expect(find.text('Payer à la livraison'), findsOneWidget);

      await tester.tap(find.text('Payer à la livraison'));
      await tester.pumpAndSettle();

      // Conditions affichees, bouton inactif tant qu'elles ne sont pas acceptees.
      expect(find.textContaining('Aucun débit n'), findsOneWidget);
      expect(find.textContaining('sous 7 jours'), findsOneWidget);
      final cta = find.text('Laisser mon empreinte (25.00 €)');
      expect(cta, findsWidgets);
      await tester.tap(cta.first);
      await tester.pumpAndSettle();
      verifyNever(() => repo.createGuaranteeIntent(any(), any()));

      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
      await tester.tap(cta.first);
      await tester.pumpAndSettle();

      verify(() => repo.createGuaranteeIntent(_orderId, '2026-10-02'))
          .called(1);
      verifyNever(() => repo.createPaymentIntent(any()));
      expect(find.text('tracking-screen'), findsOneWidget);
    });

    testWidgets('switching mode resets the acceptance', (tester) async {
      await pumpScreen(tester, _order());

      await tester.tap(find.text('Payer à la livraison'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
      expect(
        tester.widget<Checkbox>(find.byType(Checkbox)).value,
        true,
      );

      await tester.tap(find.text('Payer maintenant').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Payer à la livraison'));
      await tester.pumpAndSettle();

      expect(
        tester.widget<Checkbox>(find.byType(Checkbox)).value,
        false,
      );
    });

    testWidgets('terms load failure is explained and can be retried',
        (tester) async {
      when(() => repo.fetchGuaranteeTerms()).thenAnswer(
        (_) async => throw Exception('network'),
      );
      await pumpScreen(tester, _order());

      await tester.tap(find.text('Payer à la livraison'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Impossible de charger les conditions'),
        findsOneWidget,
      );
      expect(find.byType(Checkbox), findsNothing);

      when(() => repo.fetchGuaranteeTerms()).thenAnswer((_) async => _terms);
      await tester.tap(find.text('Réessayer').first);
      await tester.pumpAndSettle();
      expect(find.byType(Checkbox), findsOneWidget);
    });
  });
}
