import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:mocktail/mocktail.dart';

import 'package:app_client/core/analytics/analytics_reporter.dart';
import 'package:app_client/features/catalog/repositories/catalog_repository.dart';
import 'package:app_client/features/catalog/providers/catalog_provider.dart';
import 'package:app_client/features/checkout/models/checkout_state.dart';
import 'package:app_client/features/checkout/models/delivery_info.dart';
import 'package:app_client/features/checkout/providers/checkout_provider.dart';
import 'package:app_client/features/checkout/repositories/checkout_repository.dart';
import 'package:app_client/features/checkout/screens/steps/step_address.dart';

class MockCheckoutRepository extends Mock implements CheckoutRepository {}

class MockCatalogRepository extends Mock implements CatalogRepository {}

class _NoopAnalyticsReporter implements AnalyticsReporter {
  const _NoopAnalyticsReporter();

  @override
  void track(String eventName, Map<String, Object?> properties) {}
}

void main() {
  late MockCheckoutRepository mockCheckoutRepo;
  late MockCatalogRepository mockCatalogRepo;
  late ProviderContainer container;

  Future<void> pumpStepAddress(
    WidgetTester tester, {
    LatLng? initialPoint,
  }) async {
    container = ProviderContainer(
      overrides: [
        checkoutRepositoryProvider.overrideWithValue(mockCheckoutRepo),
        catalogRepositoryProvider.overrideWithValue(mockCatalogRepo),
        addressMapTileLayerProvider.overrideWithValue(const SizedBox.shrink()),
        if (initialPoint != null)
          addressInitialPointProvider.overrideWithValue(initialPoint),
        analyticsReporterProvider.overrideWithValue(
          const _NoopAnalyticsReporter(),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.listen(checkoutProvider, (_, __) {});
    container
        .read(checkoutProvider.notifier)
        .selectDeliveryMode(DeliveryMode.delivery);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 420,
              height: 760,
              child: StepAddress(),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> tapCheckZone(WidgetTester tester) async {
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();
  }

  setUp(() {
    mockCheckoutRepo = MockCheckoutRepository();
    mockCatalogRepo = MockCatalogRepository();
  });

  group('StepAddress', () {
    testWidgets('requires a non-empty delivery address', (tester) async {
      await pumpStepAddress(tester);

      await tapCheckZone(tester);

      expect(find.textContaining('adresse de livraison'), findsOneWidget);
      verifyNever(
        () => mockCheckoutRepo.checkDeliveryZone(
          lat: any(named: 'lat'),
          lng: any(named: 'lng'),
          displayAddress: any(named: 'displayAddress'),
        ),
      );
    });

    testWidgets('requires a map pin after the address is entered',
        (tester) async {
      await pumpStepAddress(tester);
      await tester.enterText(find.byType(TextField), '12 rue de la Paix');

      await tapCheckZone(tester);

      expect(find.textContaining('point sur la carte'), findsOneWidget);
      verifyNever(
        () => mockCheckoutRepo.checkDeliveryZone(
          lat: any(named: 'lat'),
          lng: any(named: 'lng'),
          displayAddress: any(named: 'displayAddress'),
        ),
      );
    });

    testWidgets('moves to recap when the selected point is deliverable',
        (tester) async {
      when(
        () => mockCheckoutRepo.checkDeliveryZone(
          lat: any(named: 'lat'),
          lng: any(named: 'lng'),
          displayAddress: any(named: 'displayAddress'),
        ),
      ).thenAnswer(
        (_) async => const DeliveryInfo(
          zoneId: 7,
          name: 'Centre',
          fee: 2.5,
          estimatedMinutes: 30,
        ),
      );

      await pumpStepAddress(
        tester,
        initialPoint: const LatLng(48.8566, 2.3522),
      );
      await tester.enterText(find.byType(TextField), '12 rue de la Paix');

      await tapCheckZone(tester);
      await tester.pump();

      final state = container.read(checkoutProvider);
      expect(state.currentStep, CheckoutStep.recap);
      expect(state.address, '12 rue de la Paix');
      expect(state.deliveryInfo?.zoneId, 7);
      verify(
        () => mockCheckoutRepo.checkDeliveryZone(
          lat: any(named: 'lat'),
          lng: any(named: 'lng'),
          displayAddress: '12 rue de la Paix',
        ),
      ).called(1);
    });

    testWidgets('shows a clear error when the selected point is outside zone',
        (tester) async {
      when(
        () => mockCheckoutRepo.checkDeliveryZone(
          lat: any(named: 'lat'),
          lng: any(named: 'lng'),
          displayAddress: any(named: 'displayAddress'),
        ),
      ).thenThrow(DeliveryZoneUnreachableException());

      await pumpStepAddress(
        tester,
        initialPoint: const LatLng(48.8566, 2.3522),
      );
      await tester.enterText(find.byType(TextField), '12 rue de la Paix');

      await tapCheckZone(tester);
      await tester.pump();

      final state = container.read(checkoutProvider);
      expect(state.currentStep, CheckoutStep.address);
      expect(state.deliveryInfo, isNull);
      expect(state.error, contains('hors zone'));
      expect(find.textContaining('hors zone'), findsOneWidget);
    });
  });
}
