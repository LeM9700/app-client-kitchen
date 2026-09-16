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
  String get homeAllMenuSectionTitle => 'Ceo meni';

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
  String get productSizeLabel => 'Veličina';

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

  @override
  String get checkoutAddressMissingError =>
      'Unesite adresu za dostavu da biste nastavili.';

  @override
  String get checkoutPinMissingError =>
      'Postavite tačku na mapi da biste nastavili.';

  @override
  String get checkoutAddressInstructions =>
      'Unesite svoju adresu, zatim dodirnite mapu da postavite oznaku za dostavu.';

  @override
  String get checkoutAddressHelper =>
      'Oznaka služi za proveru zone, adresa se prosleđuje uz porudžbinu.';

  @override
  String checkoutPinCoordinates(String lat, String lng) {
    return 'Oznaka: $lat, $lng';
  }

  @override
  String get checkoutSwitchToPickup => 'Pređi na preuzimanje u restoranu';

  @override
  String get checkoutCheckZoneButton => 'Proveri zonu';

  @override
  String get checkoutRecapArticlesTitle => 'Stavke';

  @override
  String checkoutRecapLineItem(int quantity, String name) {
    return '$quantity × $name';
  }

  @override
  String checkoutRecapZone(String zone) {
    return 'Zona: $zone';
  }

  @override
  String checkoutRecapEstimatedTime(int minutes) {
    return 'Procenjeno vreme: $minutes min';
  }

  @override
  String checkoutRecapDeliveryFee(String price) {
    return 'Troškovi dostave: $price';
  }

  @override
  String checkoutRecapAddress(String address) {
    return 'Adresa: $address';
  }

  @override
  String get checkoutRecapPickupOnly => 'Preuzimanje direktno u restoranu.';

  @override
  String get checkoutRecapEstimatedTotal => 'Procenjeni ukupan iznos';

  @override
  String get checkoutRecapFinalAmountNotice =>
      'Konačan iznos izračunava server prilikom kreiranja porudžbine.';

  @override
  String get checkoutConfirmOrderButton => 'Potvrdi porudžbinu';

  @override
  String get paymentTitle => 'Plaćanje';

  @override
  String get paymentSecureTitle => 'Bezbedno plaćanje';

  @override
  String get paymentSecureSubtitle =>
      'Vaše plaćanje je šifrovano i zaštićeno preko Stripe-a.';

  @override
  String get paymentRetryButton => 'Pokušaj ponovo';

  @override
  String get paymentPayNowButton => 'Plati sada';

  @override
  String get paymentCancelButton => 'Otkaži';

  @override
  String trackingOrderTitle(int orderId) {
    return 'Porudžbina #$orderId';
  }

  @override
  String get trackingRefreshTooltip => 'Osveži status';

  @override
  String get trackingLoadErrorMessage => 'Nije moguće učitati porudžbinu.';

  @override
  String get trackingViewOrdersButton => 'Moje porudžbine';

  @override
  String get trackingPaymentConfirmed => 'Plaćanje potvrđeno';

  @override
  String trackingRealtimeSubtitle(int orderId) {
    return 'Praćenje porudžbine #$orderId uživo.';
  }

  @override
  String get trackingConnectingMessage => 'Povezivanje u toku...';

  @override
  String get trackingCancelledMessage => 'Ova porudžbina je otkazana.';

  @override
  String get authEmailLabel => 'Email';

  @override
  String get authEmailInvalidError => 'Nevažeći email';

  @override
  String get authPasswordLabel => 'Lozinka';

  @override
  String get authPasswordMinLength => 'Minimum 8 karaktera';

  @override
  String get authForgotPasswordLink => 'Zaboravili ste lozinku?';

  @override
  String get authLoginSubmitButton => 'Prijavi se';

  @override
  String get authOrDivider => 'ili';

  @override
  String get authCreateAccountButton => 'Napravi nalog';

  @override
  String get authRegisterHeading => 'Hajde\nda napravimo\nvaš\nnalog';

  @override
  String get authLegalAcceptRequired =>
      'Molimo prihvatite uslove pre nego što nastavite.';

  @override
  String get authCloseTooltip => 'Zatvori';

  @override
  String get authFullNameLabel => 'Ime i prezime';

  @override
  String get authFullNameRequiredError => 'Ime je obavezno';

  @override
  String get authRegisterSubmitButton => 'Registruj se';

  @override
  String get authHaveAccountPrompt => 'Već imate nalog?';

  @override
  String get authForgotTitle => 'Zaboravljena\nLOZINKA?';

  @override
  String get authEmailSentTitle => 'Email\nposlat';

  @override
  String authEmailSentBody(String email) {
    return 'Ako je nalog povezan sa $email, uputstva stižu za nekoliko minuta.';
  }

  @override
  String get authForgotBody =>
      'Bez brige, poslaćemo vam uputstva za resetovanje pristupa.';

  @override
  String get authEnterEmailHint => 'Unesite email';

  @override
  String get authResetPasswordButton => 'Resetuj lozinku';

  @override
  String get authBackToLoginLink => 'Nazad na prijavu';

  @override
  String authCheckoutCartSummary(int count, String price) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count artikala',
      one: '$count artikal',
    );
    return '$_temp0 · $price';
  }

  @override
  String get authCheckoutLoginPrompt =>
      'Prijavite se da biste završili porudžbinu.';

  @override
  String get authTabLogin => 'Prijavljujem se';

  @override
  String get authTabRegister => 'Pravim nalog';

  @override
  String get authPhoneLabel => 'Telefon (opciono)';

  @override
  String get authCheckoutRegisterButton => 'Napravi nalog';

  @override
  String get authLoginFailedError => 'Prijava nije uspela.';

  @override
  String get authRegisterFailedError => 'Registracija nije uspela.';
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
  String get homeAllMenuSectionTitle => 'Ceo meni';

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
  String get productSizeLabel => 'Veličina';

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

  @override
  String get checkoutAddressMissingError =>
      'Unesite adresu za dostavu da biste nastavili.';

  @override
  String get checkoutPinMissingError =>
      'Postavite tačku na mapi da biste nastavili.';

  @override
  String get checkoutAddressInstructions =>
      'Unesite svoju adresu, zatim dodirnite mapu da postavite oznaku za dostavu.';

  @override
  String get checkoutAddressHelper =>
      'Oznaka služi za proveru zone, adresa se prosleđuje uz porudžbinu.';

  @override
  String checkoutPinCoordinates(String lat, String lng) {
    return 'Oznaka: $lat, $lng';
  }

  @override
  String get checkoutSwitchToPickup => 'Pređi na preuzimanje u restoranu';

  @override
  String get checkoutCheckZoneButton => 'Proveri zonu';

  @override
  String get checkoutRecapArticlesTitle => 'Stavke';

  @override
  String checkoutRecapLineItem(int quantity, String name) {
    return '$quantity × $name';
  }

  @override
  String checkoutRecapZone(String zone) {
    return 'Zona: $zone';
  }

  @override
  String checkoutRecapEstimatedTime(int minutes) {
    return 'Procenjeno vreme: $minutes min';
  }

  @override
  String checkoutRecapDeliveryFee(String price) {
    return 'Troškovi dostave: $price';
  }

  @override
  String checkoutRecapAddress(String address) {
    return 'Adresa: $address';
  }

  @override
  String get checkoutRecapPickupOnly => 'Preuzimanje direktno u restoranu.';

  @override
  String get checkoutRecapEstimatedTotal => 'Procenjeni ukupan iznos';

  @override
  String get checkoutRecapFinalAmountNotice =>
      'Konačan iznos izračunava server prilikom kreiranja porudžbine.';

  @override
  String get checkoutConfirmOrderButton => 'Potvrdi porudžbinu';

  @override
  String get paymentTitle => 'Plaćanje';

  @override
  String get paymentSecureTitle => 'Bezbedno plaćanje';

  @override
  String get paymentSecureSubtitle =>
      'Vaše plaćanje je šifrovano i zaštićeno preko Stripe-a.';

  @override
  String get paymentRetryButton => 'Pokušaj ponovo';

  @override
  String get paymentPayNowButton => 'Plati sada';

  @override
  String get paymentCancelButton => 'Otkaži';

  @override
  String trackingOrderTitle(int orderId) {
    return 'Porudžbina #$orderId';
  }

  @override
  String get trackingRefreshTooltip => 'Osveži status';

  @override
  String get trackingLoadErrorMessage => 'Nije moguće učitati porudžbinu.';

  @override
  String get trackingViewOrdersButton => 'Moje porudžbine';

  @override
  String get trackingPaymentConfirmed => 'Plaćanje potvrđeno';

  @override
  String trackingRealtimeSubtitle(int orderId) {
    return 'Praćenje porudžbine #$orderId uživo.';
  }

  @override
  String get trackingConnectingMessage => 'Povezivanje u toku...';

  @override
  String get trackingCancelledMessage => 'Ova porudžbina je otkazana.';

  @override
  String get authEmailLabel => 'Email';

  @override
  String get authEmailInvalidError => 'Nevažeći email';

  @override
  String get authPasswordLabel => 'Lozinka';

  @override
  String get authPasswordMinLength => 'Minimum 8 karaktera';

  @override
  String get authForgotPasswordLink => 'Zaboravili ste lozinku?';

  @override
  String get authLoginSubmitButton => 'Prijavi se';

  @override
  String get authOrDivider => 'ili';

  @override
  String get authCreateAccountButton => 'Napravi nalog';

  @override
  String get authRegisterHeading => 'Hajde\nda napravimo\nvaš\nnalog';

  @override
  String get authLegalAcceptRequired =>
      'Molimo prihvatite uslove pre nego što nastavite.';

  @override
  String get authCloseTooltip => 'Zatvori';

  @override
  String get authFullNameLabel => 'Ime i prezime';

  @override
  String get authFullNameRequiredError => 'Ime je obavezno';

  @override
  String get authRegisterSubmitButton => 'Registruj se';

  @override
  String get authHaveAccountPrompt => 'Već imate nalog?';

  @override
  String get authForgotTitle => 'Zaboravljena\nLOZINKA?';

  @override
  String get authEmailSentTitle => 'Email\nposlat';

  @override
  String authEmailSentBody(String email) {
    return 'Ako je nalog povezan sa $email, uputstva stižu za nekoliko minuta.';
  }

  @override
  String get authForgotBody =>
      'Bez brige, poslaćemo vam uputstva za resetovanje pristupa.';

  @override
  String get authEnterEmailHint => 'Unesite email';

  @override
  String get authResetPasswordButton => 'Resetuj lozinku';

  @override
  String get authBackToLoginLink => 'Nazad na prijavu';

  @override
  String authCheckoutCartSummary(int count, String price) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count artikala',
      one: '$count artikal',
    );
    return '$_temp0 · $price';
  }

  @override
  String get authCheckoutLoginPrompt =>
      'Prijavite se da biste završili porudžbinu.';

  @override
  String get authTabLogin => 'Prijavljujem se';

  @override
  String get authTabRegister => 'Pravim nalog';

  @override
  String get authPhoneLabel => 'Telefon (opciono)';

  @override
  String get authCheckoutRegisterButton => 'Napravi nalog';

  @override
  String get authLoginFailedError => 'Prijava nije uspela.';

  @override
  String get authRegisterFailedError => 'Registracija nije uspela.';
}
