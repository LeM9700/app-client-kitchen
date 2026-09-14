import 'package:flutter/foundation.dart';

import 'package:app_client/core/config/env.dart';

import 'package:app_client/core/monitoring/error_reporter_base.dart';
import 'package:app_client/core/monitoring/sentry_error_reporter.dart';
import 'package:app_client/core/monitoring/telemetry_sanitizer.dart';

export 'package:app_client/core/monitoring/error_reporter_base.dart';
export 'package:app_client/core/monitoring/telemetry_sanitizer.dart';

abstract final class ErrorReporting {
  static ErrorReporter reporter = kDebugMode
      ? const DebugPrintErrorReporter()
      : (Env.sentryDsn.trim().isNotEmpty
          ? const SentryErrorReporter()
          : const NoopErrorReporter());

  static Future<void> recordError(
    Object error,
    StackTrace stackTrace, {
    bool fatal = false,
    Map<String, Object?> context = const {},
  }) {
    return reporter.recordError(
      error,
      stackTrace,
      fatal: fatal,
      context: context,
    );
  }

  static Future<void> recordFlutterError(
    FlutterErrorDetails details, {
    bool fatal = false,
    Map<String, Object?> context = const {},
  }) {
    return recordError(
      details.exception,
      details.stack ?? StackTrace.current,
      fatal: fatal,
      context: {
        ...context,
        if (details.library != null) 'library': details.library,
        if (details.context != null)
          'flutter_context': details.context.toString(),
      },
    );
  }
}

class NoopErrorReporter implements ErrorReporter {
  const NoopErrorReporter();

  @override
  Future<void> recordError(
    Object error,
    StackTrace stackTrace, {
    bool fatal = false,
    Map<String, Object?> context = const {},
  }) async {}
}

class DebugPrintErrorReporter implements ErrorReporter {
  const DebugPrintErrorReporter();

  @override
  Future<void> recordError(
    Object error,
    StackTrace stackTrace, {
    bool fatal = false,
    Map<String, Object?> context = const {},
  }) async {
    if (!kDebugMode) return;
    final sanitizedError = TelemetrySanitizer.sanitizeValue(error.toString());
    final sanitizedContext = TelemetrySanitizer.sanitizeMap(context);
    debugPrint(
      '[error] fatal=$fatal error=$sanitizedError context=$sanitizedContext',
    );
  }
}
