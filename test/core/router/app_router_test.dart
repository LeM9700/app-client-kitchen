import 'package:app_client/core/router/app_router.dart';
import 'package:app_client/core/router/app_routes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('appRouterRedirect', () {
    test('onboarding is public', () {
      expect(
        appRouterRedirect(
          isAuthenticated: false,
          location: AppRoutes.onboarding,
        ),
        isNull,
      );
    });

    test('home is public', () {
      expect(
        appRouterRedirect(isAuthenticated: false, location: AppRoutes.home),
        isNull,
      );
    });

    test('checkout stays protected', () {
      final redirect = appRouterRedirect(
        isAuthenticated: false,
        location: AppRoutes.checkout,
      );

      expect(redirect, startsWith(AppRoutes.login));
      expect(redirect, contains(Uri.encodeComponent(AppRoutes.checkout)));
    });

    test('settings stays protected through account guard', () {
      final redirect = appRouterRedirect(
        isAuthenticated: false,
        location: AppRoutes.settings,
      );

      expect(redirect, startsWith(AppRoutes.login));
      expect(redirect, contains(Uri.encodeComponent(AppRoutes.settings)));
    });

    test('favorites stays protected through account guard', () {
      final redirect = appRouterRedirect(
        isAuthenticated: false,
        location: AppRoutes.favorites,
      );

      expect(redirect, startsWith(AppRoutes.login));
      expect(redirect, contains(Uri.encodeComponent(AppRoutes.favorites)));
    });

    test('unauthenticated launch is not redirected to login', () {
      expect(
        appRouterRedirect(isAuthenticated: false, location: AppRoutes.splash),
        isNull,
      );
    });

    test('authenticated users keep existing auth-screen redirect', () {
      expect(
        appRouterRedirect(isAuthenticated: true, location: AppRoutes.login),
        AppRoutes.home,
      );
    });
  });
}
