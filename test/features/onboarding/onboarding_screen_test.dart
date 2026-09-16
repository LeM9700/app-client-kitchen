import 'package:app_client/core/router/app_routes.dart';
import 'package:app_client/features/onboarding/providers/onboarding_provider.dart';
import 'package:app_client/features/onboarding/screens/onboarding_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class _FakeOnboardingStorage extends OnboardingStorage {
  bool completed = false;

  @override
  Future<bool> isCompleted() async => completed;

  @override
  Future<void> setCompleted() async {
    completed = true;
  }
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Widget buildApp(_FakeOnboardingStorage storage) {
    final router = GoRouter(
      initialLocation: AppRoutes.onboarding,
      routes: [
        GoRoute(
          path: AppRoutes.onboarding,
          builder: (_, __) => const OnboardingScreen(),
        ),
        GoRoute(
          path: AppRoutes.home,
          builder: (_, __) => const Scaffold(body: Text('HOME_READY')),
        ),
      ],
    );
    addTearDown(router.dispose);

    return ProviderScope(
      overrides: [
        onboardingStorageProvider.overrideWithValue(storage),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  testWidgets('page 1 is displayed', (tester) async {
    await tester.pumpWidget(buildApp(_FakeOnboardingStorage()));
    await tester.pumpAndSettle();

    expect(find.text('Des ingrédients\nsélectionnés'), findsOneWidget);
    expect(
      find.text(
        'Des produits frais et de qualité\npour des pizzas authentiques.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('swipe displays page 2', (tester) async {
    await tester.pumpWidget(buildApp(_FakeOnboardingStorage()));
    await tester.pumpAndSettle();

    await tester.dragFrom(
      tester.getCenter(find.byType(PageView)),
      const Offset(-700, 0),
    );
    await tester.pumpAndSettle();

    expect(find.text('Préparées\navec passion'), findsOneWidget);
  });

  testWidgets('Passer persists completion and navigates home', (tester) async {
    final storage = _FakeOnboardingStorage();
    await tester.pumpWidget(buildApp(storage));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Passer'));
    await tester.pumpAndSettle();

    expect(storage.completed, isTrue);
    expect(find.text('HOME_READY'), findsOneWidget);
  });

  testWidgets('Terminer persists completion and navigates home',
      (tester) async {
    final storage = _FakeOnboardingStorage();
    await tester.pumpWidget(buildApp(storage));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.arrow_forward_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.arrow_forward_rounded));
    await tester.pumpAndSettle();

    expect(storage.completed, isTrue);
    expect(find.text('HOME_READY'), findsOneWidget);
  });
}
