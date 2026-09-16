import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:app_client/core/api/api_endpoints.dart';
import 'package:app_client/core/config/env.dart';
import 'package:app_client/core/providers/api_client_provider.dart';
import 'package:app_client/core/providers/auth_token_provider.dart';
import 'package:app_client/features/notifications/models/app_notification.dart';
import 'package:app_client/features/tracking/services/push_notification_service.dart';

class NotificationsState {
  const NotificationsState({
    this.notifications = const [],
    this.isConnected = false,
    this.isLoading = false,
    this.isRegisteringPush = false,
    this.error,
  });

  final List<AppNotification> notifications;
  final bool isConnected;
  final bool isLoading;
  final bool isRegisteringPush;
  final String? error;

  int get unreadCount =>
      notifications.where((notification) => !notification.isRead).length;

  NotificationsState copyWith({
    List<AppNotification>? notifications,
    bool? isConnected,
    bool? isLoading,
    bool? isRegisteringPush,
    Object? error = _unset,
  }) {
    return NotificationsState(
      notifications: notifications ?? this.notifications,
      isConnected: isConnected ?? this.isConnected,
      isLoading: isLoading ?? this.isLoading,
      isRegisteringPush: isRegisteringPush ?? this.isRegisteringPush,
      error: error == _unset ? this.error : error as String?,
    );
  }
}

const Object _unset = Object();

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, NotificationsState>(
  (ref) => NotificationsNotifier(ref),
);

final unreadNotificationsProvider = Provider<int>((ref) {
  return ref.watch(notificationsProvider).unreadCount;
});

class NotificationsNotifier extends StateNotifier<NotificationsState> {
  NotificationsNotifier(this._ref) : super(const NotificationsState()) {
    final initialToken = _ref.read(accessTokenProvider);
    if (initialToken != null) {
      _startForToken(initialToken);
    }
    _ref.listen<String?>(accessTokenProvider, (previous, next) {
      if (previous == next) return;
      if (next == null) {
        _stop(clearState: true);
      } else {
        _startForToken(next);
      }
    });
  }

  final Ref _ref;
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  Timer? _reconnectTimer;
  String? _token;
  String? _storageKey;
  int _retryCount = 0;

  static const _reconnectDelays = [
    Duration(seconds: 1),
    Duration(seconds: 2),
    Duration(seconds: 4),
    Duration(seconds: 8),
    Duration(seconds: 16),
    Duration(seconds: 30),
  ];

  Future<void> requestPushPermission() async {
    if (_ref.read(accessTokenProvider) == null) return;
    state = state.copyWith(isRegisteringPush: true, error: null);
    try {
      final configured =
          await PushNotificationService.requestPermissionAndRegister(
        _ref.read(apiClientProvider),
      );
      state = state.copyWith(
        isRegisteringPush: false,
        error: configured
            ? null
            : 'Firebase web push n est pas configure sur cette build.',
      );
    } catch (_) {
      state = state.copyWith(
        isRegisteringPush: false,
        error: 'Impossible d activer les notifications push.',
      );
    }
  }

  void markRead(String id) {
    final now = DateTime.now().toUtc();
    final updated = [
      for (final notification in state.notifications)
        notification.id == id && !notification.isRead
            ? notification.copyWith(readAt: now)
            : notification,
    ];
    _setNotifications(updated);
  }

  void markAllRead() {
    final now = DateTime.now().toUtc();
    final updated = [
      for (final notification in state.notifications)
        notification.isRead ? notification : notification.copyWith(readAt: now),
    ];
    _setNotifications(updated);
  }

  void delete(String id) {
    _setNotifications(
      state.notifications
          .where((notification) => notification.id != id)
          .toList(),
    );
  }

  void _startForToken(String token) {
    _stop(clearState: false);
    _token = token;
    _storageKey = _storageKeyForToken(token);
    unawaited(_loadFromDisk(token));
    _connect();
  }

