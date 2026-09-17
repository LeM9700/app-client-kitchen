import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persiste la devise d'affichage indicative choisie par le client — même
/// pattern que `OnboardingStorage` (lib/features/onboarding/providers/onboarding_provider.dart).
class DisplayCurrencyStorage {
  const DisplayCurrencyStorage();

  static const _key = 'kitchen_display_currency_v1';

  /// Code ISO 4217 persisté, ou null si aucune devise n'a été choisie.
  Future<String?> getSelected() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key);
  }

  /// Persiste [code] ; `null` efface la sélection (retour au prix de base
  /// seul, sans conversion indicative).
  Future<void> setSelected(String? code) async {
    final prefs = await SharedPreferences.getInstance();
    if (code == null) {
      await prefs.remove(_key);
      return;
    }
    await prefs.setString(_key, code);
  }
}

final displayCurrencyStorageProvider = Provider<DisplayCurrencyStorage>(
  (ref) => const DisplayCurrencyStorage(),
);

/// Devise d'affichage indicative courante — `null` = pas de conversion
/// affichée (défaut). Sinon un code parmi `kSupportedDisplayCurrencies`
/// (voir core/utils/price_formatter.dart).
///
/// [ref.watch] sur ce provider doit toujours déclencher un refetch réseau
/// côté providers catalogue (catalog_provider.dart) : la conversion est
/// calculée côté serveur (taux de change en cache Redis), impossible à
/// dériver localement.
class DisplayCurrencyNotifier extends StateNotifier<String?> {
  DisplayCurrencyNotifier(this._ref) : super(null) {
    _ref.read(displayCurrencyStorageProvider).getSelected().then((value) {
      if (mounted) state = value;
    });
  }

  final Ref _ref;

  Future<void> select(String? code) async {
    state = code;
    await _ref.read(displayCurrencyStorageProvider).setSelected(code);
  }
}

final displayCurrencyProvider =
    StateNotifierProvider<DisplayCurrencyNotifier, String?>(
  DisplayCurrencyNotifier.new,
);
