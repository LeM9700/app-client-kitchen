import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import 'package:app_client/core/api/api_client.dart';
import 'package:app_client/core/api/api_endpoints.dart';
import 'package:app_client/core/config/env.dart';

/// Firebase Messaging service.
///
/// The service is best-effort by design: missing dev Firebase config, denied
/// notification permission, offline startup or unauthenticated boot must never
/// block the customer journey. Release builds still require Firebase config via
/// [Env.validateForRelease].
class PushNotificationService {
  const PushNotificationService._();

  static StreamSubscription<String>? _tokenRefreshSubscription;
  static StreamSubscription<RemoteMessage>? _foregroundSubscription;
  static StreamSubscription<RemoteMessage>? _openedAppSubscription;

  static Future<void> initialize({
    required ApiClient apiClient,
    required GoRouter router,
  }) async {
    final messaging = _messagingOrNull();
    if (messaging == null) return;

    try {
      await messaging.requestPermission(alert: true, badge: true, sound: true);

      await _tokenRefreshSubscription?.cancel();
      _tokenRefreshSubscription = messaging.onTokenRefresh.listen(
        (token) => unawaited(_registerToken(apiClient, token)),
      );

      await _foregroundSubscription?.cancel();
      _foregroundSubscription = FirebaseMessaging.onMessage.listen((_) {});

      await _openedAppSubscription?.cancel();
      _openedAppSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
        (message) => _handleDeepLink(router, message.data),
      );

      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        unawaited(
          Future<void>.delayed(
            const Duration(milliseconds: 500),
            () => _handleDeepLink(router, initialMessage.data),
          ),
        );
      }

      await registerDeviceToken(apiClient);
    } catch (_) {
      // Best-effort, see class documentation.
    }
  }

  static Future<void> registerDeviceToken(ApiClient apiClient) async {
    final messaging = _messagingOrNull();
    if (messaging == null) return;

    try {
      final token = await messaging.getToken(vapidKey: _webVapidKey);
      if (token == null) return;
      await _registerToken(apiClient, token);
    } catch (_) {
      // Best-effort, see class documentation.
    }
  }

  static FirebaseMessaging? _messagingOrNull() {
    if (Firebase.apps.isEmpty) return null;
    try {
      return FirebaseMessaging.instance;
    } catch (_) {
      return null;
    }
  }

  static Future<void> _registerToken(ApiClient apiClient, String token) async {
    try {
      await apiClient.post<void>(
        ApiEndpoints.notificationsDevices,
        data: {
          'platform': _platformName,
          'token': token,
        },
      );
    } catch (_) {
      // Offline, 401 at boot, or backend unavailable: push registration will be
      // retried after login or on the next token refresh.
    }
  }

  static String? get _webVapidKey {
    if (!kIsWeb || Env.firebaseWebVapidKey.trim().isEmpty) return null;
    return Env.firebaseWebVapidKey;
  }

  static String get _platformName {
    if (kIsWeb) return 'web';
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'android',
      TargetPlatform.iOS => 'ios',
      TargetPlatform.macOS => 'macos',
      TargetPlatform.linux => 'linux',
      TargetPlatform.windows => 'windows',
      TargetPlatform.fuchsia => 'fuchsia',
    };
  }

  static void _handleDeepLink(GoRouter router, Map<String, dynamic> data) {
    final route = trackingRouteFromMessageData(data);
    if (route == null) return;
    router.push(route);
  }

  static String? trackingRouteFromMessageData(Map<String, dynamic> data) {
    final rawOrderId = data['order_id'];
    final orderId = switch (rawOrderId) {
      int value => value,
      String value => int.tryParse(value),
      _ => null,
    };
    if (orderId == null || orderId <= 0) return null;
    return '/orders/$orderId/tracking';
  }
}
