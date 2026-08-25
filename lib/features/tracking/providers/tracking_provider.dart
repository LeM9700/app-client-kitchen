import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:app_client/core/config/env.dart';
import 'package:app_client/core/api/api_endpoints.dart';
import 'package:app_client/core/providers/auth_token_provider.dart';
import 'package:app_client/features/orders/models/order.dart';
import 'package:app_client/features/orders/providers/order_provider.dart';
import 'package:app_client/features/orders/repositories/order_repository.dart';
// [🔧] Requis pour la méthode d'extension `isTerminal` sur [OrderStatusCode]
// (`OrderStatusCodeX`) — les extensions ne sont visibles que si leur
// bibliothèque déclarante est importée directement, pas transitivement via
// `order.dart`.
import 'package:app_client/features/tracking/models/order_status.dart';

/// Suivi de commande en temps réel — voir
/// `docs/superpowers/specs/plans/base/api-corrections-phase-d.md` §4 pour le
/// protocole complet. Résumé des écarts vs. le plan d'origine (Plan 14) :
///
/// - Un seul canal générique `GET /ws/notifications?tenant_slug=...` (pas de
///   canal par commande) : il faut donc **filtrer** les messages sur
///   `event.startsWith('order.')` ET `data.order_id == orderId`.
/// - Handshake en 3 temps : connexion → `auth_required` (serveur) →
///   `{"type":"auth","token":...}` (client) → `auth_ok`/`error`+close.
/// - Heartbeat obligatoire : `ping` (serveur, toutes les 30s) → `pong`
///   (client, sous 10s) sous peine de déconnexion silencieuse.
/// - Le message `notification` ne contient jamais l'état complet de la
///   commande (seulement `order_id`) : chaque event pertinent déclenche un
///   refetch `GET /orders/{id}`.
/// - Certaines transitions sont silencieuses (`*→queued`, `ready→out_for_delivery`)
///   → polling de secours en plus du WebSocket.
///
/// [Consolidation Plan 14→15] Ce fichier utilisait initialement un modèle
/// `TrackedOrder`/`TrackingOrderRepository` minimal et autonome (Plan 15 pas
/// encore exécuté à l'époque). Plan 15 ayant depuis introduit le modèle
/// `Order`/`OrderRepository` complet (`lib/features/orders/`), ce notifier a
/// été basculé dessus — `TrackedOrder`/`TrackingOrderRepository` ont été
/// supprimés, plus aucune référence ici.

// ─────────────────────────────────────────────────────────────────────────
// Abstraction du canal — permet l'injection d'un canal factice dans les
// tests sans dépendre du détail interne de `web_socket_channel` (SDK Flutter
// indisponible dans cette session pour vérifier son API exacte à l'aveugle).
// ─────────────────────────────────────────────────────────────────────────

/// Sous-ensemble minimal de [WebSocketChannel] utilisé par [TrackingNotifier].
abstract class TrackingSocket {
  Stream<dynamic> get stream;
  void send(String data);
  Future<void> close();
}

class _WebSocketChannelSocket implements TrackingSocket {
  _WebSocketChannelSocket(this._channel);
  final WebSocketChannel _channel;

  @override
  Stream<dynamic> get stream => _channel.stream;

  @override
  void send(String data) => _channel.sink.add(data);

  @override
  Future<void> close() async {
    await _channel.sink.close();
  }
}

typedef TrackingSocketFactory = TrackingSocket Function(Uri uri);

TrackingSocket _defaultSocketFactory(Uri uri) =>
    _WebSocketChannelSocket(WebSocketChannel.connect(uri));

/// Backoff de reconnexion par défaut : 1s, 2s, 4s, 8s, 16s, puis 30s en
/// plateau (idée reprise du Plan 14 d'origine, seul point resté valide).
const List<Duration> defaultReconnectDelays = [
  Duration(seconds: 1),
  Duration(seconds: 2),
  Duration(seconds: 4),
  Duration(seconds: 8),
  Duration(seconds: 16),
  Duration(seconds: 30),
];

/// Intervalle du polling de secours (transitions silencieuses, voir §4).
const Duration defaultPollInterval = Duration(seconds: 35);