  Future<void> _loadFromDisk(String token) async {
    state = state.copyWith(isLoading: true);
    final key = _storageKeyForToken(token);
    final prefs = await SharedPreferences.getInstance();
    if (_token != token) return;

    final rawItems = prefs.getStringList(key) ?? const [];
    final notifications = <AppNotification>[];
    for (final raw in rawItems) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          notifications.add(AppNotification.fromJson(decoded));
        }
      } catch (_) {
        // Ignore a single corrupted local notification.
      }
    }
    notifications.sort(_newestFirst);
    state = state.copyWith(
      notifications: notifications,
      isLoading: false,
      error: null,
    );
  }

  void _connect() {
    final token = _token;
    if (token == null) return;

    try {
      final channel = WebSocketChannel.connect(_buildWsUri());
      _channel = channel;
      _subscription = channel.stream.listen(
        _handleRawMessage,
        onError: (_) => _onStreamClosed(),
        onDone: _onStreamClosed,
      );
    } catch (_) {
      _scheduleReconnect();
    }
  }

  Uri _buildWsUri() {
    final wsBase = Env.apiBaseUrl.replaceFirst('http', 'ws');
    return Uri.parse('$wsBase${ApiEndpoints.wsNotifications}')
        .replace(queryParameters: {'tenant_slug': Env.tenantSlug});
  }

  void _handleRawMessage(dynamic raw) {
    if (raw is! String) return;
    final Map<String, dynamic> json;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return;
      json = decoded;
    } catch (_) {
      return;
    }

    switch (json['type']) {
      case 'auth_required':
        _send({'type': 'auth', 'token': _token});
        break;
      case 'auth_ok':
        _retryCount = 0;
        state = state.copyWith(isConnected: true, error: null);
        break;
      case 'ping':
        _send({'type': 'pong'});
        break;
      case 'notification':
        _addNotification(AppNotification.fromSocketMessage(json));
        break;
      case 'error':
        state = state.copyWith(
          isConnected: false,
          error: 'Connexion notifications interrompue.',
        );
        break;
      default:
        break;
    }
  }

  void _send(Map<String, dynamic> payload) {
    _channel?.sink.add(jsonEncode(payload));
  }

  void _addNotification(AppNotification notification) {
    final deduped = [
      notification,
      ...state.notifications.where((item) => item.id != notification.id),
    ]..sort(_newestFirst);

    _setNotifications(deduped.take(100).toList());
  }

  void _setNotifications(List<AppNotification> notifications) {
    notifications.sort(_newestFirst);
    state = state.copyWith(notifications: notifications);
    unawaited(_saveToDisk(notifications));
  }

  Future<void> _saveToDisk(List<AppNotification> notifications) async {
    final key = _storageKey;
    if (key == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      key,
      notifications
          .map((notification) => jsonEncode(notification.toJson()))
          .toList(),
    );
  }

  void _onStreamClosed() {
    if (_subscription == null && _channel == null) return;
    unawaited(_subscription?.cancel());
    _subscription = null;
    _channel = null;
    state = state.copyWith(isConnected: false);
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_token == null) return;
    _reconnectTimer?.cancel();
    final index = _retryCount.clamp(0, _reconnectDelays.length - 1);
    final delay = _reconnectDelays[index];
    _retryCount++;
    _reconnectTimer = Timer(delay, _connect);
  }

  void _stop({required bool clearState}) {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    unawaited(_subscription?.cancel());
    _subscription = null;
    unawaited(_channel?.sink.close());
    _channel = null;
    _token = null;
    _storageKey = null;
    _retryCount = 0;
    if (clearState) {
      state = const NotificationsState();
    } else {
      state = state.copyWith(isConnected: false);
    }
  }

  @override
  void dispose() {
    _stop(clearState: false);
    super.dispose();
  }
}

int _newestFirst(AppNotification a, AppNotification b) {
  return b.timestamp.compareTo(a.timestamp);
}

String _storageKeyForToken(String token) {
  final userId = _subjectFromJwt(token) ?? token.split('.').take(2).join('.');
  return 'notifications:${Env.tenantSlug}:$userId';
}

String? _subjectFromJwt(String token) {
  final parts = token.split('.');
  if (parts.length < 2) return null;
  try {
    final payload =
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
    final decoded = jsonDecode(payload);
    if (decoded is Map<String, dynamic>) {
      final sub = decoded['sub'];
      if (sub != null) return '$sub';
    }
  } catch (_) {
    return null;
  }
  return null;
}
