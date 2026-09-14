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
