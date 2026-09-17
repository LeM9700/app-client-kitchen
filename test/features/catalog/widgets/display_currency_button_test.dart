import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_client/features/catalog/providers/display_currency_provider.dart';
import 'package:app_client/features/catalog/widgets/display_currency_button.dart';

/// Fake en mémoire — même pattern que
/// test/features/catalog/catalog_provider_test.dart, évite le plugin
/// `shared_preferences` réel.
class _FakeDisplayCurrencyStorage implements DisplayCurrencyStorage {
  String? _value;

  @override
  Future<String?> getSelected() async => _value;

  @override
  Future<void> setSelected(String? code) async => _value = code;
}

Future<ProviderContainer> _pumpButton(WidgetTester tester) async {
  final container = ProviderContainer(
    overrides: [
      displayCurrencyStorageProvider.overrideWithValue(
        _FakeDisplayCurrencyStorage(),
      ),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        home: Scaffold(body: Align(child: DisplayCurrencyButton())),
      ),
    ),
  );
  await tester.pumpAndSettle();

  return container;
}

void main() {
  testWidgets('aucun badge de devise par défaut', (tester) async {
    await _pumpButton(tester);

    expect(find.text('USD'), findsNothing);
  });

  testWidgets('tap ouvre le sélecteur et choisir une devise met à jour le provider + le badge',
      (tester) async {
    final container = await _pumpButton(tester);

    await tester.tap(find.byIcon(Icons.currency_exchange_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Prix indicatif dans votre devise'), findsOneWidget);

    await tester.tap(find.text('USD'));
    await tester.pumpAndSettle();

    expect(container.read(displayCurrencyProvider), 'USD');
    expect(find.text('USD'), findsOneWidget); // badge sur le bouton
  });

  testWidgets('"Aucune conversion" efface la sélection', (tester) async {
    final container = await _pumpButton(tester);
    await container.read(displayCurrencyProvider.notifier).select('EUR');
    await tester.pump();

    await tester.tap(find.byIcon(Icons.currency_exchange_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Aucune conversion'));
    await tester.pumpAndSettle();

    expect(container.read(displayCurrencyProvider), isNull);
  });
}
