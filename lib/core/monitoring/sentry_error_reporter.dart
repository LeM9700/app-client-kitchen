import 'package:sentry_flutter/sentry_flutter.dart';

import 'package:app_client/core/monitoring/error_reporter_base.dart';
import 'package:app_client/core/monitoring/telemetry_sanitizer.dart';

/// Sends errors to Sentry in release builds. Context and the error message
/// are routed through [TelemetrySanitizer] first so tokens, secrets and PII
/// never leave the device.
class SentryErrorReporter implements ErrorReporter {
  const SentryErrorReporter();

  @override
  Future<void> recordError(
    Object error,
    StackTrace stackTrace, {
    bool fatal = false,
    Map<String, Object?> context = const {},
  }) async {
    final sanitizedContext = TelemetrySanitizer.sanitizeMap(context);
    await Sentry.captureException(
      TelemetrySanitizer.sanitizeValue(error.toString()),
      stackTrace: stackTrace,
      withScope: (scope) {
        scope.level = fatal ? SentryLevel.fatal : SentryLevel.error;
        if (sanitizedContext.isNotEmpty) {
          scope.setContexts('app_context', sanitizedContext);
        }
      },
    );
  }
}
