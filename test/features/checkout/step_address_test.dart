import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:mocktail/mocktail.dart';

import 'package:app_client/core/analytics/analytics_reporter.dart';
import 'package:app_client/core/errors/app_exception.dart';
import 'package:app_client/features/catalog/repositories/catalog_repository.dart';
import 'package:app_client/features/catalog/providers/catalog_provider.dart';
import 'package:app_client/features/checkout/models/address_models.dart';
import 'package:app_client/features/checkout/models/checkout_state.dart';
import 'package:app_client/features/checkout/models/delivery_info.dart';
import 'package:app_client/features/checkout/providers/checkout_provider.dart';
import 'package:app_client/features/checkout/repositories/address_repository.dart';
import 'package:app_client/features/checkout/repositories/checkout_repository.dart';
import 'package:app_client/features/checkout/screens/steps/step_address.dart';
import 'package:app_client/features/checkout/services/device_location_service.dart';
import 'package:app_client/l10n/app_localizations.dart';

class MockCheckoutRepository extends Mock implements CheckoutRepository {}

class MockCatalogRepository extends Mock implements CatalogRepository {}

class MockAddressRepository extends Mock implements AddressRepository {}

class _FakeLocation implements DeviceLocationService {
  _FakeLocation({this.point, this.failure});

  final LatLng? point;
  final DeviceLocationFailure? failure;

  @override
  Future<LatLng> currentPosition() async {
    if (failure != null) throw DeviceLocationException(failure!);
    return point!;
  }
}

class _NoopAnalyticsReporter implements AnalyticsReporter {
  const _NoopAnalyticsReporter();

  @override
  void track(String eventName, Map<String, Object?> properties) {}
}

