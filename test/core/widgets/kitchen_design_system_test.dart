import 'package:app_client/core/widgets/kitchen/kitchen_brand_logo.dart';
import 'package:app_client/core/widgets/kitchen/kitchen_embossed_button.dart';
import 'package:app_client/core/widgets/kitchen/kitchen_loading_indicator.dart';
import 'package:app_client/core/widgets/kitchen/kitchen_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Widget wrap(Widget child) {
    return MaterialApp(
      home: Scaffold(body: Center(child: child)),
    );
  }

  testWidgets('KitchenEmbossedButton renders and handles taps', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      wrap(
        KitchenEmbossedButton(
          onPressed: () => taps++,
          child: const Text('Continuer'),
        ),
      ),
    );

    expect(find.text('Continuer'), findsOneWidget);
    await tester.tap(find.text('Continuer'));
    expect(taps, 1);
  });

  testWidgets('KitchenEmbossedButton disabled ignores taps', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      wrap(
        KitchenEmbossedButton(
          onPressed: () => taps++,
          enabled: false,
          child: const Text('Continuer'),
        ),
      ),
    );

    await tester.tap(find.text('Continuer'));
    expect(taps, 0);
  });

  testWidgets('KitchenEmbossedButton loading shows custom indicator',
      (tester) async {
    await tester.pumpWidget(
      wrap(
        KitchenEmbossedButton(
          onPressed: () {},
          isLoading: true,
          child: const Text('Continuer'),
        ),
      ),
    );

    expect(find.byType(KitchenLoadingIndicator), findsOneWidget);
    expect(find.text('Continuer'), findsNothing);
  });

  testWidgets('KitchenTextField preserves validation', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      wrap(
        Form(
          child: KitchenTextField(
            controller: controller,
            label: 'Email',
            validator: (value) =>
                value == null || !value.contains('@') ? 'Email invalide' : null,
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextFormField), 'bad-email');
    Form.of(tester.element(find.byType(KitchenTextField))).validate();
    await tester.pump();

    expect(find.text('Email invalide'), findsOneWidget);
  });

  testWidgets('KitchenBrandLogo uses the local fallback asset', (tester) async {
    await tester.pumpWidget(wrap(const KitchenBrandLogo(logoUrl: '')));

    expect(find.byType(Image), findsOneWidget);
  });
}
