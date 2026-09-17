import 'package:app_client/core/config/env.dart';

/// Formats a price for display, tenant-aware.
///
/// Bespoke, not generalized: only Kod Mome (Serbia, real prices already in
/// RSD from the backend) gets RSD formatting. Every other tenant keeps the
/// existing EUR formatting untouched — this app also serves French
/// restaurants whose prices are genuinely in euros.
String formatPrice(double amount) {
  if (Env.isKodMomeBuild) {
    return '${_withThousandsSeparator(amount.round())} RSD';
  }
  return '${amount.toStringAsFixed(2)} €';
}

/// `1100` -> `1.100` (dot as thousands separator, standard in Serbian
/// pricing — see the real menu/flyer assets this DA was built from).
String _withThousandsSeparator(int value) {
  final digits = value.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }
  return value < 0 ? '-$buffer' : buffer.toString();
}

/// Devises supportées pour l'affichage indicatif (`?display_currency=`) —
/// miroir de `SUPPORTED_CURRENCIES` côté
/// api-pizza/app/modules/admin/tenants/schemas.py.
const List<String> kSupportedDisplayCurrencies = [
  'EUR',
  'USD',
  'GBP',
  'CAD',
  'CHF',
];

/// Formate un prix indicatif dans une devise arbitraire (ISO 4217) —
/// purement informatif, jamais la devise réellement débitée (voir
/// [Product.indicativePriceLabel]). Suffixe le code plutôt qu'un symbole :
/// `$`/`£` sont ambigus entre USD/CAD/GBP/CHF selon la locale.
String formatIndicativePrice(double amount, String currencyCode) =>
    '~${amount.toStringAsFixed(2)} $currencyCode';
