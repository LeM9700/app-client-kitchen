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
/// `ready→{out_for_delivery,delivered}`,
/// `out_for_delivery→{delivered,cancelled,delivery_failed}`,
/// `pending→rejected`.
/// `delivered`, `cancelled`, `delivery_failed` et `rejected` sont terminaux.
///
/// [Phase 0 livraison] `deliveryFailed` et `rejected` existent côté API depuis
/// longtemps mais manquaient ici : une commande en échec de livraison faisait
/// planter l'écran de suivi. [unknown] absorbe tout statut futur ou inconnu au
/// lieu de lever une erreur : l'écran reste utilisable, l'état exact est
/// simplement présenté comme « en cours de mise à jour ».
enum OrderStatusCode {
  pending,
  confirmed,
  queued,
  preparing,
  ready,
  outForDelivery,
  delivered,
  cancelled,
  deliveryFailed,
  rejected,
  unknown,
}

/// Parse la valeur `status` brute de l'API (`snake_case`) vers
/// [OrderStatusCode].
///
/// Une valeur inconnue (nouveau statut serveur, entrée d'historique interne
/// comme `item_ready`) donne [OrderStatusCode.unknown] — jamais d'exception :
/// une seule valeur imprévue ne doit pas casser la liste des commandes ni
/// l'écran de suivi. L'écart reste visible en développement via `assert`.
OrderStatusCode orderStatusFromApi(String value) {
  for (final status in OrderStatusCode.values) {
    if (status != OrderStatusCode.unknown && status.apiValue == value) {
      return status;
    }
  }
  assert(() {
    // ignore: avoid_print
    print("[order_status] statut inconnu recu de l'API: $value");
    return true;
  }());
  return OrderStatusCode.unknown;
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
        OrderStatusCode.deliveryFailed => 'delivery_failed',
        OrderStatusCode.rejected => 'rejected',
        OrderStatusCode.unknown => 'unknown',
      };

  /// États terminaux — plus aucune transition possible, la reconnexion
  /// WebSocket et le polling de secours doivent s'arrêter.
  bool get isTerminal =>
      this == OrderStatusCode.delivered ||
      this == OrderStatusCode.cancelled ||
      this == OrderStatusCode.deliveryFailed ||
      this == OrderStatusCode.rejected;

  /// Terminaux « négatifs » : la commande n'ira pas au bout. Affichés seuls
  /// dans la chronologie, hors de l'ordre canonique.
  bool get isFailure =>
      this == OrderStatusCode.cancelled ||
      this == OrderStatusCode.deliveryFailed ||
      this == OrderStatusCode.rejected;

  String get label => switch (this) {
        OrderStatusCode.pending => 'Commande reçue',
        OrderStatusCode.confirmed => 'Commande confirmée',
        OrderStatusCode.queued => 'Mise en file d\'attente',
        OrderStatusCode.preparing => 'En préparation',
        OrderStatusCode.ready => 'Prête',
        OrderStatusCode.outForDelivery => 'En chemin',
        OrderStatusCode.delivered => 'Livrée',
        OrderStatusCode.cancelled => 'Annulée',
        OrderStatusCode.deliveryFailed => 'Livraison échouée',
        OrderStatusCode.rejected => 'Refusée',
        OrderStatusCode.unknown => 'Mise à jour en cours',
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
        OrderStatusCode.deliveryFailed => '⚠️',
        OrderStatusCode.rejected => '🚫',
        OrderStatusCode.unknown => '⏳',
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