// ─────────────────────────────────────────────────────────────────────────
// État
// ─────────────────────────────────────────────────────────────────────────

class TrackingState {
  const TrackingState({
    this.order,
    this.isConnected = false,
    this.isLoadingOrder = false,
    this.error,
  });

  final Order? order;
  final bool isConnected;
  final bool isLoadingOrder;
  final String? error;

  bool get isTerminal => order?.status.isTerminal ?? false;
}

// ─────────────────────────────────────────────────────────────────────────
// Notifier
// ─────────────────────────────────────────────────────────────────────────

class TrackingNotifier extends StateNotifier<TrackingState> {
  TrackingNotifier(
    this._ref,
    this._orderId, {
    required OrderRepository orderRepository,
    TrackingSocketFactory? socketFactory,
    List<Duration> reconnectDelays = defaultReconnectDelays,
    Duration pollInterval = defaultPollInterval,
  })  : _orderRepository = orderRepository,
        _socketFactory = socketFactory ?? _defaultSocketFactory,
        _reconnectDelays = reconnectDelays,
        _pollInterval = pollInterval,
        super(const TrackingState()) {
    // État initial : fetch direct (affiche quelque chose sans attendre un
    // event WS) + connexion WS + polling de secours en parallèle.
    unawaited(_fetchOrder());
    _connect();
    _startPolling();
  }

  final Ref _ref;
  final int _orderId;
  final OrderRepository _orderRepository;
  final TrackingSocketFactory _socketFactory;
  final List<Duration> _reconnectDelays;
  final Duration _pollInterval;

  TrackingSocket? _socket;
  StreamSubscription<dynamic>? _subscription;
  Timer? _reconnectTimer;
  Timer? _pollTimer;
  int _retryCount = 0;

  // ───────────────────────────────────────────────────────────────────────
  // Connexion / reconnexion
  // ───────────────────────────────────────────────────────────────────────

  void _connect() {
    final uri = _buildWsUri();
    try {
      final socket = _socketFactory(uri);
      _socket = socket;
      _subscription = socket.stream.listen(
        _handleRawMessage,
        onError: (_) => _onStreamClosed(),
        onDone: _onStreamClosed,
      );
    } catch (_) {
      // Échec SYNCHRONE de `_socketFactory` (ex. URI invalide) — aucune
      // souscription n'a jamais existé, donc on ne doit PAS passer par
      // `_onStreamClosed` (son garde-fou `_subscription == null` la ferait
      // sortir immédiatement sans jamais programmer de reconnexion, un bug
      // qui laisserait le notifier bloqué déconnecté pour toujours).
      _scheduleReconnectUnlessTerminal();
    }
  }

  Uri _buildWsUri() {
    // 'http://x'.replaceFirst('http','ws') -> 'ws://x'
    // 'https://x'.replaceFirst('http','ws') -> 'wss://x' (le remplacement
    // touche déjà les 4 premiers caractères 'http' communs aux deux schémas).
    final wsBase = Env.apiBaseUrl.replaceFirst('http', 'ws');
    return Uri.parse('$wsBase${ApiEndpoints.wsNotifications}')
        .replace(queryParameters: {'tenant_slug': Env.tenantSlug});
  }

  /// Callback `onError`/`onDone` du flux — idempotent : une même coupure
  /// peut déclencher `onError` puis `onDone` (ou l'inverse selon la
  /// plateforme), le garde-fou `_subscription == null` évite de traiter la
  /// déconnexion deux fois.
  void _onStreamClosed() {
    if (_subscription == null) return;
    _subscription?.cancel();
    _subscription = null;
    _socket = null;
    _scheduleReconnectUnlessTerminal();
  }

  void _scheduleReconnectUnlessTerminal() {
    if (state.isTerminal) {
      // [Corrections §4 / DoD] Pas de reconnexion sur un état terminal.
      return;
    }
    state = TrackingState(
      order: state.order,
      isConnected: false,
      isLoadingOrder: state.isLoadingOrder,
      error: 'Connexion perdue. Reconnexion...',
    );
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    final index = _retryCount.clamp(0, _reconnectDelays.length - 1);
    final delay = _reconnectDelays[index];
    _retryCount++;
    _reconnectTimer = Timer(delay, _connect);
  }

