import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_fr.dart';
import 'app_localizations_sr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('fr'),
    Locale('sr'),
    Locale.fromSubtags(languageCode: 'sr', scriptCode: 'Latn')
  ];

  /// Nom affiché de l'application (titre système/onglet).
  ///
  /// In fr, this message translates to:
  /// **'O\'Pizza'**
  String get appTitle;

  /// No description provided for @homeDeliverTo.
  ///
  /// In fr, this message translates to:
  /// **'Livrer a'**
  String get homeDeliverTo;

  /// No description provided for @homeDeliveryAddressPlaceholder.
  ///
  /// In fr, this message translates to:
  /// **'Adresse de livraison'**
  String get homeDeliveryAddressPlaceholder;

  /// No description provided for @homeSearchPlaceholder.
  ///
  /// In fr, this message translates to:
  /// **'Que souhaitez-vous commander ?'**
  String get homeSearchPlaceholder;

  /// No description provided for @homeFeaturedSectionTitle.
  ///
  /// In fr, this message translates to:
  /// **'Incontournables'**
  String get homeFeaturedSectionTitle;

  /// No description provided for @loyaltyPointsLabel.
  ///
  /// In fr, this message translates to:
  /// **'{points} points'**
  String loyaltyPointsLabel(int points);

  /// No description provided for @productRowSeeAll.
  ///
  /// In fr, this message translates to:
  /// **'Voir tout'**
  String get productRowSeeAll;

  /// No description provided for @promoViewOffer.
  ///
  /// In fr, this message translates to:
  /// **'Voir l\'offre'**
  String get promoViewOffer;

  /// No description provided for @allergenExcludeLabel.
  ///
  /// In fr, this message translates to:
  /// **'Exclure les allergènes'**
  String get allergenExcludeLabel;

  /// No description provided for @allergenClearLabel.
  ///
  /// In fr, this message translates to:
  /// **'Effacer'**
  String get allergenClearLabel;

  /// No description provided for @allergenGluten.
  ///
  /// In fr, this message translates to:
  /// **'Gluten'**
  String get allergenGluten;

  /// No description provided for @allergenCrustaceans.
  ///
  /// In fr, this message translates to:
  /// **'Crustacés'**
  String get allergenCrustaceans;

  /// No description provided for @allergenEggs.
  ///
  /// In fr, this message translates to:
  /// **'Œufs'**
  String get allergenEggs;

  /// No description provided for @allergenFish.
  ///
  /// In fr, this message translates to:
  /// **'Poisson'**
  String get allergenFish;

  /// No description provided for @allergenPeanuts.
  ///
  /// In fr, this message translates to:
  /// **'Arachides'**
  String get allergenPeanuts;

  /// No description provided for @allergenSoybeans.
  ///
  /// In fr, this message translates to:
  /// **'Soja'**
  String get allergenSoybeans;

  /// No description provided for @allergenMilk.
  ///
  /// In fr, this message translates to:
  /// **'Lait'**
  String get allergenMilk;

  /// No description provided for @allergenNuts.
  ///
  /// In fr, this message translates to:
  /// **'Fruits à coque'**
  String get allergenNuts;

  /// No description provided for @allergenCelery.
  ///
  /// In fr, this message translates to:
  /// **'Céleri'**
  String get allergenCelery;

  /// No description provided for @allergenMustard.
  ///
  /// In fr, this message translates to:
  /// **'Moutarde'**
  String get allergenMustard;

  /// No description provided for @allergenSesame.
  ///
  /// In fr, this message translates to:
  /// **'Sésame'**
  String get allergenSesame;

  /// No description provided for @allergenSulphites.
  ///
  /// In fr, this message translates to:
  /// **'Sulfites'**
  String get allergenSulphites;

  /// No description provided for @allergenLupin.
  ///
  /// In fr, this message translates to:
  /// **'Lupin'**
  String get allergenLupin;

  /// No description provided for @allergenMolluscs.
  ///
  /// In fr, this message translates to:
  /// **'Mollusques'**
  String get allergenMolluscs;

  /// No description provided for @productUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Indisponible'**
  String get productUnavailable;

  /// No description provided for @productAvailableToday.
  ///
  /// In fr, this message translates to:
  /// **'Disponible aujourd\'hui'**
  String get productAvailableToday;

  /// No description provided for @productTemporarilyUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Momentanement indisponible'**
  String get productTemporarilyUnavailable;

  /// No description provided for @productAddedToCart.
  ///
  /// In fr, this message translates to:
  /// **'Ajouté au panier'**
  String get productAddedToCart;

  /// No description provided for @productContainsLabel.
  ///
  /// In fr, this message translates to:
  /// **'Contient'**
  String get productContainsLabel;

  /// No description provided for @productExtrasLabel.
  ///
  /// In fr, this message translates to:
  /// **'Suppléments'**
  String get productExtrasLabel;

  /// No description provided for @productQuantityLabel.
  ///
  /// In fr, this message translates to:
  /// **'Quantité'**
  String get productQuantityLabel;

  /// No description provided for @productAddToCartButton.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter au panier'**
  String get productAddToCartButton;

  /// No description provided for @productUnavailableButton.
  ///
  /// In fr, this message translates to:
  /// **'Produit indisponible'**
  String get productUnavailableButton;

  /// No description provided for @productLoadErrorMessage.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger ce produit.'**
  String get productLoadErrorMessage;

  /// No description provided for @cartTitle.
  ///
  /// In fr, this message translates to:
  /// **'Panier'**
  String get cartTitle;

  /// No description provided for @cartClearButton.
  ///
  /// In fr, this message translates to:
  /// **'Vider'**
  String get cartClearButton;

  /// No description provided for @cartEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mon panier'**
  String get cartEmptyTitle;

  /// No description provided for @cartEmptyStateTitle.
  ///
  /// In fr, this message translates to:
  /// **'Votre panier est vide'**
  String get cartEmptyStateTitle;

  /// No description provided for @cartEmptyStateSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez des produits depuis le menu.'**
  String get cartEmptyStateSubtitle;

  /// No description provided for @cartRemoveTooltip.
  ///
  /// In fr, this message translates to:
  /// **'Retirer'**
  String get cartRemoveTooltip;

  /// No description provided for @cartAddTooltip.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter'**
  String get cartAddTooltip;

  /// No description provided for @cartPromoLoginPrompt.
  ///
  /// In fr, this message translates to:
  /// **'Connectez-vous pour utiliser un code promo.'**
  String get cartPromoLoginPrompt;

  /// No description provided for @cartPromoCodeLabel.
  ///
  /// In fr, this message translates to:
  /// **'Code promo'**
  String get cartPromoCodeLabel;

  /// No description provided for @cartPromoApplyButton.
  ///
  /// In fr, this message translates to:
  /// **'Appliquer'**
  String get cartPromoApplyButton;

  /// No description provided for @cartPromoInvalidError.
  ///
  /// In fr, this message translates to:
  /// **'Ce code promo n\'est pas valide.'**
  String get cartPromoInvalidError;

  /// No description provided for @cartPromoAppliedLabel.
  ///
  /// In fr, this message translates to:
  /// **'Code \"{code}\" appliqué : -{discount}'**
  String cartPromoAppliedLabel(String code, String discount);

  /// No description provided for @cartLoyaltyPreview.
  ///
  /// In fr, this message translates to:
  /// **'Cette commande vous rapportera {points} points fidélité.'**
  String cartLoyaltyPreview(int points);

  /// No description provided for @cartCheckoutButton.
  ///
  /// In fr, this message translates to:
  /// **'Commander - {price}'**
  String cartCheckoutButton(String price);

  /// No description provided for @cartSubtotalLabel.
  ///
  /// In fr, this message translates to:
  /// **'Sous-total'**
  String get cartSubtotalLabel;

  /// No description provided for @cartDiscountLabel.
  ///
  /// In fr, this message translates to:
  /// **'Remise'**
  String get cartDiscountLabel;

  /// No description provided for @cartDeliveryFeeLabel.
  ///
  /// In fr, this message translates to:
  /// **'Frais de livraison'**
  String get cartDeliveryFeeLabel;

  /// No description provided for @cartDeliveryFeeValue.
  ///
  /// In fr, this message translates to:
  /// **'Au checkout'**
  String get cartDeliveryFeeValue;

  /// No description provided for @cartTotalLabel.
  ///
  /// In fr, this message translates to:
  /// **'Total'**
  String get cartTotalLabel;

  /// No description provided for @checkoutStepRevalidationTitle.
  ///
  /// In fr, this message translates to:
  /// **'Vérification du panier'**
  String get checkoutStepRevalidationTitle;

  /// No description provided for @checkoutStepDeliveryModeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Livraison ou retrait ?'**
  String get checkoutStepDeliveryModeTitle;

  /// No description provided for @checkoutStepAddressTitle.
  ///
  /// In fr, this message translates to:
  /// **'Adresse de livraison'**
  String get checkoutStepAddressTitle;

  /// No description provided for @checkoutStepRecapTitle.
  ///
  /// In fr, this message translates to:
  /// **'Récapitulatif'**
  String get checkoutStepRecapTitle;

  /// No description provided for @checkoutGenericTitle.
  ///
  /// In fr, this message translates to:
  /// **'Commander'**
  String get checkoutGenericTitle;

  /// No description provided for @checkoutBackToCart.
  ///
  /// In fr, this message translates to:
  /// **'Retour au panier'**
  String get checkoutBackToCart;

  /// No description provided for @checkoutRevalidationMessage.
  ///
  /// In fr, this message translates to:
  /// **'Certains articles de votre panier ont changé depuis que vous les avez ajoutés.'**
  String get checkoutRevalidationMessage;

  /// No description provided for @checkoutContinueButton.
  ///
  /// In fr, this message translates to:
  /// **'Continuer'**
  String get checkoutContinueButton;

  /// No description provided for @checkoutPriceUpdated.
  ///
  /// In fr, this message translates to:
  /// **'Prix mis à jour : {oldPrice} → {newPrice}'**
  String checkoutPriceUpdated(String oldPrice, String newPrice);

  /// No description provided for @checkoutItemNoLongerAvailable.
  ///
  /// In fr, this message translates to:
  /// **'Cet article n\'est plus disponible.'**
  String get checkoutItemNoLongerAvailable;

  /// No description provided for @checkoutDeliveryModeQuestion.
  ///
  /// In fr, this message translates to:
  /// **'Comment souhaitez-vous récupérer votre commande ?'**
  String get checkoutDeliveryModeQuestion;

  /// No description provided for @checkoutDeliveryTitle.
  ///
  /// In fr, this message translates to:
  /// **'Livraison'**
  String get checkoutDeliveryTitle;

  /// No description provided for @checkoutDeliverySubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Livré à votre adresse'**
  String get checkoutDeliverySubtitle;

  /// No description provided for @checkoutPickupTitle.
  ///
  /// In fr, this message translates to:
  /// **'Retrait en boutique'**
  String get checkoutPickupTitle;

  /// No description provided for @checkoutPickupSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'À récupérer sur place'**
  String get checkoutPickupSubtitle;

  /// No description provided for @checkoutAddressMissingError.
  ///
  /// In fr, this message translates to:
  /// **'Saisissez une adresse de livraison pour continuer.'**
  String get checkoutAddressMissingError;

  /// No description provided for @checkoutPinMissingError.
  ///
  /// In fr, this message translates to:
  /// **'Placez un point sur la carte pour continuer.'**
  String get checkoutPinMissingError;

  /// No description provided for @checkoutAddressInstructions.
  ///
  /// In fr, this message translates to:
  /// **'Saisissez votre adresse, puis touchez la carte pour placer le repère de livraison.'**
  String get checkoutAddressInstructions;

  /// No description provided for @checkoutAddressHelper.
  ///
  /// In fr, this message translates to:
  /// **'Le repère sert à vérifier la zone, l\'adresse est transmise à la commande.'**
  String get checkoutAddressHelper;

  /// No description provided for @checkoutPinCoordinates.
  ///
  /// In fr, this message translates to:
  /// **'Repère : {lat}, {lng}'**
  String checkoutPinCoordinates(String lat, String lng);

  /// No description provided for @checkoutSwitchToPickup.
  ///
  /// In fr, this message translates to:
  /// **'Passer en retrait en boutique'**
  String get checkoutSwitchToPickup;

  /// No description provided for @checkoutCheckZoneButton.
  ///
  /// In fr, this message translates to:
  /// **'Vérifier la zone'**
  String get checkoutCheckZoneButton;

  /// No description provided for @checkoutRecapArticlesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Articles'**
  String get checkoutRecapArticlesTitle;

  /// No description provided for @checkoutRecapLineItem.
  ///
  /// In fr, this message translates to:
  /// **'{quantity} × {name}'**
  String checkoutRecapLineItem(int quantity, String name);

  /// No description provided for @checkoutRecapZone.
  ///
  /// In fr, this message translates to:
  /// **'Zone : {zone}'**
  String checkoutRecapZone(String zone);

  /// No description provided for @checkoutRecapEstimatedTime.
  ///
  /// In fr, this message translates to:
  /// **'Délai estimé : {minutes} min'**
  String checkoutRecapEstimatedTime(int minutes);

  /// No description provided for @checkoutRecapDeliveryFee.
  ///
  /// In fr, this message translates to:
  /// **'Frais de livraison : {price}'**
  String checkoutRecapDeliveryFee(String price);

  /// No description provided for @checkoutRecapAddress.
  ///
  /// In fr, this message translates to:
  /// **'Adresse : {address}'**
  String checkoutRecapAddress(String address);

  /// No description provided for @checkoutRecapPickupOnly.
  ///
  /// In fr, this message translates to:
  /// **'À récupérer directement en boutique.'**
  String get checkoutRecapPickupOnly;

  /// No description provided for @checkoutRecapEstimatedTotal.
  ///
  /// In fr, this message translates to:
  /// **'Total estimé'**
  String get checkoutRecapEstimatedTotal;

  /// No description provided for @checkoutRecapFinalAmountNotice.
  ///
  /// In fr, this message translates to:
  /// **'Le montant définitif est calculé par le serveur à la création de la commande.'**
  String get checkoutRecapFinalAmountNotice;

  /// No description provided for @checkoutConfirmOrderButton.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer la commande'**
  String get checkoutConfirmOrderButton;

  /// No description provided for @paymentTitle.
  ///
  /// In fr, this message translates to:
  /// **'Paiement'**
  String get paymentTitle;

  /// No description provided for @paymentSecureTitle.
  ///
  /// In fr, this message translates to:
  /// **'Paiement sécurisé'**
  String get paymentSecureTitle;

  /// No description provided for @paymentSecureSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Votre paiement est chiffré et sécurisé par Stripe.'**
  String get paymentSecureSubtitle;

  /// No description provided for @paymentRetryButton.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get paymentRetryButton;

  /// No description provided for @paymentPayNowButton.
  ///
  /// In fr, this message translates to:
  /// **'Payer maintenant'**
  String get paymentPayNowButton;

  /// No description provided for @paymentCancelButton.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get paymentCancelButton;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['fr', 'sr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+script codes are specified.
  switch (locale.languageCode) {
    case 'sr':
      {
        switch (locale.scriptCode) {
          case 'Latn':
            return AppLocalizationsSrLatn();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'fr':
      return AppLocalizationsFr();
    case 'sr':
      return AppLocalizationsSr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
