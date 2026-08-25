/// Statuts réels d'une commande côté `api-pizza` (voir
/// `docs/superpowers/specs/plans/base/api-corrections-phase-d.md` §4).
///
/// [🔒 CORRECTIF] Le plan d'origine (Plan 14) utilisait 7 valeurs avec
/// `ready_for_pickup` — le backend expose en réalité **8** valeurs, avec un
/// seul état `ready` qui sert à la fois le retrait ET le passage en
/// livraison. `queued` (mise en file d'attente cuisine) est un état
/// transitoire valide, pas une erreur : l'UI ne doit ni le masquer ni
/// planter dessus.
///
/// Transitions valides côté serveur (rappel, pour référence — ce fichier ne
/// valide pas les transitions, il ne fait qu'afficher l'état reçu) :
/// `pending→{confirmed,cancelled}`, `confirmed→{preparing,cancelled}`,
/// `queued→{confirmed,cancelled}`, `preparing→{ready,cancelled}`,
/// `ready→{out_for_delivery,delivered}`, `out_for_delivery→{delivered,cancelled}`.
/// `delivered` et `cancelled` sont terminaux.
enum OrderStatusCode {
  pending,
  confirmed,
  queued,
  preparing,
  ready,
  outForDelivery,
  delivered,
  cancelled,
}

/// Parse la valeur `status` brute de l'API (`snake_case`) vers
/// [OrderStatusCode]. Lève [ArgumentError] sur une valeur inconnue plutôt que
/// de silencieusement retomber sur un état par défaut — un statut inconnu
/// signale un écart API/client qu'il vaut mieux voir planter en dev que
/// masquer.
OrderStatusCode orderStatusFromApi(String value) {
  return OrderStatusCode.values.firstWhere(
    (status) => status.apiValue == value,
    orElse: () => throw ArgumentError('Statut de commande inconnu: $value'),
  );
}

extension OrderStatusCodeX on OrderStatusCode {
  /// Valeur `snake_case` telle qu'envoyée/reçue par l'API.
  String get apiValue => switch (this) {
        OrderStatusCode.pending => 'pending',
        OrderStatusCode.confirmed => 'confirmed',
        OrderStatusCode.queued => 'queued',
        OrderStatusCode.preparing => 'preparing',
        OrderStatusCode.ready => 'ready',
        OrderStatusCode.outForDelivery => 'out_for_delivery',
        OrderStatusCode.delivered => 'delivered',
        OrderStatusCode.cancelled => 'cancelled',
      };

  /// États terminaux — plus aucune transition possible, la reconnexion
  /// WebSocket et le polling de secours doivent s'arrêter.
  bool get isTerminal =>
      this == OrderStatusCode.delivered || this == OrderStatusCode.cancelled;

  String get label => switch (this) {
        OrderStatusCode.pending => 'Commande reçue',
        OrderStatusCode.confirmed => 'Commande confirmée',
        OrderStatusCode.queued => 'Mise en file d\'attente',
        OrderStatusCode.preparing => 'En préparation',
        OrderStatusCode.ready => 'Prête',
        OrderStatusCode.outForDelivery => 'En chemin',
        OrderStatusCode.delivered => 'Livrée',
        OrderStatusCode.cancelled => 'Annulée',
      };

  String get icon => switch (this) {
        OrderStatusCode.pending => '🕐',
        OrderStatusCode.confirmed => '✅',
        OrderStatusCode.queued => '⏳',
        OrderStatusCode.preparing => '👨‍🍳',
        OrderStatusCode.ready => '📦',
        OrderStatusCode.outForDelivery => '🛵',
        OrderStatusCode.delivered => '🎉',
        OrderStatusCode.cancelled => '❌',
      };
}

/// Ordre canonique d'affichage de la timeline (hors `cancelled`, qui est un
/// état terminal atteignable depuis n'importe quelle étape et affiché à part
/// — voir [TrackingScreen]). Inclut `queued` : un statut reçu qui vaut
/// [OrderStatusCode.queued] a donc toujours une place dans la timeline,
/// jamais une étape inattendue à masquer.
const List<OrderStatusCode> orderStatusTimelineOrder = [
  OrderStatusCode.pending,
  OrderStatusCode.confirmed,
  OrderStatusCode.queued,
  OrderStatusCode.preparing,
  OrderStatusCode.ready,
  OrderStatusCode.outForDelivery,
  OrderStatusCode.delivered,
];
