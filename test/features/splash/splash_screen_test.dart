import 'dart:async';

import 'package:app_client/core/api/api_client.dart';
import 'package:app_client/core/models/tenant_branding.dart';
import 'package:app_client/core/providers/api_client_provider.dart';
import 'package:app_client/core/repositories/branding_repository.dart';
import 'package:app_client/core/router/app_router.dart';
import 'package:app_client/core/router/app_routes.dart';
import 'package:app_client/core/theme/tenant_theme_provider.dart';
import 'package:app_client/features/onboarding/providers/onboarding_provider.dart';
import 'package:app_client/features/splash/screens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';

class _MockApiClient extends Mock implements ApiClient {}

class _MockBrandingRepository extends Mock implements BrandingRepository {}

class _FakeOnboardingStorage extends OnboardingStorage {
  _FakeOnboardingStorage({required this.completed});

  final bool completed;

  @override
  Future<bool> isCompleted() async => completed;
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  late _MockApiClient apiClient;
  late _MockBrandingRepository brandingRepository;

  Widget buildApp({
    required OnboardingStorage onboardingStorage,
    Completer<TenantBranding>? brandingCompleter,
  }) {
    apiClient = _MockApiClient();
    brandingRepository = _MockBrandingRepository();
    when(() => apiClient.setTenantSlug(any())).thenReturn(null);
    when(() => brandingRepository.fetchBranding(any())).thenAnswer(
      (_) => brandingCompleter?.future ?? Future.value(TenantBranding.demo()),
    );

    final router = GoRouter(
      initialLocation: AppRoutes.splash,
      routes: [
        GoRoute(
          path: AppRoutes.splash,
          builder: (_, __) => const SplashScreen(),
        ),
        GoRoute(
          path: AppRoutes.onboarding,
          builder: (_, __) =>
              const Scaffold(body: Text('ONBOARDING_DESTINATION')),
        ),
        GoRoute(
          path: AppRoutes.home,
          builder: (_, __) => const Scaffold(body: Text('HOME_DESTINATION')),
        ),
      ],
    );
    addTearDown(router.dispose);

    return ProviderScope(
      overrides: [
        apiClientProvider.overrideWithValue(apiClient),
        brandingRepositoryProvider.overrideWithValue(brandingRepository),
        onboardingStorageProvider.overrideWithValue(onboardingStorage),
        routerProvider.overrideWithValue(router),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  testWidgets('boot runs and first launch navigates to onboarding',
      (tester) async {
    await tester.pumpWidget(
      buildApp(
        onboardingStorage: _FakeOnboardingStorage(completed: false),
      ),
    );
    await tester.pumpAndSettle();

    verify(() => apiClient.setTenantSlug(any())).called(1);
    verify(() => brandingRepository.fetchBranding(any())).called(1);
    expect(find.text('ONBOARDING_DESTINATION'), findsOneWidget);
  });

  testWidgets('completed onboarding navigates to home', (tester) async {
    await tester.pumpWidget(
      buildApp(
        onboardingStorage: _FakeOnboardingStorage(completed: true),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('HOME_DESTINATION'), findsOneWidget);
  });

  testWidgets('background is present while boot is pending', (tester) async {
    final completer = Completer<TenantBranding>();
    await tester.pumpWidget(
      buildApp(
        onboardingStorage: _FakeOnboardingStorage(completed: true),
        brandingCompleter: completer,
      ),
    );
    await tester.pump();

    expect(find.byType(Image), findsWidgets);

    completer.complete(TenantBranding.demo());
    await tester.pumpAndSettle();
  });

  testWidgets('does not navigate after dispose', (tester) async {
    final completer = Completer<TenantBranding>();
    await tester.pumpWidget(
      buildApp(
        onboardingStorage: _FakeOnboardingStorage(completed: true),
        brandingCompleter: completer,
      ),
    );
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());

    completer.complete(TenantBranding.demo());
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