void main() {
  late MockCheckoutRepository mockCheckoutRepo;
  late MockCatalogRepository mockCatalogRepo;
  late MockAddressRepository mockAddressRepo;
  late ProviderContainer container;

  Future<void> pumpStepAddress(
    WidgetTester tester, {
    LatLng? initialPoint,
    DeviceLocationService? location,
  }) async {
    container = ProviderContainer(
      overrides: [
        checkoutRepositoryProvider.overrideWithValue(mockCheckoutRepo),
        catalogRepositoryProvider.overrideWithValue(mockCatalogRepo),
        addressRepositoryProvider.overrideWithValue(mockAddressRepo),
        deliveryAvailabilityProvider.overrideWith(
          (ref) async => const DeliveryAvailability(deliveryEnabled: true),
        ),
        deviceLocationServiceProvider.overrideWithValue(
          location ?? _FakeLocation(point: const LatLng(48.8566, 2.3522)),
        ),
        // Couche factice qui remplit la carte : sans elle (SizedBox.shrink) la carte n'a aucune
        // zone cliquable tant qu'aucun repere n'existe, alors que la vraie couche de tuiles couvre la carte.
        addressMapTileLayerProvider.overrideWithValue(
          const ColoredBox(color: Color(0xFFEEEEEE), child: SizedBox.expand()),
        ),
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
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('fr'),
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
    final button = find.byKey(const ValueKey('check-delivery-zone-button'));
    await tester.scrollUntilVisible(
      button,
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(button);
    await tester.pump();
  }

  setUp(() {
    mockCheckoutRepo = MockCheckoutRepository();
    mockCatalogRepo = MockCatalogRepository();
    mockAddressRepo = MockAddressRepository();
    when(
      () => mockAddressRepo.geocode(
        any(),
        lat: any(named: 'lat'),
        lng: any(named: 'lng'),
        language: any(named: 'language'),
      ),
    ).thenAnswer((_) async => const []);
    when(
      () => mockAddressRepo.reverse(
        any(),
        any(),
        language: any(named: 'language'),
      ),
    ).thenAnswer((_) async => null);
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
          subtotal: any(named: 'subtotal'),
          establishmentId: any(named: 'establishmentId'),
        ),
      );
    });

    testWidgets('requires a map pin after the address is entered',
        (tester) async {
      await pumpStepAddress(tester);
      await tester.enterText(
          find.byKey(const ValueKey('delivery-address-field')),
          '12 rue de la Paix',);

      await tapCheckZone(tester);

      expect(find.textContaining('point sur la carte'), findsOneWidget);
      verifyNever(
        () => mockCheckoutRepo.checkDeliveryZone(
          lat: any(named: 'lat'),
          lng: any(named: 'lng'),
          displayAddress: any(named: 'displayAddress'),
          subtotal: any(named: 'subtotal'),
          establishmentId: any(named: 'establishmentId'),
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
          subtotal: any(named: 'subtotal'),
          establishmentId: any(named: 'establishmentId'),
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
      await tester.enterText(
          find.byKey(const ValueKey('delivery-address-field')),
          '12 rue de la Paix',);
      await tester.enterText(
        find.byKey(const ValueKey('delivery-phone-field')),
        '06 12 34 56 78',
      );

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
          subtotal: any(named: 'subtotal'),
          establishmentId: any(named: 'establishmentId'),
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
          subtotal: any(named: 'subtotal'),
          establishmentId: any(named: 'establishmentId'),
        ),
      ).thenThrow(DeliveryZoneUnreachableException());

      await pumpStepAddress(
        tester,
        initialPoint: const LatLng(48.8566, 2.3522),
      );
      await tester.enterText(
          find.byKey(const ValueKey('delivery-address-field')),
          '12 rue de la Paix',);
      await tester.enterText(
        find.byKey(const ValueKey('delivery-phone-field')),
        '06 12 34 56 78',
      );

      await tapCheckZone(tester);
      await tester.pump();

      final state = container.read(checkoutProvider);
      expect(state.currentStep, CheckoutStep.address);
      expect(state.deliveryInfo, isNull);
      expect(state.error, contains('hors zone'));
      expect(find.textContaining('hors zone'), findsOneWidget);
    });

    testWidgets('requires a phone number before checking the zone',
        (tester) async {
      await pumpStepAddress(
        tester,
        initialPoint: const LatLng(48.8566, 2.3522),
      );
      await tester.enterText(
        find.byKey(const ValueKey('delivery-address-field')),
        '12 rue de la Paix',
      );

      await tapCheckZone(tester);

      expect(find.textContaining('numéro de téléphone'), findsOneWidget);
      verifyNever(
        () => mockCheckoutRepo.checkDeliveryZone(
          lat: any(named: 'lat'),
          lng: any(named: 'lng'),
          displayAddress: any(named: 'displayAddress'),
          subtotal: any(named: 'subtotal'),
          establishmentId: any(named: 'establishmentId'),
        ),
      );
    });

    testWidgets('rejects an invalid phone number', (tester) async {
      await pumpStepAddress(
        tester,
        initialPoint: const LatLng(48.8566, 2.3522),
      );
      await tester.enterText(
        find.byKey(const ValueKey('delivery-address-field')),
        '12 rue de la Paix',
      );
      await tester.enterText(
        find.byKey(const ValueKey('delivery-phone-field')),
        'abc',
      );

      await tapCheckZone(tester);

      expect(find.textContaining('semble invalide'), findsOneWidget);
      verifyNever(
        () => mockCheckoutRepo.checkDeliveryZone(
          lat: any(named: 'lat'),
          lng: any(named: 'lng'),
          displayAddress: any(named: 'displayAddress'),
          subtotal: any(named: 'subtotal'),
          establishmentId: any(named: 'establishmentId'),
        ),
      );
    });

    testWidgets('keeps phone and instructions in the checkout state',
        (tester) async {
      when(
        () => mockCheckoutRepo.checkDeliveryZone(
          lat: any(named: 'lat'),
          lng: any(named: 'lng'),
          displayAddress: any(named: 'displayAddress'),
          subtotal: any(named: 'subtotal'),
          establishmentId: any(named: 'establishmentId'),
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
      await tester.enterText(
        find.byKey(const ValueKey('delivery-address-field')),
        '12 rue de la Paix',
      );
      await tester.enterText(
        find.byKey(const ValueKey('delivery-phone-field')),
        ' 06 12 34 56 78 ',
      );
      await tester.enterText(
        find.byKey(const ValueKey('delivery-instructions-field')),
        '3e etage, code 4521',
      );

      await tapCheckZone(tester);
      await tester.pump();

      final state = container.read(checkoutProvider);
      expect(state.phone, '06 12 34 56 78');
      expect(state.instructions, '3e etage, code 4521');
      expect(state.lat, 48.8566);
      expect(state.lng, 2.3522);
    });

    test('isValidDeliveryPhone mirrors the server rule', () {
      expect(isValidDeliveryPhone('+33 6 12 34 56 78'), isTrue);
      expect(isValidDeliveryPhone('064/123-4567'), isFalse);
      expect(isValidDeliveryPhone('12345'), isFalse);
      expect(isValidDeliveryPhone('abc'), isFalse);
      expect(isValidDeliveryPhone(''), isFalse);
    });
  });

  group('StepAddress - recherche d\'adresse, carte et position', () {
    const rivoli = AddressSuggestion(
      label: '12 Rue de Rivoli, 75004 Paris',
      lat: 48.8566,
      lng: 2.3522,
    );

    void stubCheck(DeliveryInfo info) {
      when(
        () => mockCheckoutRepo.checkDeliveryZone(
          lat: any(named: 'lat'),
          lng: any(named: 'lng'),
          displayAddress: any(named: 'displayAddress'),
          subtotal: any(named: 'subtotal'),
          establishmentId: any(named: 'establishmentId'),
        ),
      ).thenAnswer((_) async => info);
    }

    void stubGeocode(List<AddressSuggestion> results) {
      when(
        () => mockAddressRepo.geocode(
          any(),
          lat: any(named: 'lat'),
          lng: any(named: 'lng'),
          language: any(named: 'language'),
        ),
      ).thenAnswer((_) async => results);
    }

    Future<void> typeAddress(WidgetTester tester, String text) async {
      await tester.enterText(
        find.byKey(const ValueKey('delivery-address-field')),
        text,
      );
      await tester.pump(const Duration(milliseconds: 400)); // anti-rebond
      await tester.pump();
    }

    Future<void> tapMap(WidgetTester tester) async {
      await tester.tapAt(tester.getCenter(find.byType(FlutterMap)));
      // flutter_map attend la fin du delai de double-tap avant de signaler un tap simple.
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();
    }

    const info = DeliveryInfo(
      zoneId: 7,
      name: 'Centre',
      fee: 2.5,
      estimatedMinutes: 30,
      establishmentId: 3,
    );

    testWidgets('suggests addresses while typing, then previews the fee',
        (tester) async {
      stubGeocode(const [rivoli]);
      stubCheck(info);
      await pumpStepAddress(tester);

      await typeAddress(tester, '12 rue de rivoli');
      final suggestion =
          find.byKey(ValueKey('address-suggestion-${rivoli.label}'));
      expect(suggestion, findsOneWidget);

      await tester.ensureVisible(suggestion);
      await tester.pump();
      await tester.tap(suggestion);
      await tester.pump();
      await tester.pump();

      final state = container.read(checkoutProvider);
      expect(
          state.currentStep, CheckoutStep.address,); // apercu : on n'avance pas
      expect(state.address, isNull); // pas memorisee avant « continuer »
      expect(state.lat, 48.8566);
      expect(state.deliveryInfo?.establishmentId, 3);
      expect(find.byKey(const ValueKey('address-suggestions')), findsNothing);
      expect(find.text(rivoli.label), findsOneWidget); // dans le champ
      expect(find.textContaining('Frais de livraison'), findsOneWidget);
      expect(find.textContaining('Centre - 30 min'), findsOneWidget);
    });

    testWidgets('does not search before three characters', (tester) async {
      await pumpStepAddress(tester);
      await typeAddress(tester, 'ru');
      verifyNever(
        () => mockAddressRepo.geocode(
          any(),
          lat: any(named: 'lat'),
          lng: any(named: 'lng'),
          language: any(named: 'language'),
        ),
      );
    });

    testWidgets('only the last keystrokes trigger a search (debounce)',
        (tester) async {
      await pumpStepAddress(tester);
      await tester.enterText(
          find.byKey(const ValueKey('delivery-address-field')), '12 r',);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.enterText(
          find.byKey(const ValueKey('delivery-address-field')), '12 rue',);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.enterText(
          find.byKey(const ValueKey('delivery-address-field')), '12 rue de',);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();

      verify(
        () => mockAddressRepo.geocode(
          '12 rue de',
          lat: any(named: 'lat'),
          lng: any(named: 'lng'),
          language: any(named: 'language'),
        ),
      ).called(1);
    });

    testWidgets('keeps the map usable when address search is unavailable',
        (tester) async {
      when(
        () => mockAddressRepo.geocode(
          any(),
          lat: any(named: 'lat'),
          lng: any(named: 'lng'),
          language: any(named: 'language'),
        ),
      ).thenThrow(const DeliveryException('GEOCODING_UNAVAILABLE', 'down'));
      stubCheck(info);
      await pumpStepAddress(tester);

      await typeAddress(tester, '12 rue de rivoli');
      expect(
          find.byKey(const ValueKey('address-search-problem')), findsOneWidget,);
      expect(find.textContaining('indisponible'), findsWidgets);

      await tapMap(tester); // le repere fonctionne sans la recherche
      expect(container.read(checkoutProvider).deliveryInfo?.zoneId, 7);
    });

    testWidgets('rate limiting shows its own message', (tester) async {
      when(
        () => mockAddressRepo.geocode(
          any(),
          lat: any(named: 'lat'),
          lng: any(named: 'lng'),
          language: any(named: 'language'),
        ),
      ).thenThrow(const DeliveryException('RATE_LIMITED', 'slow down'));
      await pumpStepAddress(tester);

      await typeAddress(tester, '12 rue de rivoli');
      expect(find.textContaining('Trop de recherches'), findsOneWidget);
    });

    testWidgets('tapping the map fills an empty address and previews',
        (tester) async {
      stubCheck(info);
      when(
        () => mockAddressRepo.reverse(any(), any(),
            language: any(named: 'language'),),
      ).thenAnswer((_) async => rivoli);
      await pumpStepAddress(tester);

      await tapMap(tester);

      expect(find.text(rivoli.label), findsOneWidget);
      expect(container.read(checkoutProvider).deliveryInfo?.zoneId, 7);
    });

    testWidgets('tapping the map never overwrites an address typed by the user',
        (tester) async {
      stubCheck(info);
      when(
        () => mockAddressRepo.reverse(any(), any(),
            language: any(named: 'language'),),
      ).thenAnswer((_) async => rivoli);
      await pumpStepAddress(tester);
      await typeAddress(tester, '3 chemin des Vignes');

      await tapMap(tester);

      expect(find.text('3 chemin des Vignes'), findsOneWidget);
      expect(find.text(rivoli.label), findsNothing);
      verifyNever(
        () => mockAddressRepo.reverse(any(), any(),
            language: any(named: 'language'),),
      );
    });

    testWidgets('my position places the pin and previews the fee',
        (tester) async {
      stubCheck(info);
      await pumpStepAddress(
        tester,
        location: _FakeLocation(point: const LatLng(48.86, 2.34)),
      );

      await tester.tap(find.byKey(const ValueKey('use-my-position-button')));
      await tester.pump();
      await tester.pump();

      final state = container.read(checkoutProvider);
      expect((state.lat, state.lng), (48.86, 2.34));
      expect(state.deliveryInfo?.zoneId, 7);
    });

    testWidgets('a denied location permission explains what to do',
        (tester) async {
      await pumpStepAddress(
        tester,
        location:
            _FakeLocation(failure: DeviceLocationFailure.permissionDenied),
      );

      await tester.tap(find.byKey(const ValueKey('use-my-position-button')));
      await tester.pump();

      expect(find.textContaining('Autorisez la localisation'), findsOneWidget);
      expect(container.read(checkoutProvider).lat, isNull);
    });

    testWidgets('location services switched off use the generic message',
        (tester) async {
      await pumpStepAddress(
        tester,
        location: _FakeLocation(failure: DeviceLocationFailure.serviceDisabled),
      );
      await tester.tap(find.byKey(const ValueKey('use-my-position-button')));
      await tester.pump();
      expect(find.textContaining('Impossible d\'obtenir votre position'),
          findsOneWidget,);
    });

    testWidgets('free delivery and the amount missing to get it are shown',
        (tester) async {
      stubCheck(
        const DeliveryInfo(
          zoneId: 7,
          name: 'Centre',
          fee: 3,
          estimatedMinutes: 30,
          remainingForFree: 5,
        ),
      );
      await pumpStepAddress(tester,
          initialPoint: const LatLng(48.8566, 2.3522),);
      await tapMap(tester);
      expect(find.textContaining('Plus que 5.00'), findsOneWidget);

      stubCheck(
        const DeliveryInfo(
          zoneId: 7,
          name: 'Centre',
          fee: 0,
          estimatedMinutes: 30,
          freeDelivery: true,
          appliedLabel: 'Offerte des 25',
        ),
      );
      await tapMap(tester);
      expect(find.textContaining('Livraison offerte'), findsOneWidget);
      expect(find.textContaining('Plus que'), findsNothing);
    });

    testWidgets('below the zone minimum: message with the amount, no advance',
        (tester) async {
      stubCheck(
        const DeliveryInfo(
          zoneId: 7,
          name: 'Centre',
          fee: 2.5,
          estimatedMinutes: 30,
          minOrderAmount: 15,
          minOrderMet: false,
        ),
      );
      await pumpStepAddress(tester,
          initialPoint: const LatLng(48.8566, 2.3522),);
      await tester.enterText(
          find.byKey(const ValueKey('delivery-address-field')),
          '12 rue de la Paix',);
      await tester.enterText(
          find.byKey(const ValueKey('delivery-phone-field')), '06 12 34 56 78',);

      await tapCheckZone(tester);
      await tester.pump();

      final state = container.read(checkoutProvider);
      expect(state.currentStep, CheckoutStep.address);
      expect(state.errorCode, 'DELIVERY_MIN_ORDER_NOT_MET');
      expect(find.textContaining('Minimum de commande pour cette zone : 15.00'),
          findsOneWidget,);
    });

    testWidgets('delivery switched off by the restaurant is explained',
        (tester) async {
      when(
        () => mockCheckoutRepo.checkDeliveryZone(
          lat: any(named: 'lat'),
          lng: any(named: 'lng'),
          displayAddress: any(named: 'displayAddress'),
          subtotal: any(named: 'subtotal'),
          establishmentId: any(named: 'establishmentId'),
        ),
      ).thenThrow(const DeliveryException('DELIVERY_DISABLED', 'off'));
      await pumpStepAddress(tester);

      await tapMap(tester);

      expect(find.textContaining('momentanément indisponible'), findsOneWidget);
      expect(container.read(checkoutProvider).errorCode, 'DELIVERY_DISABLED');
    });

    testWidgets('the checkout sends the establishment found by the zone check',
        (tester) async {
      stubCheck(info);
      await pumpStepAddress(tester,
          initialPoint: const LatLng(48.8566, 2.3522),);
      await tester.enterText(
          find.byKey(const ValueKey('delivery-address-field')),
          '12 rue de la Paix',);
      await tester.enterText(
          find.byKey(const ValueKey('delivery-phone-field')), '06 12 34 56 78',);
      await tapCheckZone(tester);
      await tester.pump();

      final state = container.read(checkoutProvider);
      expect(state.currentStep, CheckoutStep.recap);
      expect(state.deliveryInfo?.establishmentId, 3);
    });
  });
}
