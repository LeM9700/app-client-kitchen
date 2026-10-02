// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'O\'Pizza';

  @override
  String get homeDeliverTo => 'Livrer a';

  @override
  String get homeDeliveryAddressPlaceholder => 'Adresse de livraison';

  @override
  String get homeSearchPlaceholder => 'Que souhaitez-vous commander ?';

  @override
  String get homeFeaturedSectionTitle => 'Incontournables';

  @override
  String get homeAllMenuSectionTitle => 'Tout le menu';

  @override
  String loyaltyPointsLabel(int points) {
    return '$points points';
  }

  @override
  String get productRowSeeAll => 'Voir tout';

  @override
  String get promoViewOffer => 'Voir l\'offre';

  @override
  String get allergenExcludeLabel => 'Exclure les allergènes';

  @override
  String get allergenClearLabel => 'Effacer';

  @override
  String get allergenGluten => 'Gluten';

  @override
  String get allergenCrustaceans => 'Crustacés';

  @override
  String get allergenEggs => 'Œufs';

  @override
  String get allergenFish => 'Poisson';

  @override
  String get allergenPeanuts => 'Arachides';

  @override
  String get allergenSoybeans => 'Soja';

  @override
  String get allergenMilk => 'Lait';

  @override
  String get allergenNuts => 'Fruits à coque';

  @override
  String get allergenCelery => 'Céleri';

  @override
  String get allergenMustard => 'Moutarde';

  @override
  String get allergenSesame => 'Sésame';

  @override
  String get allergenSulphites => 'Sulfites';

  @override
  String get allergenLupin => 'Lupin';

  @override
  String get allergenMolluscs => 'Mollusques';

  @override
  String get productUnavailable => 'Indisponible';

  @override
  String get productAvailableToday => 'Disponible aujourd\'hui';

  @override
  String get productTemporarilyUnavailable => 'Momentanement indisponible';

  @override
  String get productAddedToCart => 'Ajouté au panier';

  @override
  String get productContainsLabel => 'Contient';

  @override
  String get productExtrasLabel => 'Suppléments';

  @override
  String get productQuantityLabel => 'Quantité';

  @override
  String get productAddToCartButton => 'Ajouter au panier';

  @override
  String get productUnavailableButton => 'Produit indisponible';

  @override
  String get productLoadErrorMessage => 'Impossible de charger ce produit.';

  @override
  String get productSizeLabel => 'Taille';

  @override
  String get cartTitle => 'Panier';

  @override
  String get cartClearButton => 'Vider';

  @override
  String get cartEmptyTitle => 'Mon panier';

  @override
  String get cartEmptyStateTitle => 'Votre panier est vide';

  @override
  String get cartEmptyStateSubtitle => 'Ajoutez des produits depuis le menu.';

  @override
  String get cartRemoveTooltip => 'Retirer';

  @override
  String get cartAddTooltip => 'Ajouter';

  @override
  String get cartPromoLoginPrompt =>
      'Connectez-vous pour utiliser un code promo.';

  @override
  String get cartPromoCodeLabel => 'Code promo';

  @override
  String get cartPromoApplyButton => 'Appliquer';

  @override
  String get cartPromoInvalidError => 'Ce code promo n\'est pas valide.';

  @override
  String cartPromoAppliedLabel(String code, String discount) {
    return 'Code \"$code\" appliqué : -$discount';
  }

  @override
  String cartLoyaltyPreview(int points) {
    return 'Cette commande vous rapportera $points points fidélité.';
  }

  @override
  String cartCheckoutButton(String price) {
    return 'Commander - $price';
  }

  @override
  String get cartSubtotalLabel => 'Sous-total';

  @override
  String get cartDiscountLabel => 'Remise';

  @override
  String get cartDeliveryFeeLabel => 'Frais de livraison';

  @override
  String get cartDeliveryFeeValue => 'Au checkout';

  @override
  String get cartTotalLabel => 'Total';

  @override
  String get checkoutStepRevalidationTitle => 'Vérification du panier';

  @override
  String get checkoutStepDeliveryModeTitle => 'Livraison ou retrait ?';

  @override
  String get checkoutStepAddressTitle => 'Adresse de livraison';

  @override
  String get checkoutStepRecapTitle => 'Récapitulatif';

  @override
  String get checkoutGenericTitle => 'Commander';

  @override
  String get checkoutBackToCart => 'Retour au panier';

  @override
  String get checkoutRevalidationMessage =>
      'Certains articles de votre panier ont changé depuis que vous les avez ajoutés.';

  @override
  String get checkoutContinueButton => 'Continuer';

  @override
  String checkoutPriceUpdated(String oldPrice, String newPrice) {
    return 'Prix mis à jour : $oldPrice → $newPrice';
  }

  @override
  String get checkoutItemNoLongerAvailable =>
      'Cet article n\'est plus disponible.';

  @override
  String get checkoutDeliveryModeQuestion =>
      'Comment souhaitez-vous récupérer votre commande ?';

  @override
  String get checkoutDeliveryTitle => 'Livraison';

  @override
  String get checkoutDeliverySubtitle => 'Livré à votre adresse';

  @override
  String get checkoutPickupTitle => 'Retrait en boutique';

  @override
  String get checkoutPickupSubtitle => 'À récupérer sur place';

  @override
  String get checkoutAddressMissingError =>
      'Saisissez une adresse de livraison pour continuer.';

  @override
  String get checkoutPinMissingError =>
      'Placez un point sur la carte pour continuer.';

  @override
  String get checkoutAddressInstructions =>
      'Saisissez votre adresse, puis touchez la carte pour placer le repère de livraison.';

  @override
  String get checkoutAddressHelper =>
      'Le repère sert à vérifier la zone, l\'adresse est transmise à la commande.';

  @override
  String checkoutPinCoordinates(String lat, String lng) {
    return 'Repère : $lat, $lng';
  }

  @override
  String get checkoutSwitchToPickup => 'Passer en retrait en boutique';

  @override
  String get checkoutCheckZoneButton => 'Vérifier la zone';

  @override
  String get checkoutAddressSearchUnavailable =>
      'La recherche d\'adresse est indisponible. Placez le repère sur la carte.';

  @override
  String get checkoutUseMyPosition => 'Ma position';

  @override
  String get checkoutLocationDenied =>
      'Autorisez la localisation pour utiliser votre position.';

  @override
  String get checkoutLocationUnavailable =>
      'Impossible d\'obtenir votre position. Vérifiez que la localisation est activée.';

  @override
  String checkoutDeliveryFeeLine(String fee) {
    return 'Frais de livraison : $fee';
  }

  @override
  String get checkoutDeliveryFree => 'Livraison offerte';

  @override
  String checkoutDeliveryFreeNudge(String amount) {
    return 'Plus que $amount pour la livraison offerte';
  }

  @override
  String checkoutMinOrderError(String amount) {
    return 'Minimum de commande pour cette zone : $amount. Ajoutez des articles ou choisissez le retrait.';
  }

  @override
  String get checkoutMinOrderErrorGeneric =>
      'Le minimum de commande de cette zone n\'est pas atteint. Ajoutez des articles ou choisissez le retrait.';

  @override
  String get checkoutDeliveryDisabled =>
      'La livraison est momentanément indisponible. Choisissez le retrait en boutique.';

  @override
  String get checkoutDeliveryUnavailableMode => 'Indisponible actuellement';

  @override
  String get checkoutPhoneRequiredServer =>
      'Un numéro de téléphone est requis pour une livraison.';

  @override
  String get checkoutRateLimited => 'Trop de recherches. Patientez un instant.';

  @override
  String cartPromoFreeDeliveryApplied(String code) {
    return 'Code $code appliqué : livraison offerte';
  }

  @override
  String get checkoutPhoneLabel => 'Téléphone (pour le livreur)';

  @override
  String get checkoutPhoneHint => '06 12 34 56 78';

  @override
  String get checkoutPhoneMissingError =>
      'Saisissez un numéro de téléphone pour que le livreur puisse vous joindre.';

  @override
  String get checkoutPhoneInvalidError =>
      'Ce numéro de téléphone semble invalide.';

  @override
  String get checkoutInstructionsLabel =>
      'Instructions de livraison (optionnel)';

  @override
  String get checkoutInstructionsHint => 'Étage, digicode, interphone…';

  @override
  String get checkoutRecapArticlesTitle => 'Articles';

  @override
  String checkoutRecapLineItem(int quantity, String name) {
    return '$quantity × $name';
  }

  @override
  String checkoutRecapZone(String zone) {
    return 'Zone : $zone';
  }

  @override
  String checkoutRecapEstimatedTime(int minutes) {
    return 'Délai estimé : $minutes min';
  }

  @override
  String checkoutRecapDeliveryFee(String price) {
    return 'Frais de livraison : $price';
  }

  @override
  String checkoutRecapAddress(String address) {
    return 'Adresse : $address';
  }

  @override
  String get checkoutRecapPickupOnly => 'À récupérer directement en boutique.';

  @override
  String get checkoutRecapEstimatedTotal => 'Total estimé';

  @override
  String get checkoutRecapFinalAmountNotice =>
      'Le montant définitif est calculé par le serveur à la création de la commande.';

  @override
  String get checkoutConfirmOrderButton => 'Confirmer la commande';

  @override
  String get paymentTitle => 'Paiement';

  @override
  String get paymentSecureTitle => 'Paiement sécurisé';

  @override
  String get paymentSecureSubtitle =>
      'Votre paiement est chiffré et sécurisé par Stripe.';

  @override
  String get paymentRetryButton => 'Réessayer';

  @override
  String get paymentPayNowButton => 'Payer maintenant';

  @override
  String get paymentCancelButton => 'Annuler';

  @override
  String get paymentModeOnlineTitle => 'Payer maintenant';

  @override
  String get paymentModeOnlineSubtitle =>
      'Carte bancaire, débitée tout de suite';

  @override
  String get paymentModeOnDeliveryTitle => 'Payer à la livraison';

  @override
  String get paymentModeOnDeliverySubtitle =>
      'Espèces ou carte, avec une empreinte bancaire';

  @override
  String get paymentGuaranteeHeading => 'Montant bloqué sur la carte';

  @override
  String paymentGuaranteeExplainer(String amount) {
    return 'Nous bloquons $amount sur votre carte pour garantir la commande. Aucun débit n\'est effectué : vous payez le livreur (espèces ou carte) et le blocage est levé.';
  }

  @override
  String get paymentGuaranteeChargeRule =>
      'Nous ne pouvons débiter votre carte que si la livraison échoue de votre fait : absence, adresse erronée, injoignable ou commande refusée.';

  @override
  String paymentGuaranteeValidity(int days) {
    return 'Sans débit, le blocage disparaît de lui-même sous $days jours.';
  }

  @override
  String get paymentGuaranteeAccept =>
      'J\'ai compris et j\'accepte ces conditions';

  @override
  String paymentGuaranteeCta(String amount) {
    return 'Laisser mon empreinte ($amount)';
  }

  @override
  String get paymentGuaranteeTermsError =>
      'Impossible de charger les conditions. Vérifiez votre connexion.';

  @override
  String get trackingDeliveryCodeTitle => 'Votre code de remise';

  @override
  String get trackingDeliveryCodeHint =>
      'Donnez ce code au livreur quand il vous remet la commande. Ne le partagez avec personne d\'autre.';

  @override
  String trackingOrderTitle(int orderId) {
    return 'Commande #$orderId';
  }

  @override
  String get trackingRefreshTooltip => 'Rafraichir le statut';

  @override
  String get trackingLoadErrorMessage => 'Impossible de charger la commande.';

  @override
  String get trackingViewOrdersButton => 'Voir mes commandes';

  @override
  String get trackingPaymentConfirmed => 'Paiement confirmé';

  @override
  String trackingRealtimeSubtitle(int orderId) {
    return 'Suivi de la commande #$orderId en temps réel.';
  }

  @override
  String get trackingConnectingMessage => 'Connexion en cours...';

  @override
  String get trackingCancelledMessage => 'Cette commande a été annulée.';

  @override
  String get authEmailLabel => 'Email';

  @override
  String get authEmailInvalidError => 'Email invalide';

  @override
  String get authPasswordLabel => 'Mot de passe';

  @override
  String get authPasswordMinLength => '8 caractères minimum';

  @override
  String get authForgotPasswordLink => 'Mot de passe oublié ?';

  @override
  String get authLoginSubmitButton => 'Se connecter';

  @override
  String get authOrDivider => 'ou';

  @override
  String get authCreateAccountButton => 'Créer un compte';

  @override
  String get authRegisterHeading => 'Allons-y\nCréez\nvotre\ncompte';

  @override
  String get authLegalAcceptRequired =>
      'Merci d\'accepter les conditions avant de continuer.';

  @override
  String get authCloseTooltip => 'Fermer';

  @override
  String get authFullNameLabel => 'Nom complet';

  @override
  String get authFullNameRequiredError => 'Nom requis';

  @override
  String get authRegisterSubmitButton => 'S\'inscrire';

  @override
  String get authHaveAccountPrompt => 'Vous avez un compte ?';

  @override
  String get authForgotTitle => 'Mot de\nPASSE ?';

  @override
  String get authEmailSentTitle => 'Email\nenvoyé';

  @override
  String authEmailSentBody(String email) {
    return 'Si un compte est associé à $email, les instructions arrivent dans quelques minutes.';
  }

  @override
  String get authForgotBody =>
      'Pas de souci, nous vous enverrons les instructions pour réinitialiser votre accès.';

  @override
  String get authEnterEmailHint => 'Entrer votre email';

  @override
  String get authResetPasswordButton => 'Réinitialiser le mot de passe';

  @override
  String get authBackToLoginLink => 'Retour à la connexion';

  @override
  String authCheckoutCartSummary(int count, String price) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count articles',
      one: '$count article',
    );
    return '$_temp0 · $price';
  }

  @override
  String get authCheckoutLoginPrompt =>
      'Connectez-vous pour finaliser votre commande.';

  @override
  String get authTabLogin => 'Je me connecte';

  @override
  String get authTabRegister => 'Je crée un compte';

  @override
  String get authPhoneLabel => 'Téléphone (optionnel)';

  @override
  String get authCheckoutRegisterButton => 'Créer mon compte';

  @override
  String get authLoginFailedError => 'Connexion impossible.';

  @override
  String get authRegisterFailedError => 'Inscription impossible.';
}