  void _stopReconnecting() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  // ───────────────────────────────────────────────────────────────────────
  // Protocole (handshake, heartbeat, notifications)
  // ───────────────────────────────────────────────────────────────────────

  void _handleRawMessage(dynamic raw) {
    if (raw is! String) return;
    final Map<String, dynamic> json;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return;
      json = decoded;
    } catch (_) {
      return; // message illisible — ignoré, pas une raison de se déconnecter.
    }

    switch (json['type']) {
      case 'auth_required':
        _sendAuth();
        break;
      case 'auth_ok':
        _retryCount = 0;
        state = TrackingState(
          order: state.order,
          isConnected: true,
          isLoadingOrder: state.isLoadingOrder,
          error: null,
        );
        break;
      case 'error':
        // Le serveur ferme juste après (codes 4001-4006) — inutile de
        // distinguer le code ici, onDone/onError déclenchera la
        // reconnexion normalement.
        break;
      case 'ping':
        // [Corrections §4 / DoD] Réponse au heartbeat OBLIGATOIRE, sous
        // peine de déconnexion silencieuse après quelques minutes.
        _sendPong();
        break;
      case 'notification':
        _handleNotification(json);
        break;
      default:
        break;
    }
  }

  void _sendAuth() {
    final token = _ref.read(accessTokenProvider);
    _socket?.send(jsonEncode({'type': 'auth', 'token': token}));
  }

  void _sendPong() {
    _socket?.send(jsonEncode({'type': 'pong'}));
  }

  void _handleNotification(Map<String, dynamic> json) {
    final event = json['event'];
    if (event is! String || !event.startsWith('order.')) return;

    final data = json['data'];
    if (data is! Map<String, dynamic>) return;
    final eventOrderId = data['order_id'];
    if (eventOrderId is! int || eventOrderId != _orderId) return;

    // [Corrections §4] `data` ne contient jamais l'état complet — toujours
    // refetch l'état autoritaire plutôt que de le déduire du message WS.
    unawaited(_fetchOrder());
  }

  // ───────────────────────────────────────────────────────────────────────
  // Fetch état commande (event WS + polling de secours)
  // ───────────────────────────────────────────────────────────────────────

  void _startPolling() {
    _pollTimer = Timer.periodic(_pollInterval, (_) {
      if (state.isTerminal) {
        _pollTimer?.cancel();
        return;
      }
      unawaited(_fetchOrder());
    });
  }

  Future<void> refreshNow() => _fetchOrder(surfaceError: true);

  Future<void> _fetchOrder({bool surfaceError = false}) async {
    state = TrackingState(
      order: state.order,
      isConnected: state.isConnected,
      isLoadingOrder: true,
      error: state.error,
    );
    try {
      final order = await _orderRepository.getOrderById(_orderId);
      state = TrackingState(
        order: order,
        isConnected: state.isConnected,
        isLoadingOrder: false,
        error: null,
      );
      if (order.status.isTerminal) {
        _stopReconnecting();
        _pollTimer?.cancel();
      }
    } catch (_) {
      // Échec isolé du fetch — on garde le dernier état connu, le WS/polling
      // suivant réessaiera. Ne pas planter l'écran sur une erreur réseau
      // transitoire.
      state = TrackingState(
        order: state.order,
        isConnected: state.isConnected,
        isLoadingOrder: false,
        error: surfaceError
            ? 'Impossible de rafraichir la commande. Reessayez dans un instant.'
            : state.error,
      );
    }
  }

  // ───────────────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _reconnectTimer?.cancel();
    _pollTimer?.cancel();
    _subscription?.cancel();
    unawaited(_socket?.close());
    super.dispose();
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Providers
// ─────────────────────────────────────────────────────────────────────────

final trackingProvider = StateNotifierProvider.autoDispose
    .family<TrackingNotifier, TrackingState, int>((ref, orderId) {
  return TrackingNotifier(
    ref,
    orderId,
    orderRepository: ref.read(orderRepositoryProvider),
  );
});
