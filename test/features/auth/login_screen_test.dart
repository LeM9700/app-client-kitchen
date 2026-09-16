import 'package:app_client/core/errors/app_exception.dart';
import 'package:app_client/core/router/app_routes.dart';
import 'package:app_client/features/auth/models/auth_tokens.dart';
import 'package:app_client/features/auth/models/user.dart';
import 'package:app_client/features/auth/providers/auth_provider.dart';
import 'package:app_client/features/auth/repositories/auth_repository.dart';
import 'package:app_client/features/auth/screens/login_screen.dart';
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
  email: 'client@test.fr',
  fullName: 'Client Test',
  emailVerified: false,
);

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  late _MockAuthRepository authRepository;

  setUp(() {
    authRepository = _MockAuthRepository();
  });

  Widget buildApp({String initialLocation = AppRoutes.login}) {
    final router = GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(
          path: AppRoutes.login,
          builder: (_, state) => LoginScreen(
            redirectTo: state.uri.queryParameters['redirect'],
          ),
        ),
        GoRoute(
          path: AppRoutes.forgotPassword,
          builder: (_, __) => const Scaffold(body: Text('FORGOT_ROUTE')),
        ),
        GoRoute(
          path: AppRoutes.register,
          builder: (_, __) => const Scaffold(body: Text('REGISTER_ROUTE')),
        ),
        GoRoute(
          path: AppRoutes.home,
          builder: (_, __) => const Scaffold(body: Text('HOME_ROUTE')),
        ),
        GoRoute(
          path: '/target',
          builder: (_, __) => const Scaffold(body: Text('TARGET_ROUTE')),
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

  Future<void> enterValidCredentials(WidgetTester tester) async {
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'client@test.fr');
    await tester.enterText(fields.at(1), 'password123');
  }

  Future<void> tapLoginButton(WidgetTester tester) async {
    final button = find.text('SE CONNECTER');
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
  }

  testWidgets('invalid email and password show validation errors',
      (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tapLoginButton(tester);
    await tester.pump();

    expect(find.text('Email invalide'), findsOneWidget);
    expect(find.text('8 caractères minimum'), findsOneWidget);
  });

  testWidgets('ValidationException displays backend field errors',
      (tester) async {
    when(
      () => authRepository.login(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenThrow(
      const ValidationException(
        fieldErrors: {'email': 'Email inconnu'},
      ),
    );

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    await enterValidCredentials(tester);
    await tapLoginButton(tester);
    await tester.pumpAndSettle();

    expect(find.text('Email inconnu'), findsOneWidget);
  });

  testWidgets('AppException displays a SnackBar', (tester) async {
    when(
      () => authRepository.login(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenThrow(const AuthException('Identifiants invalides.'));

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    await enterValidCredentials(tester);
    await tapLoginButton(tester);
    await tester.pumpAndSettle();

    expect(find.text('Identifiants invalides.'), findsOneWidget);
  });

  testWidgets('success preserves redirectTo', (tester) async {
    when(
      () => authRepository.login(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => _tokens);
    when(() => authRepository.getMe()).thenAnswer((_) async => _user);

    await tester.pumpWidget(
      buildApp(initialLocation: '${AppRoutes.login}?redirect=/target'),
    );
    await tester.pumpAndSettle();
    await enterValidCredentials(tester);
    await tapLoginButton(tester);
    await tester.pumpAndSettle();

    expect(find.text('TARGET_ROUTE'), findsOneWidget);
  });

  testWidgets('forgot password and register links keep navigation',
      (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Mot de passe oublié ?'));
    await tester.pumpAndSettle();
    expect(find.text('FORGOT_ROUTE'), findsOneWidget);

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Créer un compte'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Créer un compte'));
    await tester.pumpAndSettle();
    expect(find.text('REGISTER_ROUTE'), findsOneWidget);
  });
}
