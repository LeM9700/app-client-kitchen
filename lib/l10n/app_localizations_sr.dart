// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Serbian (`sr`).
class AppLocalizationsSr extends AppLocalizations {
  AppLocalizationsSr([String locale = 'sr']) : super(locale);

  @override
  String get appTitle => 'Kod Mome';

  @override
  String get homeDeliverTo => 'Dostava na';

  @override
  String get homeDeliveryAddressPlaceholder => 'Adresa za dostavu';

  @override
  String get homeSearchPlaceholder => 'Šta želite da naručite?';

  @override
  String get homeFeaturedSectionTitle => 'Najpopularnije';

  @override
  String loyaltyPointsLabel(int points) {
    return '$points poena';
  }

  @override
  String get productRowSeeAll => 'Pogledaj sve';

  @override
  String get promoViewOffer => 'Pogledaj ponudu';

  @override
  String get allergenExcludeLabel => 'Isključi alergene';

  @override
  String get allergenClearLabel => 'Obriši';

  @override
  String get allergenGluten => 'Gluten';

  @override
  String get allergenCrustaceans => 'Rakovi';

  @override
  String get allergenEggs => 'Jaja';

  @override
  String get allergenFish => 'Riba';

  @override
  String get allergenPeanuts => 'Kikiriki';

  @override
  String get allergenSoybeans => 'Soja';

  @override
  String get allergenMilk => 'Mleko';

  @override
  String get allergenNuts => 'Orašasti plodovi';

  @override
  String get allergenCelery => 'Celer';

  @override
  String get allergenMustard => 'Slačica';

  @override
  String get allergenSesame => 'Susam';

  @override
  String get allergenSulphites => 'Sulfiti';

  @override
  String get allergenLupin => 'Lupin';

  @override
  String get allergenMolluscs => 'Mekušci';

  @override
  String get productUnavailable => 'Nedostupno';

  @override
  String get productAvailableToday => 'Dostupno danas';

  @override
  String get productTemporarilyUnavailable => 'Trenutno nedostupno';

  @override
  String get productAddedToCart => 'Dodato u korpu';

  @override
  String get productContainsLabel => 'Sadrži';

  @override
  String get productExtrasLabel => 'Dodaci';

  @override
  String get productQuantityLabel => 'Količina';

  @override
  String get productAddToCartButton => 'Dodaj u korpu';

  @override
  String get productUnavailableButton => 'Proizvod nedostupan';

  @override
  String get productLoadErrorMessage => 'Nije moguće učitati ovaj proizvod.';

  @override
  String get cartTitle => 'Korpa';

  @override
  String get cartClearButton => 'Isprazni';

  @override
  String get cartEmptyTitle => 'Moja korpa';

  @override
  String get cartEmptyStateTitle => 'Vaša korpa je prazna';

  @override
  String get cartEmptyStateSubtitle => 'Dodajte proizvode sa menija.';

  @override
  String get cartRemoveTooltip => 'Ukloni';

  @override
  String get cartAddTooltip => 'Dodaj';

  @override
  String get cartPromoLoginPrompt =>
      'Prijavite se da biste koristili promo kod.';

  @override
  String get cartPromoCodeLabel => 'Promo kod';

  @override
  String get cartPromoApplyButton => 'Primeni';

  @override
  String get cartPromoInvalidError => 'Ovaj promo kod nije validan.';

  @override
  String cartPromoAppliedLabel(String code, String discount) {
    return 'Kod \"$code\" primenjen: -$discount';
  }

  @override
  String cartLoyaltyPreview(int points) {
    return 'Ova narudžbina će vam doneti $points poena vernosti.';
  }

  @override
  String cartCheckoutButton(String price) {
    return 'Poruči - $price';
  }

  @override
  String get cartSubtotalLabel => 'Međuzbir';

  @override
  String get cartDiscountLabel => 'Popust';

  @override
  String get cartDeliveryFeeLabel => 'Troškovi dostave';

  @override
  String get cartDeliveryFeeValue => 'Na plaćanju';

  @override
  String get cartTotalLabel => 'Ukupno';

  @override
  String get checkoutStepRevalidationTitle => 'Provera korpe';

  @override
  String get checkoutStepDeliveryModeTitle => 'Dostava ili preuzimanje?';

  @override
  String get checkoutStepAddressTitle => 'Adresa za dostavu';

  @override
  String get checkoutStepRecapTitle => 'Pregled porudžbine';

  @override
  String get checkoutGenericTitle => 'Poruči';

  @override
  String get checkoutBackToCart => 'Nazad na korpu';

  @override
  String get checkoutRevalidationMessage =>
      'Neki proizvodi iz vaše korpe su se promenili od kada ste ih dodali.';

  @override
  String get checkoutContinueButton => 'Nastavi';

  @override
  String checkoutPriceUpdated(String oldPrice, String newPrice) {
    return 'Cena ažurirana: $oldPrice → $newPrice';
  }

  @override
  String get checkoutItemNoLongerAvailable =>
      'Ovaj proizvod više nije dostupan.';

  @override
  String get checkoutDeliveryModeQuestion =>
      'Kako želite da preuzmete porudžbinu?';

  @override
  String get checkoutDeliveryTitle => 'Dostava';

  @override
  String get checkoutDeliverySubtitle => 'Dostavljeno na vašu adresu';

  @override
  String get checkoutPickupTitle => 'Preuzimanje u restoranu';

  @override
  String get checkoutPickupSubtitle => 'Preuzmite lično';
}

