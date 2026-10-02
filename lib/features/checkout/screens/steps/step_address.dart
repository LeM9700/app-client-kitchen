import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import 'package:app_client/core/config/env.dart';
import 'package:app_client/core/errors/app_exception.dart';
import 'package:app_client/core/theme/app_typography.dart';
import 'package:app_client/core/theme/kitchen_radius.dart';
import 'package:app_client/core/theme/kitchen_spacing.dart';
import 'package:app_client/core/theme/kitchen_tokens.dart';
import 'package:app_client/core/utils/price_formatter.dart';
import 'package:app_client/core/widgets/kitchen/kitchen_embossed_button.dart';
import 'package:app_client/core/widgets/kitchen/kitchen_surface.dart';
import 'package:app_client/core/widgets/kitchen/kitchen_text_field.dart';
import 'package:app_client/features/auth/providers/auth_provider.dart';
import 'package:app_client/features/checkout/models/address_models.dart';
import 'package:app_client/features/checkout/models/checkout_state.dart';
import 'package:app_client/features/checkout/providers/checkout_provider.dart';
import 'package:app_client/features/checkout/repositories/address_repository.dart';
import 'package:app_client/features/checkout/services/device_location_service.dart';
import 'package:app_client/features/checkout/widgets/kitchen_delivery_status.dart';
import 'package:app_client/l10n/app_localizations.dart';

/// Tuiles de la carte de livraison : Mapbox si un jeton public est fourni
/// (`--dart-define=MAPBOX_PUBLIC_TOKEN=pk...`), OpenStreetMap sinon (developpement).
final addressMapTileLayerProvider = Provider<Widget>((ref) {
  const token = Env.mapboxPublicToken;
  return TileLayer(
    urlTemplate: token.isEmpty
        ? 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'
        : 'https://api.mapbox.com/styles/v1/mapbox/streets-v12/tiles/256/{z}/{x}/{y}@2x'
            '?access_token=$token',
    userAgentPackageName: 'com.opizza.app_client',
  );
});

final addressInitialPointProvider = Provider<LatLng?>((ref) => null);

/// Meme regle que le serveur (`orders/schemas.py::_PHONE_RE`) : chiffres, espaces,
/// `+ ( ) . -`, 6 a 32 caracteres, avec au moins 6 chiffres.
bool isValidDeliveryPhone(String value) {
  final phone = value.trim();
  if (!RegExp(r'^\+?[0-9 ().-]{6,32}$').hasMatch(phone)) return false;
  return phone.replaceAll(RegExp(r'[^0-9]'), '').length >= 6;
}

/// Etape 2 : adresse de livraison.
///
/// Le client tape son adresse (suggestions via le proxy de geocodage de l'API), ou touche la
/// carte, ou utilise sa position : dans les trois cas le repere et l'adresse restent
/// synchronises, et la zone, les frais et le delai s'affichent tout de suite. Si la recherche
/// d'adresse est indisponible, le repere sur la carte reste utilisable.
class StepAddress extends ConsumerStatefulWidget {
  const StepAddress({super.key});

  @override
  ConsumerState<StepAddress> createState() => _StepAddressState();
}

class _StepAddressState extends ConsumerState<StepAddress> {
  static const _searchDebounce = Duration(milliseconds: 350);
  static const _minQueryLength = 3;
  static const _fallbackCenter = Env.isKodMomeBuild
      ? LatLng(44.7866, 20.4489) // Belgrade
      : LatLng(48.8566, 2.3522); // Paris

  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _mapController = MapController();

  LatLng? _selectedPoint;
  bool _mapReady = false;
  bool _userMovedPin = false;
  // L'adresse du champ vient du geocodage inverse (et non d'une saisie) : on peut la
  // remplacer quand le client deplace le repere.
  bool _addressAutoFilled = false;

  Timer? _debounce;
  int _searchSeq = 0;
  bool _searching = false;
  List<AddressSuggestion> _suggestions = const [];
  String? _searchProblem;

