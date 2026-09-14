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
}