/// The translations for Serbian, using the Latin script (`sr_Latn`).
class AppLocalizationsSrLatn extends AppLocalizationsSr {
  AppLocalizationsSrLatn() : super('sr_Latn');

  @override
  String get appTitle => 'Kod Mome';

  @override
  String get homeDeliverTo => 'Dostava na';

  @override
  String get homeDeliveryAddressPlaceholder => 'Adresa za dostavu';

  @override
  String get homeSearchPlaceholder => 'Šta želite da naručite?';

  @override
  String get homeFeaturedSectionTitle => 'Najpopularnije';

  @override
  String loyaltyPointsLabel(int points) {
    return '$points poena';
  }

  @override
  String get productRowSeeAll => 'Pogledaj sve';

  @override
  String get promoViewOffer => 'Pogledaj ponudu';

  @override
  String get allergenExcludeLabel => 'Isključi alergene';

  @override
  String get allergenClearLabel => 'Obriši';

  @override
  String get allergenGluten => 'Gluten';

  @override
  String get allergenCrustaceans => 'Rakovi';

  @override
  String get allergenEggs => 'Jaja';

  @override
  String get allergenFish => 'Riba';

  @override
  String get allergenPeanuts => 'Kikiriki';

  @override
  String get allergenSoybeans => 'Soja';

  @override
  String get allergenMilk => 'Mleko';

  @override
  String get allergenNuts => 'Orašasti plodovi';

  @override
  String get allergenCelery => 'Celer';

  @override
  String get allergenMustard => 'Slačica';

  @override
  String get allergenSesame => 'Susam';

  @override
  String get allergenSulphites => 'Sulfiti';

  @override
  String get allergenLupin => 'Lupin';

  @override
  String get allergenMolluscs => 'Mekušci';

  @override
  String get productUnavailable => 'Nedostupno';

  @override
  String get productAvailableToday => 'Dostupno danas';

  @override
  String get productTemporarilyUnavailable => 'Trenutno nedostupno';

  @override
  String get productAddedToCart => 'Dodato u korpu';

  @override
  String get productContainsLabel => 'Sadrži';

  @override
  String get productExtrasLabel => 'Dodaci';

  @override
  String get productQuantityLabel => 'Količina';

  @override
  String get productAddToCartButton => 'Dodaj u korpu';

  @override
  String get productUnavailableButton => 'Proizvod nedostupan';

  @override
  String get productLoadErrorMessage => 'Nije moguće učitati ovaj proizvod.';

  @override
  String get cartTitle => 'Korpa';

  @override
  String get cartClearButton => 'Isprazni';

  @override
  String get cartEmptyTitle => 'Moja korpa';

  @override
  String get cartEmptyStateTitle => 'Vaša korpa je prazna';

  @override
  String get cartEmptyStateSubtitle => 'Dodajte proizvode sa menija.';

  @override
  String get cartRemoveTooltip => 'Ukloni';

  @override
  String get cartAddTooltip => 'Dodaj';

  @override
  String get cartPromoLoginPrompt =>
      'Prijavite se da biste koristili promo kod.';

  @override
  String get cartPromoCodeLabel => 'Promo kod';

  @override
  String get cartPromoApplyButton => 'Primeni';

  @override
  String get cartPromoInvalidError => 'Ovaj promo kod nije validan.';

  @override
  String cartPromoAppliedLabel(String code, String discount) {
    return 'Kod \"$code\" primenjen: -$discount';
  }

  @override
  String cartLoyaltyPreview(int points) {
    return 'Ova narudžbina će vam doneti $points poena vernosti.';
  }

  @override
  String cartCheckoutButton(String price) {
    return 'Poruči - $price';
  }

  @override
  String get cartSubtotalLabel => 'Međuzbir';

  @override
  String get cartDiscountLabel => 'Popust';

  @override
  String get cartDeliveryFeeLabel => 'Troškovi dostave';

  @override
  String get cartDeliveryFeeValue => 'Na plaćanju';

  @override
  String get cartTotalLabel => 'Ukupno';

  @override
  String get checkoutStepRevalidationTitle => 'Provera korpe';

  @override
  String get checkoutStepDeliveryModeTitle => 'Dostava ili preuzimanje?';

  @override
  String get checkoutStepAddressTitle => 'Adresa za dostavu';

  @override
  String get checkoutStepRecapTitle => 'Pregled porudžbine';

  @override
  String get checkoutGenericTitle => 'Poruči';

  @override
  String get checkoutBackToCart => 'Nazad na korpu';

  @override
  String get checkoutRevalidationMessage =>
      'Neki proizvodi iz vaše korpe su se promenili od kada ste ih dodali.';

  @override
  String get checkoutContinueButton => 'Nastavi';

  @override
  String checkoutPriceUpdated(String oldPrice, String newPrice) {
    return 'Cena ažurirana: $oldPrice → $newPrice';
  }

  @override
  String get checkoutItemNoLongerAvailable =>
      'Ovaj proizvod više nije dostupan.';

  @override
  String get checkoutDeliveryModeQuestion =>
      'Kako želite da preuzmete porudžbinu?';

  @override
  String get checkoutDeliveryTitle => 'Dostava';

  @override
  String get checkoutDeliverySubtitle => 'Dostavljeno na vašu adresu';

  @override
  String get checkoutPickupTitle => 'Preuzimanje u restoranu';

  @override
  String get checkoutPickupSubtitle => 'Preuzmite lično';
}
