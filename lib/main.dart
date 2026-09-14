import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'package:app_client/core/config/env.dart';
import 'package:app_client/core/config/firebase_env_options.dart';
import 'package:app_client/core/monitoring/error_reporter.dart';
import 'package:app_client/core/router/app_router.dart';
import 'package:app_client/core/theme/tenant_theme_provider.dart';

Future<void> main() async {
  await runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      if (Env.sentryDsn.trim().isNotEmpty) {
        await Sentry.init((options) {
          options.dsn = Env.sentryDsn;
          options.environment = Env.appEnvironment;
          // Performance tracing is not needed for error reporting alone.
          options.tracesSampleRate = 0.0;
          // Error capture stays funneled through ErrorReporting below —
          // this is the base `Sentry.init`, not `SentryFlutter.init`, so no
          // Flutter-specific auto integrations (FlutterError.onError, etc.)
          // get installed on top of the existing manual wiring.
        });
      }

      FlutterError.onError = (details) {
        FlutterError.presentError(details);
        unawaited(ErrorReporting.recordFlutterError(details, fatal: true));
      };
      PlatformDispatcher.instance.onError = (error, stackTrace) {
        unawaited(
          ErrorReporting.recordError(
            error,
            stackTrace,
            fatal: true,
            context: const {'source': 'platform_dispatcher'},
          ),
        );
        return false;
      };

      Env.validateForRelease();

      final firebaseOptions = FirebaseEnvOptions.currentPlatform;
      if (firebaseOptions != null) {
        await Firebase.initializeApp(options: firebaseOptions);
      }

      if (_supportsNativeStripe()) {
        Stripe.publishableKey = Env.stripePublishableKey;
        Stripe.merchantIdentifier = Env.appleMerchantIdentifier;
        await Stripe.instance.applySettings();
      }

      runApp(
        const ProviderScope(child: AppRoot()),
      );
    },
    (error, stackTrace) {
      unawaited(
        ErrorReporting.recordError(
          error,
          stackTrace,
          fatal: true,
          context: const {'source': 'root_zone'},
        ),
      );
    },
  );
}

bool _supportsNativeStripe() {
  if (kIsWeb) {
    return false;
  }
  return defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;
}

class AppRoot extends ConsumerWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(appThemeProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: "O'Pizza",
      theme: theme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
