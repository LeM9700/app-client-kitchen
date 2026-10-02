/// Libelle lisible du `payment_status` d'une commande.
///
/// `guaranteed` / `guarantee_*` decrivent l'empreinte bancaire d'une livraison
/// payee a la remise (voir `docs/modules/payments.md` cote API). Une valeur
/// inconnue est affichee telle quelle plutot que masquee.
String paymentStatusLabel(String status) => switch (status) {
      'pending' => 'En attente',
      'paid' => 'Payé',
      'failed' => 'Échec du paiement',
      'guaranteed' => 'Empreinte bancaire : à régler à la livraison',
      'guarantee_released' => 'Empreinte libérée, rien n\'a été débité',
      'guarantee_captured' => 'Empreinte débitée en partie',
      _ => status,
    };
