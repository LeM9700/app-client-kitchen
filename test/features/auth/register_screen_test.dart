import 'package:app_client/core/router/app_routes.dart';
import 'package:app_client/features/auth/models/auth_tokens.dart';
import 'package:app_client/features/auth/models/user.dart';
import 'package:app_client/features/auth/providers/auth_provider.dart';
import 'package:app_client/features/auth/repositories/auth_repository.dart';
import 'package:app_client/features/auth/screens/register_screen.dart';
import 'package:app_client/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

const _tokens = AuthTokens(
  accessToken: 'access-token',
  refreshToken: 'refresh-token',
  sessionId: 1,
);

const _user = User(
  id: 1,
  email: null,
  fullName: 'Ada Lovelace',
  phone: '0600000000',
  phoneVerified: true,
  pendingProfileCompletion: false,
);

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  late _MockAuthRepository authRepository;

  setUp(() {
    authRepository = _MockAuthRepository();
  });

  Widget buildApp() {
    final router = GoRouter(
      initialLocation: AppRoutes.register,
      routes: [
        GoRoute(
          path: AppRoutes.register,
          builder: (_, state) => RegisterScreen(
            redirectTo: state.uri.queryParameters['redirect'],
          ),
        ),
        GoRoute(
          path: AppRoutes.login,
          builder: (_, __) => const Scaffold(body: Text('LOGIN_ROUTE')),
        ),
        GoRoute(
          path: AppRoutes.home,
          builder: (_, __) => const Scaffold(body: Text('HOME_ROUTE')),
        ),
      ],
    );
    addTearDown(router.dispose);

    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(authRepository),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('fr'),
      ),
    );
  }

  testWidgets('register phone creates account then verifies SMS code',
      (tester) async {
    when(
      () => authRepository.registerPhone(
        phone: any(named: 'phone'),
        firstName: any(named: 'firstName'),
        lastName: any(named: 'lastName'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => authRepository.verifyPhone(
        phone: any(named: 'phone'),
        code: any(named: 'code'),
      ),
    ).thenAnswer((_) async => _tokens);
    when(() => authRepository.getMe()).thenAnswer((_) async => _user);

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Téléphone').first);
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), '0600000000');
    await tester.enterText(fields.at(1), 'Ada');
    await tester.enterText(fields.at(2), 'Lovelace');

    await tester.ensureVisible(find.byType(Checkbox));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('CRÉER ET ENVOYER LE CODE'));
    await tester.tap(find.text('CRÉER ET ENVOYER LE CODE'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).last, '123456');
    await tester.tap(find.text('VÉRIFIER LE CODE'));
    await tester.pumpAndSettle();

    verify(
      () => authRepository.registerPhone(
        phone: '0600000000',
        firstName: 'Ada',
        lastName: 'Lovelace',
      ),
    ).called(1);
    verify(
      () => authRepository.verifyPhone(phone: '0600000000', code: '123456'),
    ).called(1);
    expect(find.text('HOME_ROUTE'), findsOneWidget);
  });
}
