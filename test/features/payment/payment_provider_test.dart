import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:app_client/core/analytics/analytics_reporter.dart';
import 'package:app_client/features/cart/providers/cart_provider.dart';
import 'package:app_client/features/catalog/models/product.dart';
import 'package:app_client/features/payment/providers/payment_provider.dart';
import 'package:app_client/features/payment/repositories/payment_repository.dart';
import 'package:app_client/features/payment/services/stripe_payment_sheet_client.dart';

class MockPaymentRepository extends Mock implements PaymentRepository {}

class MockStripePaymentSheetClient extends Mock
    implements StripePaymentSheetClient {}

class _Event {
  const _Event(this.name, this.properties);

  final String name;
  final Map<String, Object?> properties;
}

class _RecordingAnalyticsReporter implements AnalyticsReporter {
  final events = <_Event>[];

  @override
  void track(String eventName, Map<String, Object?> properties) {
    events.add(_Event(eventName, properties));
  }
}

const _orderId = 42;
const _intent = PaymentIntentResult(
  clientSecret: 'pi_123_secret_abc',
  providerPaymentId: 'pi_123',
);
const _product = Product(id: 1, name: 'Margherita', price: 10);

void main() {
  late MockPaymentRepository mockRepo;
  late MockStripePaymentSheetClient mockSheet;
  late _RecordingAnalyticsReporter analytics;
  late ProviderContainer container;

  void stubSuccessfulSheet() {
    when(
      () => mockSheet.initPaymentSheet(
        clientSecret: any(named: 'clientSecret'),
        merchantDisplayName: any(named: 'merchantDisplayName'),
      ),
    ).thenAnswer((_) async {});
    when(() => mockSheet.presentPaymentSheet()).thenAnswer((_) async {});
  }

  setUp(() {
    mockRepo = MockPaymentRepository();
    mockSheet = MockStripePaymentSheetClient();
    analytics = _RecordingAnalyticsReporter();
    container = ProviderContainer(
      overrides: [
        paymentRepositoryProvider.overrideWithValue(mockRepo),
        stripePaymentSheetClientProvider.overrideWithValue(mockSheet),
        analyticsReporterProvider.overrideWithValue(analytics),
      ],
    );
    addTearDown(container.dispose);
    container.listen(paymentProvider, (_, __) {});
  });

  group('PaymentNotifier', () {
    test('initial state is idle without error or intent', () {
      final state = container.read(paymentProvider);

      expect(state.status, PaymentStatus.idle);
      expect(state.error, isNull);
      expect(state.clientSecret, isNull);
      expect(state.providerPaymentId, isNull);
    });

    test('successful payment creates intent, confirms payment and clears cart',
        () async {
      container.read(cartProvider.notifier).addItem(_product, quantity: 2);
      when(() => mockRepo.createPaymentIntent(_orderId))
          .thenAnswer((_) async => _intent);
      when(() => mockRepo.confirmPayment(_intent.providerPaymentId))
          .thenAnswer((_) async {});
      stubSuccessfulSheet();

      final paid = await container.read(paymentProvider.notifier).pay(_orderId);

      expect(paid, true);
      expect(container.read(paymentProvider).status, PaymentStatus.success);
      expect(container.read(cartProvider).isEmpty, true);
      verify(() => mockRepo.createPaymentIntent(_orderId)).called(1);
      verify(
        () => mockSheet.initPaymentSheet(
          clientSecret: _intent.clientSecret,
          merchantDisplayName: "O'Pizza",
        ),
      ).called(1);
      verify(() => mockSheet.presentPaymentSheet()).called(1);
      verify(() => mockRepo.confirmPayment(_intent.providerPaymentId))
          .called(1);
      expect(
        analytics.events.map((event) => event.name),
        containsAllInOrder([
          'payment_started',
          'payment_intent_created',
          'payment_succeeded',
        ]),
      );
    });

    test('cancelled PaymentSheet keeps intent and does not confirm payment',
        () async {
      container.read(cartProvider.notifier).addItem(_product);
      when(() => mockRepo.createPaymentIntent(_orderId))
          .thenAnswer((_) async => _intent);
      when(
        () => mockSheet.initPaymentSheet(
          clientSecret: any(named: 'clientSecret'),
          merchantDisplayName: any(named: 'merchantDisplayName'),
        ),
      ).thenAnswer((_) async {});
      when(() => mockSheet.presentPaymentSheet())
          .thenThrow(const PaymentSheetCancelledException());

      final paid = await container.read(paymentProvider.notifier).pay(_orderId);

      final state = container.read(paymentProvider);
      expect(paid, false);
      expect(state.status, PaymentStatus.idle);
      expect(state.clientSecret, _intent.clientSecret);
      expect(state.providerPaymentId, _intent.providerPaymentId);
      expect(container.read(cartProvider).isEmpty, false);
      verifyNever(() => mockRepo.confirmPayment(any()));
      expect(
        analytics.events.map((event) => event.name),
        containsAllInOrder([
          'payment_started',
          'payment_intent_created',
          'payment_cancelled',
        ]),
      );
    });

    test('failed PaymentSheet keeps intent and exposes retryable error',
        () async {
      when(() => mockRepo.createPaymentIntent(_orderId))
          .thenAnswer((_) async => _intent);
      when(
        () => mockSheet.initPaymentSheet(
          clientSecret: any(named: 'clientSecret'),
          merchantDisplayName: any(named: 'merchantDisplayName'),
        ),
      ).thenAnswer((_) async {});
      when(() => mockSheet.presentPaymentSheet())
          .thenThrow(const PaymentSheetFailureException('Carte refusee.'));

      final paid = await container.read(paymentProvider.notifier).pay(_orderId);

      final state = container.read(paymentProvider);
      expect(paid, false);
      expect(state.status, PaymentStatus.failure);
      expect(state.error, 'Carte refusee.');
      expect(state.clientSecret, _intent.clientSecret);
      expect(state.providerPaymentId, _intent.providerPaymentId);
      verifyNever(() => mockRepo.confirmPayment(any()));
      expect(
        analytics.events.map((event) => event.name),
        containsAllInOrder([
          'payment_started',
          'payment_intent_created',
          'payment_failed',
        ]),
      );
    });

    test('retry after a sheet failure reuses the existing client secret',
        () async {
      var sheetAttempts = 0;
      container.read(cartProvider.notifier).addItem(_product);
      when(() => mockRepo.createPaymentIntent(_orderId))
          .thenAnswer((_) async => _intent);
      when(() => mockRepo.confirmPayment(_intent.providerPaymentId))
          .thenAnswer((_) async {});
      when(
        () => mockSheet.initPaymentSheet(
          clientSecret: any(named: 'clientSecret'),
          merchantDisplayName: any(named: 'merchantDisplayName'),
        ),
      ).thenAnswer((_) async {});
      when(() => mockSheet.presentPaymentSheet()).thenAnswer((_) async {
        sheetAttempts += 1;
        if (sheetAttempts == 1) {
          throw const PaymentSheetFailureException('Carte refusee.');
        }
      });

      final notifier = container.read(paymentProvider.notifier);
      expect(await notifier.pay(_orderId), false);
      expect(await notifier.pay(_orderId), true);

      verify(() => mockRepo.createPaymentIntent(_orderId)).called(1);
      verify(
        () => mockSheet.initPaymentSheet(
          clientSecret: _intent.clientSecret,
          merchantDisplayName: any(named: 'merchantDisplayName'),
        ),
      ).called(2);
      verify(() => mockSheet.presentPaymentSheet()).called(2);
      verify(() => mockRepo.confirmPayment(_intent.providerPaymentId))
          .called(1);
      expect(container.read(cartProvider).isEmpty, true);
      expect(
        analytics.events.map((event) => event.name),
        containsAllInOrder([
          'payment_started',
          'payment_intent_created',
          'payment_failed',
          'payment_started',
          'payment_intent_reused',
          'payment_succeeded',
        ]),
      );
    });

    test('reset() returns to the initial state', () async {
      when(() => mockRepo.createPaymentIntent(_orderId))
          .thenAnswer((_) async => _intent);
      when(
        () => mockSheet.initPaymentSheet(
          clientSecret: any(named: 'clientSecret'),
          merchantDisplayName: any(named: 'merchantDisplayName'),
        ),
      ).thenAnswer((_) async {});
      when(() => mockSheet.presentPaymentSheet())
          .thenThrow(const PaymentSheetFailureException('Carte refusee.'));

      final notifier = container.read(paymentProvider.notifier);
      await notifier.pay(_orderId);

      expect(container.read(paymentProvider).clientSecret, isNotNull);

      notifier.reset();

      final state = container.read(paymentProvider);
      expect(state.status, PaymentStatus.idle);
      expect(state.error, isNull);
      expect(state.clientSecret, isNull);
      expect(state.providerPaymentId, isNull);
    });
  });
}