  @override
  void initState() {
    super.initState();
    _selectedPoint = ref.read(addressInitialPointProvider);
    // Prerempli depuis le profil (modifiable) pour ne pas ressaisir son numero.
    final user = ref.read(currentUserProvider);
    _phoneController.text = user?.phoneE164 ?? user?.phone ?? '';
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _mapController.dispose();
    _phoneController.dispose();
    _instructionsController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  String get _language => Localizations.localeOf(context).languageCode;

  LatLng get _mapCenter =>
      _selectedPoint ??
      ref.read(deliveryAvailabilityProvider).valueOrNull?.mapCenter ??
      _fallbackCenter;

  // ---------------------------------------------------------------- recherche

  void _onAddressChanged(String value) {
    _addressAutoFilled = false;
    _debounce?.cancel();
    final query = value.trim();
    if (query.length < _minQueryLength) {
      _searchSeq++;
      setState(() {
        _suggestions = const [];
        _searching = false;
        _searchProblem = null;
      });
      return;
    }
    _debounce = Timer(_searchDebounce, () => _search(query));
  }

  Future<void> _search(String query) async {
    final seq = ++_searchSeq;
    final l10n = AppLocalizations.of(context)!;
    final center = _mapCenter;
    setState(() {
      _searching = true;
      _searchProblem = null;
    });
    try {
      final results = await ref.read(addressRepositoryProvider).geocode(
            query,
            lat: center.latitude,
            lng: center.longitude,
            language: _language,
          );
      if (!mounted || seq != _searchSeq) return;
      setState(() {
        _suggestions = results;
        _searching = false;
      });
    } on AppException catch (error) {
      if (!mounted || seq != _searchSeq) return;
      setState(() {
        _suggestions = const [];
        _searching = false;
        _searchProblem =
            error is DeliveryException && error.code == 'RATE_LIMITED'
                ? l10n.checkoutRateLimited
                : l10n.checkoutAddressSearchUnavailable;
      });
    }
  }

  void _selectSuggestion(AddressSuggestion suggestion) {
    _debounce?.cancel();
    _searchSeq++;
    FocusScope.of(context).unfocus();
    setState(() {
      _addressController.text = suggestion.label;
      _addressAutoFilled = false;
      _selectedPoint = suggestion.point;
      _userMovedPin = true;
      _suggestions = const [];
      _searching = false;
      _searchProblem = null;
    });
    _moveMap(suggestion.point, zoom: 16);
    _previewDelivery();
  }

  // ---------------------------------------------------------------- carte

  void _moveMap(LatLng point, {double? zoom}) {
    if (!_mapReady) return;
    _mapController.move(point, zoom ?? _mapController.camera.zoom);
  }

  void _onMapTap(LatLng point) {
    FocusScope.of(context).unfocus();
    setState(() {
      _selectedPoint = point;
      _userMovedPin = true;
      _suggestions = const [];
    });
    _reverseFill(point);
    _previewDelivery();
  }

  /// Remplit le champ adresse depuis le repere, sauf si le client a deja saisi la sienne.
  Future<void> _reverseFill(LatLng point) async {
    final typedByUser =
        _addressController.text.trim().isNotEmpty && !_addressAutoFilled;
    if (typedByUser) return;
    try {
      final result = await ref
          .read(addressRepositoryProvider)
          .reverse(point.latitude, point.longitude, language: _language);
      if (!mounted || result == null || _selectedPoint != point) return;
      setState(() {
        _addressController.text = result.label;
        _addressAutoFilled = true;
      });
    } on AppException {
      // L'adresse reste modifiable a la main : le geocodage inverse n'est qu'un confort.
    }
  }

  Future<void> _useMyPosition() async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final point =
          await ref.read(deviceLocationServiceProvider).currentPosition();
      if (!mounted) return;
      setState(() {
        _selectedPoint = point;
        _userMovedPin = true;
        _suggestions = const [];
      });
      _moveMap(point, zoom: 16);
      _reverseFill(point);
      _previewDelivery();
    } on DeviceLocationException catch (error) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            error.failure == DeviceLocationFailure.permissionDenied
                ? l10n.checkoutLocationDenied
                : l10n.checkoutLocationUnavailable,
          ),
        ),
      );
    }
  }

  // ---------------------------------------------------------------- verification

  /// Apercu : zone, frais et delai pour le repere courant, sans quitter l'etape.
  void _previewDelivery() {
    final point = _selectedPoint;
    if (point == null) return;
    ref.read(checkoutProvider.notifier).checkDeliveryAddress(
          displayAddress: _addressController.text.trim(),
          lat: point.latitude,
          lng: point.longitude,
          advance: false,
        );
  }

  void _onCheckZone() {
    final l10n = AppLocalizations.of(context)!;
    final address = _addressController.text.trim();
    if (address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.checkoutAddressMissingError)),
      );
      return;
    }

    final point = _selectedPoint;
    if (point == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.checkoutPinMissingError)),
      );
      return;
    }

    final phone = _phoneController.text.trim();
    if (phone.isEmpty || !isValidDeliveryPhone(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            phone.isEmpty
                ? l10n.checkoutPhoneMissingError
                : l10n.checkoutPhoneInvalidError,
          ),
        ),
      );
      return;
    }

    final instructions = _instructionsController.text.trim();
    ref.read(checkoutProvider.notifier).checkDeliveryAddress(
          displayAddress: address,
          lat: point.latitude,
          lng: point.longitude,
          phone: phone,
          instructions: instructions.isEmpty ? null : instructions,
        );
  }

  // ---------------------------------------------------------------- affichage

  @override
  Widget build(BuildContext context) {
    final checkoutState = ref.watch(checkoutProvider);
    final l10n = AppLocalizations.of(context)!;
    final status = _deliveryStatusFor(checkoutState, l10n);

    // La position du restaurant arrive apres le premier affichage : on recentre la carte,
    // tant que le client n'a pas place son propre repere.
    ref.listen<AsyncValue<DeliveryAvailability>>(deliveryAvailabilityProvider,
        (_, next) {
      final center = next.valueOrNull?.mapCenter;
      if (center != null && _selectedPoint == null && !_userMovedPin) {
        _moveMap(center, zoom: 14);
      }
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        KitchenSpacing.lg,
        KitchenSpacing.md,
        KitchenSpacing.lg,
        KitchenSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Adresse de livraison',
            style: KitchenTypography.title.copyWith(fontSize: 30),
          ),
          const SizedBox(height: KitchenSpacing.xs),
          Text(
            l10n.checkoutAddressInstructions,
            style:
                KitchenTypography.body.copyWith(color: KitchenColors.textMuted),
          ),
          const SizedBox(height: KitchenSpacing.lg),
          KitchenSurface(
            padding: const EdgeInsets.all(KitchenSpacing.xs),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(KitchenRadius.lg),
              child: SizedBox(
                height: 280,
                child: Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _mapCenter,
                        initialZoom: 13,
                        onTap: (_, point) => _onMapTap(point),
                        onMapReady: () => _mapReady = true,
                      ),
                      children: [
                        ref.watch(addressMapTileLayerProvider),
                        if (_selectedPoint != null)
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: _selectedPoint!,
                                width: 44,
                                height: 44,
                                child: const Icon(
                                  Icons.location_pin,
                                  color: KitchenColors.cognac,
                                  size: 42,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    Positioned(
                      right: KitchenSpacing.xs,
                      bottom: KitchenSpacing.xs,
                      child: Semantics(
                        button: true,
                        label: l10n.checkoutUseMyPosition,
                        child: Tooltip(
                          message: l10n.checkoutUseMyPosition,
                          child: Material(
                            key: const ValueKey('use-my-position-button'),
                            color: KitchenColors.paper,
                            elevation: 2,
                            shape: const CircleBorder(),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: _useMyPosition,
                              child: const SizedBox(
                                width: 48,
                                height: 48,
                                child: Icon(
                                  Icons.my_location,
                                  color: KitchenColors.cognac,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: KitchenSpacing.md),
          KitchenTextField(
            key: const ValueKey('delivery-address-field'),
            controller: _addressController,
            label: l10n.checkoutStepAddressTitle,
            hintText: '12 rue des Oliviers, 69007 Lyon',
            prefixIcon: Icons.home_outlined,
            textInputAction: TextInputAction.next,
            onChanged: _onAddressChanged,
          ),
          if (_searching)
            const Padding(
              padding: EdgeInsets.only(top: KitchenSpacing.xs),
              child: LinearProgressIndicator(minHeight: 2),
            ),
          if (_suggestions.isNotEmpty) ...[
            const SizedBox(height: KitchenSpacing.xs),
            KitchenSurface(
              key: const ValueKey('address-suggestions'),
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (final suggestion in _suggestions)
                    InkWell(
                      key: ValueKey('address-suggestion-${suggestion.label}'),
                      onTap: () => _selectSuggestion(suggestion),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 48),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: KitchenSpacing.md,
                            vertical: KitchenSpacing.xs,
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.place_outlined,
                                color: KitchenColors.cognac,
                                size: 20,
                              ),
                              const SizedBox(width: KitchenSpacing.sm),
                              Expanded(
                                child: Text(
                                  suggestion.label,
                                  style: KitchenTypography.body.copyWith(
                                    color: KitchenColors.espresso,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
          if (_searchProblem != null) ...[
            const SizedBox(height: KitchenSpacing.xs),
            Text(
              _searchProblem!,
              key: const ValueKey('address-search-problem'),
              style: KitchenTypography.body.copyWith(
                color: KitchenColors.terracotta,
                fontSize: 13,
              ),
            ),
          ],
          const SizedBox(height: KitchenSpacing.md),
          KitchenTextField(
            key: const ValueKey('delivery-phone-field'),
            controller: _phoneController,
            label: l10n.checkoutPhoneLabel,
            hintText: l10n.checkoutPhoneHint,
            prefixIcon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.telephoneNumber],
          ),
          const SizedBox(height: KitchenSpacing.md),
          KitchenTextField(
            key: const ValueKey('delivery-instructions-field'),
            controller: _instructionsController,
            label: l10n.checkoutInstructionsLabel,
            hintText: l10n.checkoutInstructionsHint,
            prefixIcon: Icons.notes_outlined,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _onCheckZone(),
          ),
          if (_selectedPoint != null) ...[
            const SizedBox(height: KitchenSpacing.xs),
            Text(
              l10n.checkoutPinCoordinates(
                _selectedPoint!.latitude.toStringAsFixed(5),
                _selectedPoint!.longitude.toStringAsFixed(5),
              ),
              style: KitchenTypography.body.copyWith(
                color: KitchenColors.textMuted,
                fontSize: 13,
              ),
            ),
          ],
          const SizedBox(height: KitchenSpacing.md),
          KitchenDeliveryStatus(
            type: status.type,
            title: status.title,
            subtitle: status.subtitle,
          ),
          if (checkoutState.error != null) ...[
            const SizedBox(height: KitchenSpacing.sm),
            TextButton.icon(
              onPressed: () => ref
                  .read(checkoutProvider.notifier)
                  .selectDeliveryMode(DeliveryMode.pickup),
              icon: const Icon(Icons.storefront_outlined),
              label: Text(l10n.checkoutSwitchToPickup),
              style: TextButton.styleFrom(
                foregroundColor: KitchenColors.cognac,
                minimumSize: const Size(44, 44),
              ),
            ),
          ],
          const SizedBox(height: KitchenSpacing.lg),
          KitchenEmbossedButton(
            key: const ValueKey('check-delivery-zone-button'),
            onPressed: _onCheckZone,
            isLoading: checkoutState.isLoading,
            semanticLabel: 'Verifier la zone de livraison',
            child: Text(l10n.checkoutCheckZoneButton),
          ),
        ],
      ),
    );
  }

  _DeliveryStatusViewModel _deliveryStatusFor(
    CheckoutState state,
    AppLocalizations l10n,
  ) {
    if (state.isLoading) {
      return const _DeliveryStatusViewModel(
        type: KitchenDeliveryStatusType.checking,
        title: 'Verification de la zone...',
        subtitle: 'Nous interrogeons la zone de livraison disponible.',
      );
    }
    final error = state.error;
    if (error != null) {
      final info = state.deliveryInfo;
      switch (state.errorCode) {
        case 'DELIVERY_MIN_ORDER_NOT_MET':
          return _DeliveryStatusViewModel(
            type: KitchenDeliveryStatusType.invalid,
            title: info != null && info.minOrderAmount > 0
                ? l10n.checkoutMinOrderError(formatPrice(info.minOrderAmount))
                : l10n.checkoutMinOrderErrorGeneric,
          );
        case 'DELIVERY_DISABLED':
          return _DeliveryStatusViewModel(
            type: KitchenDeliveryStatusType.invalid,
            title: l10n.checkoutDeliveryDisabled,
          );
        case 'CUSTOMER_PHONE_REQUIRED':
          return _DeliveryStatusViewModel(
            type: KitchenDeliveryStatusType.invalid,
            title: l10n.checkoutPhoneRequiredServer,
          );
        case 'RATE_LIMITED':
          return _DeliveryStatusViewModel(
            type: KitchenDeliveryStatusType.error,
            title: l10n.checkoutRateLimited,
          );
      }
      final isOutOfZone = state.errorCode == 'DELIVERY_ZONE_UNREACHABLE' ||
          error.toLowerCase().contains('hors zone');
      return _DeliveryStatusViewModel(
        type: isOutOfZone
            ? KitchenDeliveryStatusType.invalid
            : KitchenDeliveryStatusType.error,
        title: error,
        subtitle: isOutOfZone
            ? 'Vous pouvez basculer en retrait sans perdre votre panier.'
            : 'Verifiez votre connexion puis reessayez.',
      );
    }
    final info = state.deliveryInfo;
    if (info != null) {
      final fee = info.freeDelivery
          ? l10n.checkoutDeliveryFree
          : l10n.checkoutDeliveryFeeLine(formatPrice(info.fee));
      final nudge = !info.freeDelivery && (info.remainingForFree ?? 0) > 0
          ? '\n${l10n.checkoutDeliveryFreeNudge(formatPrice(info.remainingForFree!))}'
          : '';
      return _DeliveryStatusViewModel(
        type: KitchenDeliveryStatusType.valid,
        title: 'Vous etes dans notre zone de livraison',
        subtitle: '${info.name} - ${info.estimatedMinutes} min\n$fee$nudge',
      );
    }
    return const _DeliveryStatusViewModel(
      type: KitchenDeliveryStatusType.idle,
      title: 'Placez le repere sur la carte',
      subtitle: 'La validation utilise les coordonnees reelles du repere.',
    );
  }
}

class _DeliveryStatusViewModel {
  const _DeliveryStatusViewModel({
    required this.type,
    required this.title,
    this.subtitle,
  });

  final KitchenDeliveryStatusType type;
  final String title;
  final String? subtitle;
}
